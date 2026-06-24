import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/model/member.dart';
import 'package:projecti_fan_app/model/youtube_video_model.dart';
import 'package:projecti_fan_app/services/youtube_service.dart';

class _MemberVideoCache {
  List<YouTubeVideoModel> videos;
  DateTime lastFetched;

  _MemberVideoCache({
    required this.videos,
    required this.lastFetched,
  });

  bool get isStale => DateTime.now().difference(lastFetched).inMinutes > 10;
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
    ever(_globalController.selectedGroup, (_) => _onGroupChanged());
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
    final memberKey = effectiveSelectedMemberKey;
    if (memberKey.isEmpty) return;

    final channelId = _memberByKey(memberKey)?.youtubeChannelId;
    if (channelId == null || channelId.isEmpty) {
      hasError.value = true;
      errorMessage.value = '채널 ID를 찾을 수 없습니다';
      return;
    }

    // 캐시 확인
    if (!forceRefresh &&
        _cache.containsKey(memberKey) &&
        !_cache[memberKey]!.isStale) {
      videoList.value = List.from(_cache[memberKey]!.videos);
      return;
    }

    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final videos = await _service.getChannelVideos(channelId: channelId);

      videoList.value = videos;

      // 캐시 저장
      _cache[memberKey] = _MemberVideoCache(
        videos: List.from(videos),
        lastFetched: DateTime.now(),
      );
    } on YouTubeServiceException catch (e) {
      hasError.value = true;
      errorMessage.value = e.message;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = '알 수 없는 오류가 발생했습니다';
    } finally {
      isLoading.value = false;
    }
  }

  /// 새로고침
  @override
  Future<void> refresh() async {
    await loadVideos(forceRefresh: true);
  }

  /// 홈 대시보드용: 그룹 전체 멤버의 최신 영상 로드 (최신순 상위 [limit]개)
  Future<void> loadGroupLatestVideos({
    bool forceRefresh = false,
    int limit = 5,
  }) async {
    final group = _globalController.selectedGroup.value;
    if (group.isEmpty) return;

    // 캐시 확인
    if (!forceRefresh &&
        _groupCache.containsKey(group) &&
        !_groupCache[group]!.isStale) {
      groupLatestVideos.value = List.from(_groupCache[group]!.videos);
      return;
    }

    try {
      isGroupVideosLoading.value = true;

      // 그룹 전체 멤버 RSS 병렬 조회 (실패한 채널은 빈 목록 처리)
      final results = await Future.wait(
        currentMembers.map(
          (member) => _service
              .getChannelVideos(channelId: member.youtubeChannelId)
              .catchError((_) => <YouTubeVideoModel>[]),
        ),
      );

      // 병합 후 최신순 정렬
      final merged = results.expand((videos) => videos).toList()
        ..sort((a, b) {
          final aDate = a.publishedAt ?? DateTime(2000);
          final bDate = b.publishedAt ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });

      final latest = merged.take(limit).toList();
      groupLatestVideos.value = latest;

      // 캐시 저장
      _groupCache[group] = _MemberVideoCache(
        videos: List.from(latest),
        lastFetched: DateTime.now(),
      );
    } finally {
      isGroupVideosLoading.value = false;
    }
  }
}
