import 'package:url_launcher/url_launcher.dart';
import 'package:projecti_fan_app/utils/app_snackbar.dart';

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
    if (!launched) showAppSnackBar(message);
  } catch (_) {
    showAppSnackBar(message);
  }
}
