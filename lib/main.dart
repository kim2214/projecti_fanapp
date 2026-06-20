import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/notification_controller.dart';
import 'package:projecti_fan_app/controllers/theme_controller.dart';
import 'package:projecti_fan_app/default_firebase_options.dart';
import 'package:projecti_fan_app/router.dart';
import 'package:projecti_fan_app/theme/app_theme.dart';
import 'package:projecti_fan_app/widget/splash_screen.dart';

/// 백그라운드/종료 상태에서 FCM 메시지를 받을 때 실행되는 최상위 핸들러.
/// notification 페이로드가 있으면 시스템이 트레이에 자동 표시하므로 별도 처리 불필요.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 현재는 표시 외 처리할 작업이 없어 비워둔다.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 테마 모드를 첫 빌드 전에 선로딩 (플래시 방지)
  final themeController = ThemeController();
  await themeController.load();
  Get.put(themeController, permanent: true);

  // 푸시 알림 권한 요청 + 토픽 구독 동기화
  final notificationController = NotificationController();
  await notificationController.init();
  Get.put(notificationController, permanent: true);

  runApp(const MyApp());
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
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SplashScreen();
  }
}
