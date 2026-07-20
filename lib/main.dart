import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/notification_controller.dart';
import 'package:projecti_fan_app/controllers/theme_controller.dart';
import 'package:projecti_fan_app/default_firebase_options.dart';
import 'package:projecti_fan_app/router.dart';
import 'package:projecti_fan_app/theme/app_theme.dart';

/// 백그라운드/종료 상태에서 FCM 메시지를 받을 때 실행되는 최상위 핸들러.
/// notification 페이로드가 있으면 시스템이 트레이에 자동 표시하므로 별도 처리 불필요.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 현재는 표시 외 처리할 작업이 없어 비워둔다.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android 15(SDK 35)부터 강제되는 edge-to-edge를 모든 버전에서 켠다.
  // (이전 버전과의 호환성을 위해 enableEdgeToEdge()를 호출하라는 권장사항 대응)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // google-services Gradle 플러그인을 적용하면서 네이티브(FirebaseInitProvider)가
  // 기본 앱을 자동 생성한다. 그 상태에서 옵션으로 다시 초기화하면 [core/duplicate-app]이
  // 발생하므로, 이미 초기화돼 있으면 무시하고 기존 앱을 재사용한다.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Crashlytics: 디버그 빌드의 크래시는 수집하지 않아 리포트 오염을 막는다.
  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

  // Flutter 프레임워크 에러와 그 밖의 비동기 에러를 모두 Crashlytics로 전달.
  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };

  // 테마 모드를 첫 빌드 전에 선로딩 (플래시 방지)
  final themeController = ThemeController();
  await themeController.load();
  Get.put(themeController, permanent: true);

  // 푸시 알림 컨트롤러는 즉시 등록하되, 초기화(FCM 권한 요청·토픽 구독 등
  // 네트워크 작업 포함)는 await하지 않는다. await하면 첫 프레임 전까지 runApp이
  // 막혀 시작 시 검정화면 + ANR("응답 없음")이 발생한다.
  final notificationController = NotificationController();
  Get.put(notificationController, permanent: true);

  runApp(const MyApp());

  // 첫 프레임을 그린 뒤 백그라운드로 알림 초기화 진행.
  // fire-and-forget이라 실패가 조용히 묻히거나 PlatformDispatcher를 통해 fatal
  // 크래시로 오분류되지 않도록, 여기서 직접 잡아 non-fatal로 기록한다.
  unawaited(notificationController.init().catchError((Object e, StackTrace st) {
    crashlytics.recordError(
      e,
      st,
      reason: '알림 초기화(NotificationController.init) 실패',
      fatal: false,
    );
  }));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(
      () => MaterialApp.router(
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeController.themeMode.value,
        // edge-to-edge에서 시스템바를 투명 처리하고 아이콘 명암을 테마에 맞춘다.
        // 색상 setter(deprecated) 대신 transparent + 아이콘 brightness만 지정.
        builder: (context, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final iconBrightness = isDark ? Brightness.light : Brightness.dark;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: iconBrightness,
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: iconBrightness,
              systemNavigationBarDividerColor: Colors.transparent,
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
