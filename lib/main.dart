import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:projecti_fan_app/default_firebase_options.dart';
import 'package:projecti_fan_app/router.dart';
import 'package:projecti_fan_app/widget/audio_manager.dart';
import 'package:projecti_fan_app/widget/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  await AudioManager.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
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
