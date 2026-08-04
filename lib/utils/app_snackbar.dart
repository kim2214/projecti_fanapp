import 'package:flutter/material.dart';

/// MaterialApp.router에 연결되는 전역 ScaffoldMessenger 키.
/// 위젯 context가 없는 곳(컨트롤러·푸시 알림 탭 핸들러 등)에서도 스낵바를 띄우기 위해 사용한다.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// 전역 스낵바. 아직 화면이 없으면(앱 시작 직후 등) 조용히 무시된다.
///
/// 이미 떠 있는 스낵바는 치우고 띄운다 — 여러 로드가 동시에 실패해도
/// 같은 안내가 줄줄이 쌓이지 않게 한다.
void showAppSnackBar(String message) {
  final messenger = scaffoldMessengerKey.currentState;
  if (messenger == null) return;
  messenger.removeCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
