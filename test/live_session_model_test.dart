// LiveSessionModel(지난 방송 세션) 파싱·파생 라벨 단위 테스트.
// Firestore 없이 fromJson에 값을 주입해 검증한다 (기존 테스트 관례).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/model/live_session_model.dart';
import 'package:projecti_fan_app/utils/date_label.dart';

/// KST 벽시계 시각 → 절대 시각. openDate 문자열(KST)과 같은 기준으로 맞춰
/// 기기·CI 타임존과 무관하게 결정적으로 검증한다.
DateTime _kst(int y, int mo, int d, int h, int mi) =>
    DateTime.utc(y, mo, d, h - 9, mi);

void main() {
  group('LiveSessionModel', () {
    test('서버 기록 문서를 파싱하고 파생 라벨을 만든다', () {
      final session = LiveSessionModel.fromJson({
        'liveTitle': '게릴라 방송',
        'liveCategoryValue': 'Just Chatting',
        'openDate': '2026-08-23 20:00:00',
        'endedAt': Timestamp.fromDate(_kst(2026, 8, 23, 23, 12)),
        'peakConcurrentUserCount': 1384,
      });

      expect(session.liveTitle, '게릴라 방송');
      // 연도 표기는 date_label_test가 검증 — 여기선 시작 시각을 쓰는지만 본다.
      expect(session.dateLabel, shortDateLabel(DateTime(2026, 8, 23)));
      expect(session.durationLabel, '3시간 12분');
      expect(session.peakViewerText, '최고 1,384명');
    });

    test('openDate 문자열은 기기 타임존과 무관하게 KST로 해석한다', () {
      final session =
          LiveSessionModel.fromJson({'openDate': '2026-08-23 20:00:00'});
      expect(session.startedAt!.toUtc(), DateTime.utc(2026, 8, 23, 11));
    });

    test('startedAt Timestamp가 있으면 openDate 문자열보다 우선한다', () {
      // 서버가 준 절대 시각(Timestamp)이 있으면 openDate 문자열은 쓰지 않는다.
      final session = LiveSessionModel.fromJson({
        'openDate': '2000-01-01 00:00:00', // 엉뚱한 값 — 무시돼야 함
        'startedAt': Timestamp.fromDate(DateTime(2026, 8, 23, 20, 0)),
        'endedAt': Timestamp.fromDate(DateTime(2026, 8, 23, 21, 30)),
      });
      expect(session.durationLabel, '1시간 30분');
      // 연도 표기는 date_label_test가 검증 — 여기선 시작 시각을 쓰는지만 본다.
      expect(session.dateLabel, shortDateLabel(DateTime(2026, 8, 23)));
    });

    test('endedAgoLabel: 종료 후 경과를 시간/분 단위로, 미래·직후는 "방금 종료"', () {
      final ended = DateTime(2026, 8, 23, 21, 0);
      final session = LiveSessionModel(endedAt: ended);
      expect(session.endedAgoLabel(now: DateTime(2026, 8, 23, 23, 30)),
          '2시간 전 종료');
      expect(session.endedAgoLabel(now: DateTime(2026, 8, 23, 21, 35)),
          '35분 전 종료');
      expect(session.endedAgoLabel(now: DateTime(2026, 8, 23, 21, 0, 20)),
          '방금 종료');
      expect(session.endedAgoLabel(now: DateTime(2026, 8, 23, 20, 0)), '방금 종료');
      expect(LiveSessionModel().endedAgoLabel(), '');
    });

    test('1시간 미만 방송은 분 단위로만 표기', () {
      final session = LiveSessionModel.fromJson({
        'openDate': '2026-08-23 20:00:00',
        'endedAt': Timestamp.fromDate(_kst(2026, 8, 23, 20, 45)),
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
        'endedAt': Timestamp.fromDate(_kst(2026, 8, 23, 19, 0)),
      });
      expect(session.duration, isNull);
      expect(session.durationLabel, '');
    });
  });
}
