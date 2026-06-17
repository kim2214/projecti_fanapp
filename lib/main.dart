import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/theme_controller.dart';
import 'package:projecti_fan_app/default_firebase_options.dart';
import 'package:projecti_fan_app/router.dart';
import 'package:projecti_fan_app/theme/app_theme.dart';
import 'package:projecti_fan_app/widget/audio_manager.dart';
import 'package:projecti_fan_app/widget/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  await AudioManager.initialize();

  // 테마 모드를 첫 빌드 전에 선로딩 (플래시 방지)
  final themeController = ThemeController();
  await themeController.load();
  Get.put(themeController, permanent: true);

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
