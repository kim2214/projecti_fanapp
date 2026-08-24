import 'dart:convert';

import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/model/member.dart';
import 'package:projecti_fan_app/model/youtube_video_model.dart';
import 'package:projecti_fan_app/services/youtube_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemberVideoCache {
  List<YouTubeVideoModel> videos;
  DateTime lastFetched;

  _MemberVideoCache({
    required this.videos,
    required this.lastFetched,
  });

  bool get isStale => DateTime.now().difference(lastFetched).inMinutes > 10;

  Map<String, dynamic> toJson() => {
        'lastFetched': lastFetched.toIso8601String(),
        'videos': videos.map((v) => v.toJson()).toList(),
      };

  factory _MemberVideoCache.fromJson(Map<String, dynamic> json) =>
      _MemberVideoCache(
        videos: (json['videos'] as List)
            .map((e) => YouTubeVideoModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        lastFetched:
            DateTime.tryParse(json['lastFetched'] as String? ?? '') ??
                DateTime(2000),
      );
}

class YouTubeController extends GetxController {
  // globalController는 테스트에서 주입할 수 있도록 생성자 파라미터로 받는다.
  // 프로덕션(바인딩)은 인자 없이 생성하므로 기본값으로 기존 동작(Get.find)을 유지한다.
  YouTubeController({GlobalController? globalController})
      : _globalController = globalController ?? Get.find<GlobalController>();

  final GlobalController _globalController;
  final YouTubeService _service = YouTubeService.instance;

  // 상태 변수들
  RxString selectedMemberKey = ''.obs;
  RxList<YouTubeVideoModel> videoList = <YouTubeVideoModel>[].obs;
  RxBool isLoading = false.obs;
  RxBool hasError = false.obs;
  RxString errorMessage = ''.obs;

  // 홈 대시보드용: 그룹 전체 멤버의 최신 영상
  RxList<YouTubeVideoModel> groupLatestVideos = <YouTubeVideoModel>[].obs;
  RxBool isGroupVideosLoading = false.obs;

  // 멤버별 캐시
  final Map<String, _MemberVideoCache> _cache = {};

  // 그룹별 최신 영상 캐시
  final Map<String, _MemberVideoCache> _groupCache = {};

  // 영속화된 캐시 복원 작업. loadVideos/loadGroupLatestVideos는 시작 전에 이를
  // 기다려, 콜드스타트 시 디스크 캐시가 메모리에 올라온 뒤 표시/판단하도록 한다.
  Future<void>? _restoreFuture;

  // shared_preferences 키 (스키마 변경 시 버전 suffix를 올린다)
  static const String _memberCacheKey = 'yt_member_cache_v1';
  static const String _groupCacheKey = 'yt_group_cache_v1';

  // 그룹 일괄 조회용 타임아웃 (단일 멤버 조회 8초보다 짧게 — 느린 채널을 일찍 포기).
  static const Duration _groupRequestTimeout = Duration(seconds: 5);

  // 현재 그룹의 멤버 목록 (단일 카탈로그 기반)
  List<Member> get currentMembers =>
      _globalController.membersOf(_globalController.selectedGroup.value);

  // 유효한 선택된 멤버 키 (미설정이거나 다른 그룹이면 첫 번째 멤버)
  String get effectiveSelectedMemberKey {
    final members = currentMembers;
    if (members.isEmpty) return '';
    if (selectedMemberKey.value.isEmpty ||
        !members.any((m) => m.key == selectedMemberKey.value)) {
      return members.first.key;
    }
    return selectedMemberKey.value;
  }

  /// 현재 그룹에서 키로 멤버를 찾는다 (없으면 null)
  Member? _memberByKey(String key) {
    for (final m in currentMembers) {
      if (m.key == key) return m;
    }
    return null;
  }

  /// 현재 선택된 멤버의 YouTube 채널 페이지 URL
  String? get currentChannelUrl {
    final channelId = _memberByKey(effectiveSelectedMemberKey)?.youtubeChannelId;
    if (channelId == null) return null;
    return 'https://www.youtube.com/channel/$channelId/videos';
  }

  @override
  void onInit() {
    super.onInit();
    _restoreFuture = _restorePersistedCache();
    // 그룹 전환 시의 영상 로드는 이 컨트롤러가 단일 소유한다. 화면(홈)에서도
    // ever를 걸면 그룹 전환마다 같은 RSS fan-out이 두 벌 나간다.
    ever(_globalController.selectedGroup, (_) => _onGroupChanged());
    // 컨트롤러는 lazy 생성이라 첫 홈 진입 시점엔 그룹이 이미 선택된 뒤다
    // (ever가 그 변경을 놓침) → 초기 1회는 여기서 직접 로드한다.
    if (_globalController.selectedGroup.value.isNotEmpty) {
      loadGroupLatestVideos();
    }
  }

