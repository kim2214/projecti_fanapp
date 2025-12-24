import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projecti_fan_app/model/youtube_video_model.dart';
import 'package:projecti_fan_app/services/youtube_service.dart';

class YouTubeController extends GetxController {
  static const String _channelIdKey = 'youtube_channel_id';
  // 기본 채널 ID (변경 필요)
  static const String _defaultChannelId = 'UCkQFRBUPh5mcF1kca4f_DvQ';

  final YouTubeService _service = YouTubeService.instance;

  // 상태 변수들
  RxString channelId = ''.obs;
  RxList<YouTubeVideoModel> videoList = <YouTubeVideoModel>[].obs;
  RxBool isLoading = false.obs;
  RxBool isLoadingMore = false.obs;
  RxBool hasError = false.obs;
  RxString errorMessage = ''.obs;

  // 페이지네이션
  String? _nextPageToken;

  bool get hasMore => _nextPageToken != null;

  @override
  void onInit() {
    super.onInit();
    _loadChannelId();
  }

  /// 저장된 채널 ID 로드
  Future<void> _loadChannelId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      channelId.value = prefs.getString(_channelIdKey) ?? _defaultChannelId;
    } catch (e) {
      debugPrint('Error loading channel ID: $e');
    }
  }

  /// 채널 ID 변경 및 저장
  Future<void> setChannelId(String newChannelId) async {
    if (newChannelId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_channelIdKey, newChannelId);

      channelId.value = newChannelId;

      // 새 채널로 비디오 다시 로드
      await loadVideos();
    } catch (e) {
      debugPrint('Error saving channel ID: $e');
    }
  }

  /// 비디오 목록 로드 (새로고침)
  Future<void> loadVideos() async {
    if (channelId.value.isEmpty) {
      await _loadChannelId();
      if (channelId.value.isEmpty) {
        hasError.value = true;
        errorMessage.value = '채널 ID를 설정해주세요';
        return;
      }
    }

    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';
      _nextPageToken = null;

      final response = await _service.getChannelVideos(
        channelId: channelId.value,
        maxResults: 20,
      );

      videoList.value = response.videos;
      _nextPageToken = response.nextPageToken;
    } on YouTubeServiceException catch (e) {
      hasError.value = true;
      errorMessage.value = e.message;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = '알 수 없는 오류가 발생했습니다';
      debugPrint('Error loading videos: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 추가 비디오 로드 (페이지네이션)
  Future<void> loadMoreVideos() async {
    if (!hasMore || isLoadingMore.value) return;

    try {
      isLoadingMore.value = true;

      final response = await _service.getChannelVideos(
        channelId: channelId.value,
        maxResults: 20,
        pageToken: _nextPageToken,
      );

      videoList.addAll(response.videos);
      _nextPageToken = response.nextPageToken;
    } on YouTubeServiceException catch (e) {
      // 추가 로드 실패는 조용히 처리
      debugPrint('추가 로드 실패: ${e.message}');
    } catch (e) {
      debugPrint('추가 로드 실패: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// 새로고침
  @override
  Future<void> refresh() async {
    _nextPageToken = null;
    await loadVideos();
  }

  /// 채널 ID 유효성 검사 (채널 ID 형식 확인)
  bool isValidChannelId(String id) {
    // YouTube 채널 ID는 보통 UC로 시작하고 24자
    return id.startsWith('UC') && id.length == 24;
  }
}
