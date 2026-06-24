import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:projecti_fan_app/model/youtube_video_model.dart';
import 'package:xml/xml.dart';

/// YouTube 공식 RSS 피드 기반 서비스 (API 키 불필요)
/// 채널당 최신 영상 15개를 제공한다.
class YouTubeService {
  static YouTubeService? _instance;
  static const String _feedBaseUrl = 'https://www.youtube.com/feeds/videos.xml';

  /// 네트워크가 멈췄을 때 무한 대기하지 않도록 하는 요청 타임아웃.
  static const Duration _requestTimeout = Duration(seconds: 8);

  YouTubeService._();

  static YouTubeService get instance {
    _instance ??= YouTubeService._();
    return _instance!;
  }

  /// 채널의 최신 영상 목록 가져오기
  Future<List<YouTubeVideoModel>> getChannelVideos({
    required String channelId,
  }) async {
    try {
      final uri = Uri.parse(_feedBaseUrl).replace(
        queryParameters: {'channel_id': channelId},
      );

      final response = await http.get(uri).timeout(_requestTimeout);

      if (response.statusCode != 200) {
        throw YouTubeServiceException(
            '영상 목록을 가져올 수 없습니다 (${response.statusCode})');
      }

      // 한글 제목 깨짐 방지를 위해 bodyBytes를 UTF-8로 디코딩
      final document = XmlDocument.parse(utf8.decode(response.bodyBytes));

      return document
          .findAllElements('entry')
          .map(_parseEntry)
          .where((video) => video.videoId != null)
          .toList();
    } catch (e) {
      if (e is YouTubeServiceException) rethrow;
      throw YouTubeServiceException('영상 목록을 가져올 수 없습니다: $e');
    }
  }

  /// RSS entry -> YouTubeVideoModel
  YouTubeVideoModel _parseEntry(XmlElement entry) {
    final mediaGroup = entry.getElement('media:group');
    final published = entry.getElement('published')?.innerText;

    return YouTubeVideoModel(
      videoId: entry.getElement('yt:videoId')?.innerText,
      title: entry.getElement('title')?.innerText,
      description: mediaGroup?.getElement('media:description')?.innerText,
      thumbnailUrl:
          mediaGroup?.getElement('media:thumbnail')?.getAttribute('url'),
      channelTitle: entry.getElement('author')?.getElement('name')?.innerText,
      publishedAt: published != null ? DateTime.tryParse(published) : null,
    );
  }
}

/// 서비스 예외 클래스
class YouTubeServiceException implements Exception {
  final String message;

  YouTubeServiceException(this.message);

  @override
  String toString() => message;
}
