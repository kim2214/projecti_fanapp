// NotificationController의 순수 판정 로직(라이브 알림 구독 대상) 단위 테스트.
// FCM/SharedPreferences 없이 static 함수만 검증한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/controllers/notification_controller.dart';

void main() {
  const allKeys = ['a', 'b', 'c'];
  const favorites = {'b'};

  group('desiredLiveTopics (라이브 알림 구독 대상)', () {
    test("'favorites'(기본)는 최애 집합 그대로", () {
      expect(
        NotificationController.desiredLiveTopics('favorites', favorites, allKeys),
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
}
