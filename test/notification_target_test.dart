// 스케줄·생일 알림 탭 데이터 → 이동 대상 판정 단위 테스트.
// 서버(functions/index.js)가 싣는 data 형식과 맞아야 한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/controllers/notification_controller.dart';
import 'package:projecti_fan_app/model/group.dart';
import 'package:projecti_fan_app/model/notification_target.dart';

void main() {
  group('NotificationTarget.fromData', () {
    test('스케줄 알림 → 해당 그룹 스케줄', () {
      final t = NotificationTarget.fromData(
          {'type': 'schedule', 'group': 'acaxia', 'memberKey': 'popopopo'});
      expect(t?.type, NotificationTargetType.schedule);
      expect(t?.group, Group.acaxia);
      expect(t?.memberKey, 'popopopo');
    });

    test('생일 알림 → 멤버 프로필', () {
      final t = NotificationTarget.fromData(
          {'type': 'birthday', 'group': 'honeyz', 'memberKey': 'honeychurros'});
      expect(t?.type, NotificationTargetType.birthday);
      expect(t?.group, Group.honeyz);
      expect(t?.memberKey, 'honeychurros');
    });

    test('예전 서버(데이터 없음)·라이브·알 수 없는 그룹은 null', () {
      expect(NotificationTarget.fromData({}), isNull);
      expect(NotificationTarget.fromData({'type': 'live', 'group': 'honeyz'}),
          isNull);
      expect(NotificationTarget.fromData({'type': 'schedule', 'group': 'nope'}),
          isNull);
      expect(NotificationTarget.fromData({'type': 'schedule'}), isNull);
    });

    test('memberKey가 비었거나 문자열이 아니면 null로 둔다', () {
      expect(
          NotificationTarget.fromData(
                  {'type': 'birthday', 'group': 'honeyz', 'memberKey': ''})
              ?.memberKey,
          isNull);
      expect(
          NotificationTarget.fromData(
                  {'type': 'birthday', 'group': 'honeyz', 'memberKey': 3})
              ?.memberKey,
          isNull);
    });
  });

  group('NotificationController.handleTapData', () {
    test('스케줄·생일 탭은 pendingTarget에 들어간다', () {
      final c = NotificationController(
          subscribeToTopic: (_) async {},
          unsubscribeFromTopic: (_) async {},
          reportError: (_, __, ___) {});
      c.handleTapData({'type': 'schedule', 'group': 'honeyz'});
      expect(c.pendingTarget.value?.type, NotificationTargetType.schedule);
      expect(c.pendingTarget.value?.group, Group.honeyz);
    });

    test('알 수 없는 데이터는 대기열을 건드리지 않는다', () {
      final c = NotificationController(
          subscribeToTopic: (_) async {},
          unsubscribeFromTopic: (_) async {},
          reportError: (_, __, ___) {});
      c.handleTapData({'type': 'widget_refresh'});
      expect(c.pendingTarget.value, isNull);
    });
  });
}
