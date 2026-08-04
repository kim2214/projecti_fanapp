import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// MaterialApp.router에 연결되는 전역 ScaffoldMessenger 키.
/// 위젯 context가 없는 곳(푸시 알림 탭 핸들러 등)에서도 스낵바를 띄우기 위해 사용한다.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// 외부 앱/브라우저로 URL을 연다.
///
/// 브라우저가 없거나 비활성화된 기기에서 url_launcher가 던지는
/// PlatformException(ACTIVITY_NOT_FOUND)을 삼키고 안내 스낵바만 띄운다.
/// 잡지 않으면 Crashlytics에 fatal로 집계된다.
Future<void> openExternalUrl(
  Uri uri, {
  String message = '링크를 열 수 있는 앱이 없습니다.',
}) async {
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) _showFailure(message);
  } catch (_) {
    _showFailure(message);
  }
}

void _showFailure(String message) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
