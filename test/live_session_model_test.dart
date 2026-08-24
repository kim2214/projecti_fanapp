// LiveSessionModel(지난 방송 세션) 파싱·파생 라벨 단위 테스트.
// Firestore 없이 fromJson에 값을 주입해 검증한다 (기존 테스트 관례).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/model/live_session_model.dart';

void main() {
  group('LiveSessionModel', () {
    test('서버 기록 문서를 파싱하고 파생 라벨을 만든다', () {
      final session = LiveSessionModel.fromJson({
        'liveTitle': '게릴라 방송',
        'liveCategoryValue': 'Just Chatting',
        'openDate': '2026-08-23 20:00:00',
        'endedAt': Timestamp.fromDate(DateTime(2026, 8, 23, 23, 12)),
        'peakConcurrentUserCount': 1384,
      });

      expect(session.liveTitle, '게릴라 방송');
      expect(session.dateLabel, '8/23');
      expect(session.durationLabel, '3시간 12분');
      expect(session.peakViewerText, '최고 1,384명');
    });

    test('1시간 미만 방송은 분 단위로만 표기', () {
      final session = LiveSessionModel.fromJson({
        'openDate': '2026-08-23 20:00:00',
        'endedAt': Timestamp.fromDate(DateTime(2026, 8, 23, 20, 45)),
      });
      expect(session.durationLabel, '45분');
    });

    test('필드 누락·형식 오류에도 크래시 없이 빈 라벨', () {
      final session = LiveSessionModel.fromJson(const {});
      expect(session.durationLabel, '');
      expect(session.dateLabel, '');
      expect(session.peakViewerText, '');

      // openDate가 숫자 등 예상 밖 타입이어도 안전.
      final weird = LiveSessionModel.fromJson(const {
        'openDate': 12345,
        'endedAt': 'not-a-timestamp',
      });
      expect(weird.startedAt, isNull);
      expect(weird.endedAt, isNull);
    });

    test('종료가 시작보다 이르면(시계 불일치) 길이는 표기하지 않음', () {
      final session = LiveSessionModel.fromJson({
        'openDate': '2026-08-23 20:00:00',
        'endedAt': Timestamp.fromDate(DateTime(2026, 8, 23, 19, 0)),
      });
      expect(session.duration, isNull);
      expect(session.durationLabel, '');
    });
  });
}
