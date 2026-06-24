// 순수 로직(외부 의존성 없는 모델 계산) 단위 테스트.
// Firebase/GetX 초기화가 필요 없는 결정적 로직만 검증한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/model/live_check_model.dart';
import 'package:projecti_fan_app/model/member.dart';
import 'package:projecti_fan_app/model/streamer_model.dart';
import 'package:projecti_fan_app/model/youtube_video_model.dart';

void main() {
  group('LiveCheckModel', () {
    test('isLive는 status가 OPEN일 때만 true', () {
      expect(LiveCheckModel(status: 'OPEN').isLive, isTrue);
      expect(LiveCheckModel(status: 'CLOSE').isLive, isFalse);
      expect(LiveCheckModel(status: null).isLive, isFalse);
    });

    test('viewerCountText는 천 단위 콤마를 붙인다', () {
      expect(LiveCheckModel(concurrentUserCount: 1384).viewerCountText,
          '1,384명');
      expect(LiveCheckModel(concurrentUserCount: 384).viewerCountText, '384명');
      expect(LiveCheckModel(concurrentUserCount: 1000000).viewerCountText,
          '1,000,000명');
      expect(LiveCheckModel(concurrentUserCount: null).viewerCountText, '');
    });

    test('uptime은 openDate가 없거나 형식이 틀리면 빈 문자열', () {
      expect(LiveCheckModel(openDate: null).uptime, '');
      expect(LiveCheckModel(openDate: 'not-a-date').uptime, '');
    });

    test('fromJson 라운드트립', () {
      final model = LiveCheckModel.fromJson({
        'liveTitle': '테스트 방송',
        'status': 'OPEN',
        'concurrentUserCount': 42,
      });
      expect(model.liveTitle, '테스트 방송');
      expect(model.isLive, isTrue);
      expect(model.concurrentUserCount, 42);
    });
  });

  group('StreamerModel 생일 계산', () {
    test('birthdayLabel은 MM-DD를 한국어 라벨로 변환', () {
      expect(_streamerWithBirthday('03-15').birthdayLabel, '3월 15일');
      expect(_streamerWithBirthday('12-01').birthdayLabel, '12월 1일');
    });

    test('잘못된 형식의 생일은 null 처리', () {
      expect(_streamerWithBirthday(null).birthdayLabel, isNull);
      expect(_streamerWithBirthday('abc').birthdayLabel, isNull);
      expect(_streamerWithBirthday('13-40').birthdayLabel, isNull); // 월/일 범위 초과
      expect(_streamerWithBirthday('2024-03-15').birthdayLabel, isNull); // MM-DD 아님
    });

    test('daysUntilBirthday는 유효한 생일에 대해 0~366 범위', () {
      final days = _streamerWithBirthday('06-15').daysUntilBirthday;
      expect(days, isNotNull);
      expect(days! >= 0 && days <= 366, isTrue);
    });

    test('생일 미설정이면 daysUntilBirthday는 null', () {
      expect(StreamerModel.empty().daysUntilBirthday, isNull);
      expect(StreamerModel.empty().birthdayLabel, isNull);
    });
  });

  group('Member', () {
    const member = Member(
      key: 'ohwayo',
      name: '오화요',
      group: 'honeyz',
      chzzkBroadcastId: 'abc123',
      youtubeChannelId: 'UC123',
    );

    test('profileAssetPath는 그룹/키 기반 경로', () {
      expect(member.profileAssetPath, 'assets/honeyz/ohwayo_profile.png');
    });

    test('isHoneyz / assetName', () {
      expect(member.isHoneyz, isTrue);
      expect(member.assetName, 'ohwayo');
    });
  });

  group('YouTubeVideoModel 캐시 직렬화', () {
    test('toJson -> fromJson 라운드트립으로 모든 필드 보존', () {
      final original = YouTubeVideoModel(
        videoId: 'abc123',
        title: '테스트 영상',
        description: '설명',
        thumbnailUrl: 'https://img/thumb.jpg',
        channelTitle: '오화요',
        publishedAt: DateTime.utc(2026, 6, 15, 9, 30),
      );

      final restored = YouTubeVideoModel.fromJson(original.toJson());

      expect(restored.videoId, 'abc123');
      expect(restored.title, '테스트 영상');
      expect(restored.description, '설명');
      expect(restored.thumbnailUrl, 'https://img/thumb.jpg');
      expect(restored.channelTitle, '오화요');
      expect(restored.publishedAt, DateTime.utc(2026, 6, 15, 9, 30));
    });

    test('publishedAt이 null이어도 안전하게 직렬화/복원', () {
      final restored =
          YouTubeVideoModel.fromJson(YouTubeVideoModel().toJson());
      expect(restored.publishedAt, isNull);
      expect(restored.videoId, isNull);
    });
  });
}

StreamerModel _streamerWithBirthday(String? birthday) => StreamerModel(
      name: 'tester',
      profileName: null,
      youtube: null,
      chzzk: null,
      twitter: null,
      birthday: birthday,
    );
