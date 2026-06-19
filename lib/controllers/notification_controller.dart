import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 푸시 알림(FCM) 권한·토픽 구독을 관리하고 설정을 기기에 영속화한다.
///
/// 스케줄 알림은 그룹별 토픽(`schedule_honeyz`, `schedule_acaxia`)으로 발송되며,
/// 사용자는 그룹별로 켜고 끌 수 있다. 기본값은 ON.
class NotificationController extends GetxController {
  static const String _prefsPrefix = 'noti_schedule_'; // + group

  /// 안드로이드 알림 채널 ID — Cloud Function의 channelId와 반드시 일치해야 한다.
  static const String scheduleChannelId = 'schedule_channel';

  static const List<String> _groups = ['honeyz', 'acaxia'];

  final FlutterLocalNotificationsPlugin _localNoti =
      FlutterLocalNotificationsPlugin();

  /// 그룹별 스케줄 알림 on/off 상태
  final RxMap<String, bool> scheduleEnabled = <String, bool>{
    'honeyz': true,
    'acaxia': true,
  }.obs;

  bool _initialized = false;

  /// main()에서 Firebase 초기화 직후 1회 호출.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _initLocalNotifications();
    await _requestPermission();
    await _loadAndApplySubscriptions();

    // 포그라운드 수신 시 로컬 알림으로 직접 표시
    FirebaseMessaging.onMessage.listen(showForegroundMessage);
  }

  Future<void> _initLocalNotifications() async {
    const androidInit =
        AndroidInitializationSettings('@mipmap/projecti_fanapp_icon');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNoti.initialize(initSettings);

    // 스케줄 알림용 채널 생성 (Android 8.0+)
    const channel = AndroidNotificationChannel(
      scheduleChannelId,
      '스케줄 알림',
      description: '멤버 스케줄이 등록되면 알려드립니다.',
      importance: Importance.high,
    );
    await _localNoti
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermission() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// 저장된 설정을 읽어 토픽 구독 상태를 동기화한다.
  Future<void> _loadAndApplySubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    for (final group in _groups) {
      final enabled = prefs.getBool('$_prefsPrefix$group') ?? true; // 기본 ON
      scheduleEnabled[group] = enabled;
      await _applySubscription(group, enabled);
    }
  }

  Future<void> _applySubscription(String group, bool enabled) async {
    final topic = 'schedule_$group';
    if (enabled) {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    }
  }

  /// 그룹별 스케줄 알림 켜기/끄기 — 토픽 구독과 설정 저장을 함께 처리한다.
  Future<void> setScheduleEnabled(String group, bool enabled) async {
    if (!_groups.contains(group)) return;
    scheduleEnabled[group] = enabled;
    await _applySubscription(group, enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefsPrefix$group', enabled);
  }

  /// 포그라운드에서 받은 FCM 메시지를 로컬 알림으로 표시.
  void showForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNoti.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          scheduleChannelId,
          '스케줄 알림',
          channelDescription: '멤버 스케줄이 등록되면 알려드립니다.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/projecti_fanapp_icon',
        ),
      ),
    );
  }
}
