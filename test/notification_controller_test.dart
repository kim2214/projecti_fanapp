// NotificationController의 라이브 알림 구독 대상 판정과 토픽 재조정 단위 테스트.
// FCM 구독/해제는 생성자로 주입한 가짜 함수로, 저장소는 SharedPreferences 목으로 대신한다.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/controllers/notification_controller.dart';
import 'package:projecti_fan_app/model/group.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 호출을 기록하고, [hold]가 켜져 있으면 테스트가 완료시킬 때까지 멈추는 가짜 FCM.
class _FakeTopics {
  final List<String> calls = [];
  final List<Completer<void>> held = [];
  bool hold = false;

  Future<void> subscribe(String topic) => _record('+$topic');
  Future<void> unsubscribe(String topic) => _record('-$topic');

  Future<void> _record(String call) {
    calls.add(call);
    if (!hold) return Future.value();
    final c = Completer<void>();
    held.add(c);
    return c.future;
  }
}

Future<List<String>?> _savedTopics() async =>
    (await SharedPreferences.getInstance()).getStringList('noti_live_topics');

void main() {
  const allKeys = ['a', 'b', 'c'];
  const favorites = {'b'};

  group('desiredLiveTopics (라이브 알림 구독 대상)', () {
    test("'favorites'(기본)는 최애 집합 그대로", () {
      expect(
        NotificationController.desiredLiveTopics(
            'favorites', favorites, allKeys),
        {'b'},
      );
    });

    test("'all'은 최애와 무관하게 전체 멤버", () {
      expect(
        NotificationController.desiredLiveTopics('all', favorites, allKeys),
        {'a', 'b', 'c'},
      );
      expect(
        NotificationController.desiredLiveTopics('all', const {}, allKeys),
        {'a', 'b', 'c'},
      );
    });

    test("'off'는 최애가 있어도 빈 집합 — 전부 구독 해제", () {
      expect(
        NotificationController.desiredLiveTopics('off', favorites, allKeys),
        isEmpty,
      );
    });

    test('알 수 없는 모드 값은 기본(최애만)으로 동작', () {
      expect(
        NotificationController.desiredLiveTopics('weird', favorites, allKeys),
        {'b'},
      );
    });
  });

  group('syncLiveSubscriptions (토픽 재조정)', () {
    late _FakeTopics fcm;
    late NotificationController c;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fcm = _FakeTopics();
      c = NotificationController(
        subscribeToTopic: fcm.subscribe,
        unsubscribeFromTopic: fcm.unsubscribe,
      );
    });

    test('최애 추가·해제를 저장된 구독 집합과 diff해 필요한 것만 호출', () async {
      await c.syncLiveSubscriptions({'damyui'});
      expect(fcm.calls, ['+live_damyui']);
      expect(await _savedTopics(), ['damyui']);

      fcm.calls.clear();
      await c.syncLiveSubscriptions({'damyui'}); // 변화 없음 → 호출 없음
      expect(fcm.calls, isEmpty);

      await c.syncLiveSubscriptions({});
      expect(fcm.calls, ['-live_damyui']);
      expect(await _savedTopics(), isEmpty);
    });

    test('해제 중에 바로 재지정해도 최종 구독이 남는다 (재조정 직렬화)', () async {
      await c.syncLiveSubscriptions({'damyui'});
      fcm.calls.clear();
      fcm.hold = true;

      final unfav = c.syncLiveSubscriptions({}); // 해제가 진행 중인 채로
      await pumpEventQueue();
      final refav = c.syncLiveSubscriptions({'damyui'}); // 바로 재지정
      await pumpEventQueue();
      expect(fcm.calls, ['-live_damyui']); // 두 번째는 첫 번째가 끝나길 기다린다

      fcm.held.removeAt(0).complete();
      await unfav;
      await pumpEventQueue();
      expect(fcm.calls, ['-live_damyui', '+live_damyui']);

      fcm.held.removeAt(0).complete();
      await refav;
      expect(await _savedTopics(), ['damyui']);
    });

    test('구독 실패는 호출부로 전달되고, 다음 재조정은 계속 동작한다', () async {
      final failing = NotificationController(
        subscribeToTopic: (_) => Future.error(Exception('offline')),
        unsubscribeFromTopic: fcm.unsubscribe,
      );
      await expectLater(
          failing.syncLiveSubscriptions({'damyui'}), throwsException);
      expect(await _savedTopics(), isNull); // 실패하면 저장하지 않아 다음에 재시도

      await failing.syncLiveSubscriptions({}); // 체인이 끊기지 않았다
      expect(await _savedTopics(), isEmpty);
    });
  });

  group('설정 화면 콜백 (오프라인 구독 실패)', () {
    late List<String> reported;
    late NotificationController c;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      reported = [];
      c = NotificationController(
        subscribeToTopic: (_) => Future.error(Exception('offline')),
        unsubscribeFromTopic: (_) => Future.error(Exception('offline')),
        reportError: (e, st, reason) => reported.add(reason),
      );
    });

    test('스케줄 알림: 구독이 실패해도 설정은 저장되고 예외를 던지지 않는다', () async {
      await c.setScheduleEnabled(Group.honeyz, false);

      expect(c.scheduleEnabled[Group.honeyz], isFalse);
      // 저장값이 있어야 다음 실행에서 저장값대로 구독을 다시 맞춘다.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('noti_schedule_honeyz'), isFalse);
      expect(reported, ['스케줄 알림 설정 반영 실패']);
    });

    test('라이브 모드: 구독이 실패해도 모드는 저장되고 예외를 던지지 않는다', () async {
      await c.setLiveMode('all');

      expect(c.liveMode.value, 'all');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('noti_live_mode'), 'all');
      // 구독 집합은 성공했을 때만 저장 — 다음 재조정에서 다시 시도된다.
      expect(await _savedTopics(), isNull);
      expect(reported, ['라이브 알림 모드 반영 실패']);
    });
  });
}
