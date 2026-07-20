import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:projecti_fan_app/model/member.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// 푸시 알림(FCM) 권한·토픽 구독을 관리하고 설정을 기기에 영속화한다.
///
/// - 스케줄 알림: 그룹별 토픽(`schedule_honeyz`, `schedule_acaxia`). 그룹별 on/off, 기본 ON.
/// - 라이브 알림: 최애 멤버별 토픽(`live_<memberKey>`). 서버 폴링(Cloud Function
///   pollLiveStatus)이 CLOSE→OPEN 전이를 감지해 발송한다. 구독 대상은 최애 목록을
///   따라가며, [FavoritesController]가 변경 시 [syncLiveSubscriptions]로 알려준다.
class NotificationController extends GetxController {
  static const String _prefsPrefix = 'noti_schedule_'; // + group

  /// 안드로이드 알림 채널 ID — Cloud Function의 channelId와 반드시 일치해야 한다.
  static const String scheduleChannelId = 'schedule_channel';
  static const String liveChannelId = 'live_channel';

  /// 현재 구독 중인 라이브 멤버 key 집합(영속). 최애 변경 시 이 집합과 diff해
  /// 추가/해제만 수행하고, 앱 재시작 후에도 실제 구독 상태를 추적한다.
  static const String _liveTopicsKey = 'noti_live_topics';

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

    // 알림 탭(백그라운드/종료 상태)으로 앱이 열렸을 때의 처리
    _setupInteraction();
  }

  Future<void> _initLocalNotifications() async {
    const androidInit =
        AndroidInitializationSettings('@mipmap/projecti_fanapp_icon');
    const initSettings = InitializationSettings(android: androidInit);
    // 포그라운드에서 우리가 직접 띄운 로컬 알림의 탭 콜백.
    await _localNoti.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    final androidImpl = _localNoti.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // 스케줄 알림용 채널 (Android 8.0+)
    const scheduleChannel = AndroidNotificationChannel(
      scheduleChannelId,
      '스케줄 알림',
      description: '멤버 스케줄이 등록되면 알려드립니다.',
      importance: Importance.high,
    );
    await androidImpl?.createNotificationChannel(scheduleChannel);

    // 라이브 알림용 채널 — 스케줄과 분리해 사용자가 개별로 끌 수 있게 한다.
    const liveChannel = AndroidNotificationChannel(
      liveChannelId,
      '라이브 알림',
      description: '최애 멤버가 방송을 시작하면 알려드립니다.',
      importance: Importance.high,
    );
    await androidImpl?.createNotificationChannel(liveChannel);
  }

  Future<void> _requestPermission() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// 저장된 설정을 읽어 스케줄 토픽 구독 상태를 동기화한다.
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

  /// 최애 멤버 목록에 맞춰 라이브 토픽(`live_<key>`) 구독을 동기화한다.
  /// [FavoritesController]가 최애 로드/토글 후 호출한다.
  ///
  /// 영속된 구독 집합과 diff해 추가/해제할 토픽만 처리하므로, 중복 구독이나
  /// 불필요한 네트워크 호출이 없다.
  Future<void> syncLiveSubscriptions(Set<String> favoriteKeys) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_liveTopicsKey) ?? const []).toSet();

    final toAdd = favoriteKeys.difference(current);
    final toRemove = current.difference(favoriteKeys);

    for (final key in toAdd) {
      await FirebaseMessaging.instance.subscribeToTopic('live_$key');
    }
    for (final key in toRemove) {
      await FirebaseMessaging.instance.unsubscribeFromTopic('live_$key');
    }
    await prefs.setStringList(_liveTopicsKey, favoriteKeys.toList());
  }

  /// 포그라운드에서 받은 FCM 메시지를 로컬 알림으로 표시.
  void showForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final isLive = message.data['type'] == 'live';
    final channelId = isLive ? liveChannelId : scheduleChannelId;
    final channelName = isLive ? '라이브 알림' : '스케줄 알림';
    final channelDesc =
        isLive ? '최애 멤버가 방송을 시작하면 알려드립니다.' : '멤버 스케줄이 등록되면 알려드립니다.';
    // 라이브 알림은 탭 시 치지직으로 이동할 수 있게 broadcastId를 payload로 실는다.
    final payload = isLive ? message.data['broadcastId'] : null;

    _localNoti.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/projecti_fanapp_icon',
        ),
      ),
      payload: payload,
    );
  }

  /// 백그라운드/종료 상태에서 알림을 탭해 앱이 열렸을 때의 진입 처리.
  void _setupInteraction() {
    // 종료 상태에서 알림 탭으로 콜드 스타트한 경우
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleRemoteTap(message);
    });
    // 백그라운드(앱은 살아있음)에서 알림 탭한 경우
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteTap);
  }

  void _handleRemoteTap(RemoteMessage message) {
    if (message.data['type'] == 'live') {
      _openChzzkLive(message.data['broadcastId']);
    }
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    // 포그라운드 로컬 알림의 payload = broadcastId (라이브 알림에만 존재)
    _openChzzkLive(response.payload);
  }

  Future<void> _openChzzkLive(String? broadcastId) async {
    if (broadcastId == null || broadcastId.isEmpty) return;
    final uri = Uri.parse(Member.liveUrlOf(broadcastId));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
