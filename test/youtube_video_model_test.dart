// 영상 게시일 표기 — 상대 시간(relativeTime)과 절대 날짜(formattedDate).
// relativeTime은 now를 주입해 결정적으로, 특히 년/월/주 경계값을 고정한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/model/youtube_video_model.dart';

YouTubeVideoModel video(DateTime? publishedAt) =>
    YouTubeVideoModel(videoId: 'v', publishedAt: publishedAt);

void main() {
  final now = DateTime(2026, 10, 18, 12);

  group('relativeTimeFrom', () {
    test('publishedAt 없으면 빈 문자열', () {
      expect(video(null).relativeTimeFrom(now), '');
    });

    test('방금 전 / 시간 / 일', () {
      expect(video(now).relativeTimeFrom(now), '방금 전');
      expect(
          video(now.subtract(const Duration(hours: 5))).relativeTimeFrom(now),
          '5시간 전');
      expect(video(now.subtract(const Duration(days: 3))).relativeTimeFrom(now),
          '3일 전');
    });

    test('주 / 개월 / 년', () {
      expect(video(now.subtract(const Duration(days: 10))).relativeTimeFrom(now),
          '1주 전');
      expect(video(now.subtract(const Duration(days: 60))).relativeTimeFrom(now),
          '2개월 전');
      expect(
          video(now.subtract(const Duration(days: 400))).relativeTimeFrom(now),
          '1년 전');
    });

    test('경계값 — 7일/365일은 아래 단위에 걸린다(> 비교)', () {
      expect(video(now.subtract(const Duration(days: 7))).relativeTimeFrom(now),
          '7일 전'); // 7 > 7 == false
      expect(
          video(now.subtract(const Duration(days: 365))).relativeTimeFrom(now),
          '12개월 전'); // 365 > 365 == false → 365/30
      expect(
          video(now.subtract(const Duration(days: 366))).relativeTimeFrom(now),
          '1년 전');
    });
  });

  group('formattedDate', () {
    test('YYYY.MM.DD 제로패딩', () {
      expect(video(DateTime(2026, 3, 5)).formattedDate, '2026.03.05');
      expect(video(DateTime(2026, 12, 31)).formattedDate, '2026.12.31');
    });

    test('publishedAt 없으면 빈 문자열', () {
      expect(video(null).formattedDate, '');
    });
  });
}
