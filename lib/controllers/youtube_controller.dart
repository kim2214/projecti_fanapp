import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
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
  final GlobalController _globalController = Get.find<GlobalController>();
  final YouTubeService _service = YouTubeService.instance;

  // 멤버별 YouTube 채널 ID
  static const Map<String, String> honeyzChannelIds = {
    'honeychurros': 'UCkQFRBUPh5mcF1kca4f_DvQ',
    'ayauke': 'UCZcjMonq-hln97npqkYdHjQ',
    'damyui': 'UC_XRkKvydFB_wX1dlr7OHrg',
    'ddddragon': 'UCmNurVU0rTyYqU4W4N0Mbgg',
    'ohwayo': 'UC1RdgfinRXTboGZLZ4xG5Aw',
    'mangnae': 'UCicn6yqObjHrCKWkKL70ALg',
  };

  static const Map<String, String> acaxiaChannelIds = {
    'popopopo': 'UCXE5gQZ5WIbtT6FJtG2g5ag',
    'violetaMone': 'UC0dF0Yr7PVddxuIHp_xsFZg',
    'blaireRose': 'UC4RqkMZg4xRy0gWizubvPLw',
    'hasiyo': 'UCkmb3uZxHAx10m7QR8XJSpQ',
    'ryushiho': 'UC-9fPSlVjMqG3zwbRT2XhXA',
  };

  // 상태 변수들
  RxString selectedMemberKey = ''.obs;
  RxList<YouTubeVideoModel> videoList = <YouTubeVideoModel>[].obs;
  RxBool isLoading = false.obs;
  RxBool hasError = false.obs;
  RxString errorMessage = ''.obs;

  // 멤버별 캐시
  final Map<String, _MemberVideoCache> _cache = {};

  // 현재 그룹의 채널 ID 맵
  Map<String, String> get currentChannelIds {
    return _globalController.selectedGroup.value == 'honeyz'
        ? honeyzChannelIds
        : acaxiaChannelIds;
  }

  // 현재 그룹의 멤버 키 목록
  List<String> get currentMemberKeys {
    return _globalController.selectedGroup.value == 'honeyz'
        ? _globalController.honeyzSequence
        : _globalController.acaxiaSequence;
  }

  // 현재 그룹의 멤버 이름 목록
  List<String> get currentMemberNames {
    return _globalController.selectedGroup.value == 'honeyz'
        ? _globalController.honeyzNameList
        : _globalController.acaxiaNameList;
  }

  // 현재 그룹의 에셋 이름 목록
  List<String> get currentAssetNames {
    return _globalController.selectedGroup.value == 'honeyz'
        ? _globalController.honeyzAssetName
        : _globalController.acaxiaAssetName;
  }

  // 유효한 선택된 멤버 키 (미설정이거나 다른 그룹이면 첫 번째 멤버)
  String get effectiveSelectedMemberKey {
    final keys = currentMemberKeys;
    if (keys.isEmpty) return '';
    if (selectedMemberKey.value.isEmpty ||
        !keys.contains(selectedMemberKey.value)) {
      return keys.first;
    }
    return selectedMemberKey.value;
  }

  /// 현재 선택된 멤버의 YouTube 채널 페이지 URL
  String? get currentChannelUrl {
    final channelId = currentChannelIds[effectiveSelectedMemberKey];
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

    final channelId = currentChannelIds[memberKey];
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
}
