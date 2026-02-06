import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:projecti_fan_app/model/youtube_video_model.dart';

class YouTubeService {
  static YouTubeService? _instance;
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  YouTubeService._();

  static YouTubeService get instance {
    _instance ??= YouTubeService._();
    return _instance!;
  }

  String get _apiKey {
    final apiKey = dotenv.env['YOUTUBE_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw YouTubeServiceException('YouTube API Key가 설정되지 않았습니다');
    }
    return apiKey;
  }

  /// 채널의 uploads 플레이리스트 ID 가져오기
  Future<String?> getUploadsPlaylistId(String channelId) async {
    try {
      final uri = Uri.parse('$_baseUrl/channels').replace(
        queryParameters: {
          'part': 'contentDetails',
          'id': channelId,
          'key': _apiKey,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw YouTubeServiceException(
            '채널 정보를 가져올 수 없습니다: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final items = json['items'] as List?;

      if (items == null || items.isEmpty) {
        throw YouTubeServiceException('채널을 찾을 수 없습니다');
      }

      return items.first['contentDetails']?['relatedPlaylists']?['uploads'];
    } catch (e) {
      if (e is YouTubeServiceException) rethrow;
      throw YouTubeServiceException('채널 정보를 가져올 수 없습니다: $e');
    }
  }

  /// 플레이리스트의 비디오 목록 가져오기 (페이지네이션 지원)
  Future<YouTubeVideoListResponse> getPlaylistVideos({
    required String playlistId,
    int maxResults = 20,
    String? pageToken,
  }) async {
    try {
      final queryParams = {
        'part': 'snippet,contentDetails',
        'playlistId': playlistId,
        'maxResults': maxResults.toString(),
        'key': _apiKey,
      };

      if (pageToken != null) {
        queryParams['pageToken'] = pageToken;
      }

      final uri = Uri.parse('$_baseUrl/playlistItems').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        final errorJson = jsonDecode(response.body);
        final errorMessage = errorJson['error']?['message'] ?? '알 수 없는 오류';
        throw YouTubeServiceException('API 오류: $errorMessage');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final items = json['items'] as List? ?? [];

      final videos = items
          .map((item) =>
              YouTubeVideoModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return YouTubeVideoListResponse(
        videos: videos,
        nextPageToken: json['nextPageToken'],
        totalResults: json['pageInfo']?['totalResults'] ?? 0,
      );
    } catch (e) {
      if (e is YouTubeServiceException) rethrow;
      throw YouTubeServiceException('비디오 목록을 가져올 수 없습니다: $e');
    }
  }

  /// 채널 ID로 바로 비디오 목록 가져오기
  Future<YouTubeVideoListResponse> getChannelVideos({
    required String channelId,
    int maxResults = 20,
    String? pageToken,
  }) async {
    final playlistId = await getUploadsPlaylistId(channelId);
    if (playlistId == null) {
      throw YouTubeServiceException('채널의 업로드 플레이리스트를 찾을 수 없습니다');
    }

    return getPlaylistVideos(
      playlistId: playlistId,
      maxResults: maxResults,
      pageToken: pageToken,
    );
  }
}

/// 비디오 목록 응답 클래스
class YouTubeVideoListResponse {
  final List<YouTubeVideoModel> videos;
  final String? nextPageToken;
  final int totalResults;

  YouTubeVideoListResponse({
    required this.videos,
    this.nextPageToken,
    required this.totalResults,
  });

  bool get hasMore => nextPageToken != null;
}

/// 서비스 예외 클래스
class YouTubeServiceException implements Exception {
  final String message;

  YouTubeServiceException(this.message);

  @override
  String toString() => message;
}
