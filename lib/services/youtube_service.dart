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

  // 주의: 커스텀 User-Agent(특히 모바일 UA)를 붙이면 이 피드 엔드포인트가
  // 404를 돌려주는 경우가 있어, 헤더 없이 기본 요청을 보낸다.

  YouTubeService._();

  static YouTubeService get instance {
    _instance ??= YouTubeService._();
    return _instance!;
  }

  /// 채널의 최신 영상 목록 가져오기.
  ///
  /// [timeout] 미지정 시 기본값([_requestTimeout])을 쓴다. 그룹 일괄 조회처럼
  /// 가장 느린 채널이 전체를 지연시키는 경우 더 짧은 값을 넘길 수 있다.
  ///
  /// [retries] 만큼 지수 백오프로 재시도한다. YouTube 피드는 정상 채널에도
  /// 간헐적으로 404/500을 반환하므로(레이트리밋/안티봇), 재시도로 대부분 복구된다.
  Future<List<YouTubeVideoModel>> getChannelVideos({
    required String channelId,
    Duration? timeout,
    int retries = 2,
  }) async {
    final uri = Uri.parse(_feedBaseUrl).replace(
      queryParameters: {'channel_id': channelId},
    );
    final effectiveTimeout = timeout ?? _requestTimeout;

    YouTubeServiceException lastError =
        YouTubeServiceException('영상 목록을 가져올 수 없습니다');

    for (var attempt = 0; attempt <= retries; attempt++) {
      if (attempt > 0) {
        // 지수 백오프: 300ms, 600ms, 1200ms ...
        await Future.delayed(
            Duration(milliseconds: 300 * (1 << (attempt - 1))));
      }
      try {
        final response = await http.get(uri).timeout(effectiveTimeout);

        if (response.statusCode == 200) {
          // 한글 제목 깨짐 방지를 위해 bodyBytes를 UTF-8로 디코딩
          final document = XmlDocument.parse(utf8.decode(response.bodyBytes));
          return document
              .findAllElements('entry')
              .map(_parseEntry)
              .where((video) => video.videoId != null)
              .toList();
        }
        lastError = YouTubeServiceException(
            '영상 목록을 가져올 수 없습니다 (${response.statusCode})');
      } catch (e) {
        lastError = e is YouTubeServiceException
            ? e
            : YouTubeServiceException('영상 목록을 가져올 수 없습니다: $e');
      }
    }

    throw lastError;
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
