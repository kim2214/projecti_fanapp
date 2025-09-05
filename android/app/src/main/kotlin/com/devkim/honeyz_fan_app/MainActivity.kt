package com.devkim.honeyz_fan_app

//// 1. FlutterActivity 대신 FlutterFragmentActivity를 import 합니다.
//import io.flutter.embedding.android.FlutterFragmentActivity
//import io.flutter.embedding.engine.FlutterEngine
//import io.flutter.plugins.GeneratedPluginRegistrant
//
//// 2. 클래스 상속을 FlutterActivity에서 FlutterFragmentActivity로 변경합니다.
//class MainActivity : FlutterFragmentActivity() {
//    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//        super.configureFlutterEngine(flutterEngine)
//        GeneratedPluginRegistrant.registerWith(flutterEngine)
//    }
//}

//package com.devkim.honeyz_fan_app
//
//import io.flutter.embedding.android.FlutterActivity
//
//class MainActivity: FlutterActivity() {
//
//}

//package com.example.app

import io.flutter.embedding.android.FlutterActivity
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity: AudioServiceActivity() {
}