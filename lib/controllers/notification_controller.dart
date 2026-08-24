import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/model/member.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projecti_fan_app/utils/external_link.dart';

/// 푸시 알림(FCM) 권한·토픽 구독을 관리하고 설정을 기기에 영속화한다.
///
/// - 스케줄 알림: 그룹별 토픽(`schedule_honeyz`, `schedule_acaxia`). 그룹별 on/off,
///   기본 ON. 생일 푸시도 이 토픽으로 온다.
/// - 라이브 알림: 멤버별 토픽(`live_<memberKey>`). 서버 폴링(Cloud Function
///   pollLiveStatus)이 방송 시작을 감지해 발송한다. 구독 범위는 [liveMode]
///   ('all' 전체 / 'favorites' 최애만(기본) / 'off' 끄기)가 정하고, 최애 목록이
///   바뀌면 [FavoritesController]가 [syncLiveSubscriptions]로 알려준다.
class NotificationController extends GetxController {
  static const String _prefsPrefix = 'noti_schedule_'; // + group

  /// 라이브 알림 모드 영속화 키 ('all' | 'favorites' | 'off')
  static const String _liveModePrefsKey = 'noti_live_mode';

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

  /// 라이브 알림 모드. 기본 'favorites'(최애만) — 기존 동작과 동일.
  final RxString liveMode = 'favorites'.obs;
  bool _liveModeLoaded = false;

  /// 마지막으로 전달받은 최애 key 집합 — 모드 변경 시 재조정에 쓴다.
  Set<String> _favoriteKeys = const {};

  bool _initialized = false;

  /// 포그라운드 로컬 알림 ID. `notification.hashCode`는 값이 겹치면 이전 알림을
  /// 덮어써 조용히 사라질 수 있어, 매 알림마다 고유하도록 단조 증가시킨다.
  /// (Android 알림 ID는 32비트 int — 세션 내 증가로 충분하다.)
  int _foregroundNotiId = 0;

  /// main()에서 Firebase 초기화 직후 1회 호출.
  ///
  /// 각 단계는 서로 독립적이다 — 앞 단계가 실패해도 뒤 단계는 진행한다.
  /// (예전엔 한 단계가 던지면 나머지가 통째로 건너뛰어져, 권한 요청이 실패하면
  ///  스케줄 토픽 구독까지 안 되고 그 실행 동안 알림을 받지 못했다.)
  Future<void> init() async {
    if (_initialized) return;

    await _step(_initLocalNotifications, '로컬 알림 채널 생성');
    await _step(_requestPermission, 'FCM 권한 요청');
    await _step(_loadAndApplySubscriptions, '스케줄 토픽 구독');

    // 포그라운드 수신 시 로컬 알림으로 직접 표시
    FirebaseMessaging.onMessage.listen(showForegroundMessage);

    // 알림 탭(백그라운드/종료 상태)으로 앱이 열렸을 때의 처리
    _setupInteraction();

    // 모든 단계를 시도한 뒤에만 완료로 표시한다.
    _initialized = true;
  }

  /// 초기화 한 단계를 실행하고, 실패는 non-fatal로만 기록한다.
  /// 어느 단계에서 막혔는지 [label]로 구분할 수 있게 한다.
  Future<void> _step(Future<void> Function() action, String label) async {
    try {
      await action();
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: '알림 초기화 실패: $label',
        fatal: false,
      );
    }
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

  /// 최애 멤버 목록 변경을 반영한다. [FavoritesController]가 로드/토글 후 호출한다.
  /// 실제 구독 대상은 [liveMode]에 따라 [desiredLiveTopics]가 정한다.
  Future<void> syncLiveSubscriptions(Set<String> favoriteKeys) async {
    _favoriteKeys = favoriteKeys;
    await _reconcileLiveTopics();
  }

  /// 라이브 알림 모드 변경 — 토픽 구독 재조정과 설정 저장을 함께 처리한다.
  Future<void> setLiveMode(String mode) async {
    if (mode != 'all' && mode != 'favorites' && mode != 'off') return;
    liveMode.value = mode;
    _liveModeLoaded = true; // 사용자가 방금 정한 값이 저장값보다 우선
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_liveModePrefsKey, mode);
    await _reconcileLiveTopics();
  }

  /// 모드에 따른 라이브 알림 구독 대상 key 집합. (순수 판정 — 테스트 대상)
  @visibleForTesting
  static Set<String> desiredLiveTopics(
      String mode, Set<String> favoriteKeys, List<String> allKeys) {
    switch (mode) {
      case 'off':
        return const {};
      case 'all':
        return allKeys.toSet();
      default: // 'favorites' (기본)
        return favoriteKeys;
    }
  }

  static List<String> get _allMemberKeys => [
        for (final m in GlobalController.honeyzMembers) m.key,
        for (final m in GlobalController.acaxiaMembers) m.key,
      ];

  /// 원하는 구독 집합(모드×최애)과 영속된 실제 구독 집합을 diff해 추가/해제할
  /// 토픽만 처리한다 — 중복 구독이나 불필요한 네트워크 호출이 없다.
  Future<void> _reconcileLiveTopics() async {
    final prefs = await SharedPreferences.getInstance();

    // 저장된 모드는 첫 재조정 시점에 지연 로드한다 — FavoritesController의
    // 첫 동기화가 init()보다 먼저 도착해도 저장된 모드가 적용되게.
    if (!_liveModeLoaded) {
      final saved = prefs.getString(_liveModePrefsKey);
      if (saved == 'all' || saved == 'favorites' || saved == 'off') {
        liveMode.value = saved!;
      }
      _liveModeLoaded = true;
    }

    final desired =
        desiredLiveTopics(liveMode.value, _favoriteKeys, _allMemberKeys);
    final current = (prefs.getStringList(_liveTopicsKey) ?? const []).toSet();

    for (final key in desired.difference(current)) {
      await FirebaseMessaging.instance.subscribeToTopic('live_$key');
    }
    for (final key in current.difference(desired)) {
      await FirebaseMessaging.instance.unsubscribeFromTopic('live_$key');
    }
    await prefs.setStringList(_liveTopicsKey, desired.toList());
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
      id: _foregroundNotiId++,
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
    // onError를 붙이지 않으면 실패가 아무에게도 잡히지 않아 fatal로 집계된다.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleRemoteTap(message);
    }).catchError((Object e, StackTrace st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: '알림 탭 콜드스타트 진입 메시지 조회 실패',
        fatal: false,
      );
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
    await openExternalUrl(uri);
  }
}