  void _onGroupChanged() {
    selectedMemberKey.value = '';
    loadVideos();
    loadGroupLatestVideos();
  }

  /// 멤버 선택
  Future<void> selectMember(String memberKey) async {
    if (memberKey == effectiveSelectedMemberKey) return;
    selectedMemberKey.value = memberKey;
    await loadVideos();
  }

  /// 비디오 목록 로드
  Future<void> loadVideos({bool forceRefresh = false}) async {
    await _restoreFuture; // 영속 캐시 복원 완료 보장 (null이면 즉시 통과)

    final memberKey = effectiveSelectedMemberKey;
    if (memberKey.isEmpty) return;

    final channelId = _memberByKey(memberKey)?.youtubeChannelId;
    if (channelId == null || channelId.isEmpty) {
      hasError.value = true;
      errorMessage.value = '채널 ID를 찾을 수 없습니다';
      return;
    }

    // 캐시(영속화 포함)가 있으면 즉시 표시 — 콜드스타트에서도 스피너 없이 바로 보인다.
    final cached = _cache[memberKey];
    if (cached != null) {
      videoList.value = List.from(cached.videos);
      // 신선하고 강제 새로고침이 아니면 네트워크 없이 종료
      if (!forceRefresh && !cached.isStale) return;
    }

    try {
      // 보여줄 캐시가 없을 때만 풀스크린 로딩 스피너를 띄운다.
      if (cached == null) isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final videos = await _service.getChannelVideos(channelId: channelId);

      // 조회 도중 다른 멤버로 바뀌었으면(재시도 포함 최대 수십 초) 화면 상태를
      // 건드리지 않는다 — 늦게 도착한 응답이 새 멤버의 목록을 덮는 것 방지.
      // 결과는 캐시에는 반영해 다음 방문 때 활용한다.
      final stillSelected = effectiveSelectedMemberKey == memberKey;

      if (videos.isNotEmpty) {
        if (stillSelected) videoList.value = videos;
        // 캐시 저장 + 영속화 (빈 결과는 일시적 실패일 수 있어 저장하지 않는다)
        _cache[memberKey] = _MemberVideoCache(
          videos: List.from(videos),
          lastFetched: DateTime.now(),
        );
        await _persistCache(_memberCacheKey, _cache);
      } else if (cached == null && stillSelected) {
        // 캐시도 없는데 빈 결과면, 영상이 실제로 없는 채널로 보고 빈 목록을 표시.
        videoList.value = videos;
      }
      // 빈 결과 + 기존 캐시 있음: 보여주던 캐시를 유지하고 덮어쓰지 않는다.
    } on YouTubeServiceException catch (e) {
      // 이미 캐시로 표시 중이면 기존 콘텐츠를 유지하고 에러 화면을 띄우지 않는다.
      if (cached == null && effectiveSelectedMemberKey == memberKey) {
        hasError.value = true;
        errorMessage.value = e.message;
      }
    } catch (e) {
      if (cached == null && effectiveSelectedMemberKey == memberKey) {
        hasError.value = true;
        errorMessage.value = '알 수 없는 오류가 발생했습니다';
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// 새로고침
  @override
  Future<void> refresh() async {
    await loadVideos(forceRefresh: true);
  }

  /// 멤버 프로필 화면용: 멤버별 10분 캐시를 경유해 최신 영상을 반환한다.
  /// (서비스를 직접 부르면 프로필을 열 때마다 RSS를 재조회한다 — 이 피드는
  /// 레이트리밋에 민감하다.) 조회 실패·빈 결과 시엔 오래된 캐시라도 반환한다.
  Future<List<YouTubeVideoModel>> videosFor(Member member) async {
    await _restoreFuture; // 영속 캐시 복원 완료 보장 (null이면 즉시 통과)

    final cached = _cache[member.key];
    if (cached != null && !cached.isStale) return List.from(cached.videos);

    try {
      final videos =
          await _service.getChannelVideos(channelId: member.youtubeChannelId);
      if (videos.isNotEmpty) {
        _cache[member.key] = _MemberVideoCache(
          videos: List.from(videos),
          lastFetched: DateTime.now(),
        );
        await _persistCache(_memberCacheKey, _cache);
        return videos;
      }
      return cached != null ? List.from(cached.videos) : videos;
    } catch (_) {
      if (cached != null) return List.from(cached.videos);
      rethrow; // 화면(FutureBuilder)이 "불러올 수 없습니다"로 표시
    }
  }

  /// 홈 대시보드용: 그룹 전체 멤버의 최신 영상 로드 (최신순 상위 [limit]개)
  Future<void> loadGroupLatestVideos({
    bool forceRefresh = false,
    int limit = 5,
  }) async {
    await _restoreFuture; // 영속 캐시 복원 완료 보장 (null이면 즉시 통과)

    final group = _globalController.selectedGroup.value;
    if (group.isEmpty) return;

    // 캐시(영속화 포함)가 있으면 즉시 표시 — 콜드스타트에서도 스피너 없이 바로 보인다.
    final cached = _groupCache[group];
    if (cached != null) {
      groupLatestVideos.value = List.from(cached.videos);
      if (!forceRefresh && !cached.isStale) return;
    }

    try {
      if (cached == null) isGroupVideosLoading.value = true;

      // 그룹 변경에 대비해 대상 멤버를 고정한다.
      final members = currentMembers;
      final collected = <YouTubeVideoModel>[];

      // 점진적 표시: 각 채널 RSS를 병렬 조회하되, 모두 기다리지 않고
      // 도착하는 대로 병합·정렬해 화면을 갱신한다. 가장 느린 채널이 전체
      // 표시를 지연시키지 않으므로 첫 영상이 빠르게 보인다.
      // 그룹 조회는 더 짧은 타임아웃을 써서 느린 채널을 일찍 포기한다.
      await Future.wait(
        members.map((member) async {
          try {
            final vids = await _service.getChannelVideos(
              channelId: member.youtubeChannelId,
              timeout: _groupRequestTimeout,
              // 그룹은 11개 채널 + 점진적 표시로 일부 실패를 흡수하므로 재시도 생략
              // (재시도 시 채널 수만큼 부하가 곱해져 오히려 레이트리밋을 악화).
              retries: 0,
            );
            // 조회 도중 그룹이 바뀌었으면 결과를 반영하지 않는다.
            if (_globalController.selectedGroup.value != group) return;
            collected.addAll(vids);
            if (collected.isNotEmpty) {
              groupLatestVideos.value = _sortedLatest(collected, limit);
              isGroupVideosLoading.value = false; // 첫 결과 도착 → 스켈레톤 해제
            }
          } catch (_) {
            // 개별 채널 실패는 무시 (다른 채널 결과로 채운다)
          }
        }),
      );

      if (_globalController.selectedGroup.value != group) return;

      final latest = _sortedLatest(collected, limit);
      if (latest.isNotEmpty) {
        groupLatestVideos.value = latest;
        // 캐시 저장 + 영속화 (전체 실패로 인한 빈 결과는 저장하지 않아 다음에 재시도)
        _groupCache[group] = _MemberVideoCache(
          videos: List.from(latest),
          lastFetched: DateTime.now(),
        );
        await _persistCache(_groupCacheKey, _groupCache);
      } else if (cached == null) {
        groupLatestVideos.value = latest;
      }
      // 빈 결과 + 기존 캐시 있음: 보여주던 캐시를 유지한다.
    } finally {
      isGroupVideosLoading.value = false;
    }
  }

  /// 영상들을 게시일 내림차순 정렬해 상위 [limit]개를 반환한다.
  List<YouTubeVideoModel> _sortedLatest(
      List<YouTubeVideoModel> videos, int limit) {
    final sorted = [...videos]..sort((a, b) {
        final aDate = a.publishedAt ?? DateTime(2000);
        final bDate = b.publishedAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
    return sorted.take(limit).toList();
  }

  /// 영속화된 캐시를 메모리 맵으로 복원한다. 실패는 치명적이지 않다 (네트워크로 재조회).
  Future<void> _restorePersistedCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _restoreInto(_cache, prefs.getString(_memberCacheKey));
      _restoreInto(_groupCache, prefs.getString(_groupCacheKey));
    } catch (_) {
      // 손상된 캐시 등은 무시하고 빈 상태로 시작.
    }
  }

  void _restoreInto(Map<String, _MemberVideoCache> target, String? raw) {
    if (raw == null || raw.isEmpty) return;
    final decoded = json.decode(raw) as Map<String, dynamic>;
    decoded.forEach((key, value) {
      target[key] = _MemberVideoCache.fromJson(value as Map<String, dynamic>);
    });
  }

  /// 메모리 캐시 맵을 shared_preferences에 직렬화한다. 실패는 무시 (메모리 캐시는 유지).
  Future<void> _persistCache(
      String key, Map<String, _MemberVideoCache> map) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(
        {for (final entry in map.entries) entry.key: entry.value.toJson()},
      );
      await prefs.setString(key, encoded);
    } catch (_) {
      // 영속화 실패 무시.
    }
  }
}
