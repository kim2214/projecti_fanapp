import 'package:projecti_fan_app/model/group.dart';

/// 스케줄·생일 알림을 탭했을 때 열 화면. 앱 안의 바로가기(프로필 → 영상 더보기)도
/// 같은 경로로 기본 화면에 이동을 맡긴다.
enum NotificationTargetType {
  /// 해당 그룹의 스케줄 탭
  schedule,

  /// 해당 멤버의 프로필
  birthday,

  /// 해당 멤버를 고른 YouTube 탭 (앱 안 바로가기 전용 — 서버 데이터로는 오지 않는다)
  videos,
}

/// 알림 데이터(FCM `data`)에서 읽은 이동 대상.
///
/// 서버(`functions/index.js`)가 스케줄·생일 푸시에 `{type, group, memberKey}`를
/// 싣는다. 데이터가 없거나 형식이 다르면(예전 서버·알 수 없는 그룹) null — 이때는
/// 예전처럼 앱만 열린다.
class NotificationTarget {
  final NotificationTargetType type;
  final Group group;
  final String? memberKey;

  const NotificationTarget({
    required this.type,
    required this.group,
    this.memberKey,
  });

  static NotificationTarget? fromData(Map<String, dynamic> data) {
    final type = switch (data['type']) {
      'schedule' => NotificationTargetType.schedule,
      'birthday' => NotificationTargetType.birthday,
      _ => null,
    };
    final rawGroup = data['group'];
    final group = rawGroup is String ? Group.fromId(rawGroup) : null;
    if (type == null || group == null) return null;
    final rawKey = data['memberKey'];
    return NotificationTarget(
      type: type,
      group: group,
      memberKey: rawKey is String && rawKey.isNotEmpty ? rawKey : null,
    );
  }
}
