// YouTubeService.parseFeed의 RSS 파싱 로직 단위 테스트.
// 네트워크 없이 피드 XML 문자열을 직접 넣어 파싱 결과만 검증한다.
// (외부 피드 형식 변경이 가장 잘 터지는 지점이라 방어적으로 커버한다.)

import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/services/youtube_service.dart';

/// 실제 YouTube 채널 RSS(feeds/videos.xml)와 동일한 구조의 샘플.
String _feed(String entries) => '''
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns:yt="http://www.youtube.com/xml/schemas/2015"
      xmlns:media="http://search.yahoo.com/mrss/"
      xmlns="http://www.w3.org/2005/Atom">
  <title>채널 피드</title>
$entries
</feed>
''';

String _entry({
  String? videoId = 'VIDEO_1',
  String title = '첫 번째 영상',
  String published = '2026-07-18T10:00:00+00:00',
}) {
  final videoIdTag = videoId == null ? '' : '<yt:videoId>$videoId</yt:videoId>';
  return '''
  <entry>
    <id>yt:video:$videoId</id>
    $videoIdTag
    <title>$title</title>
    <author><name>채널명</name><uri>https://youtube.com/channel/x</uri></author>
    <published>$published</published>
    <media:group>
      <media:title>$title</media:title>
      <media:thumbnail url="https://i.ytimg.com/vi/$videoId/hqdefault.jpg" width="480" height="360"/>
      <media:description>설명 텍스트</media:description>
    </media:group>
  </entry>''';
}

void main() {
  group('YouTubeService.parseFeed', () {
    test('정상 피드의 엔트리를 모든 필드와 함께 파싱한다 (한글 보존)', () {
      final videos = YouTubeService.parseFeed(_feed(_entry()));

      expect(videos.length, 1);
      final v = videos.first;
      expect(v.videoId, 'VIDEO_1');
      expect(v.title, '첫 번째 영상');
      expect(v.channelTitle, '채널명');
      expect(v.thumbnailUrl, 'https://i.ytimg.com/vi/VIDEO_1/hqdefault.jpg');
      expect(v.publishedAt, DateTime.parse('2026-07-18T10:00:00+00:00'));
    });

    test('여러 엔트리를 피드 순서대로 반환한다', () {
      final feed = _feed(
        '${_entry(videoId: 'A', title: '영상 A')}\n'
        '${_entry(videoId: 'B', title: '영상 B')}',
      );

      final videos = YouTubeService.parseFeed(feed);
      expect(videos.map((v) => v.videoId).toList(), ['A', 'B']);
      expect(videos.map((v) => v.title).toList(), ['영상 A', '영상 B']);
    });

    test('videoId가 없는 엔트리는 제외한다', () {
      final feed = _feed(
        '${_entry(videoId: 'A')}\n'
        '${_entry(videoId: null)}',
      );

      final videos = YouTubeService.parseFeed(feed);
      expect(videos.length, 1);
      expect(videos.first.videoId, 'A');
    });

    test('entry가 없는 피드는 빈 목록', () {
      expect(YouTubeService.parseFeed(_feed('')), isEmpty);
    });

    test('published 형식이 잘못되면 publishedAt은 null (나머지는 파싱)', () {
      final videos =
          YouTubeService.parseFeed(_feed(_entry(published: 'not-a-date')));

      expect(videos.length, 1);
      expect(videos.first.publishedAt, isNull);
      expect(videos.first.videoId, 'VIDEO_1');
    });
  });
}
