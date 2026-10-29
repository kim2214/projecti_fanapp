import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:projecti_fan_app/utils/app_snackbar.dart';

/// 스케줄 이미지 저장(갤러리)·공유. 화면에 이미 띄운 이미지라 extended_image
/// 캐시에서 바이트를 꺼내 쓴다 — 보통 네트워크를 다시 타지 않는다.
/// 결과는 전역 스낵바로 알리고, 예외는 밖으로 흘리지 않는다.

/// 이미지 바이트의 시그니처로 확장자를 고른다 (공유 파일 이름용).
/// 모르는 형식은 jpg로 둔다 — 받는 앱 대부분이 내용으로 다시 판별한다.
@visibleForTesting
String imageExtensionOf(Uint8List bytes) {
  bool startsWith(List<int> sig) =>
      bytes.length >= sig.length &&
      Iterable.generate(sig.length).every((i) => bytes[i] == sig[i]);

  if (startsWith(const [0x89, 0x50, 0x4E, 0x47])) return 'png';
  if (startsWith(const [0x47, 0x49, 0x46])) return 'gif';
  if (startsWith(const [0x52, 0x49, 0x46, 0x46]) &&
      bytes.length >= 12 &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return 'webp';
  }
  return 'jpg';
}

/// 저장·공유 파일 이름 (확장자 제외). 예: '오화요_스케줄_261029'.
@visibleForTesting
String scheduleImageBaseName(String memberName, DateTime now) {
  String two(int v) => v.toString().padLeft(2, '0');
  final date = '${two(now.year % 100)}${two(now.month)}${two(now.day)}';
  final name = memberName.trim().replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
  return name.isEmpty ? '스케줄_$date' : '${name}_스케줄_$date';
}

Future<Uint8List?> _loadBytes(String url) async {
  try {
    return await getNetworkImageData(url, useCache: true);
  } catch (_) {
    return null;
  }
}

/// 갤러리에 저장한다. 성공·실패 모두 스낵바로 알린다.
Future<void> saveScheduleImage(String url, String memberName) async {
  final bytes = await _loadBytes(url);
  if (bytes == null) {
    showAppSnackBar('이미지를 불러오지 못해 저장할 수 없어요');
    return;
  }
  try {
    // Android 10 이상·iOS 14 이상은 추가 전용 저장이라 보통 권한 창이 뜨지 않는다.
    if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
      showAppSnackBar('사진 저장 권한이 없어 저장하지 못했어요');
      return;
    }
    await Gal.putImageBytes(bytes,
        name: scheduleImageBaseName(memberName, DateTime.now()));
    showAppSnackBar('갤러리에 저장했어요');
  } catch (_) {
    showAppSnackBar('저장하지 못했어요. 잠시 후 다시 시도해 주세요');
  }
}

/// 시스템 공유 시트로 이미지를 보낸다.
Future<void> shareScheduleImage(String url, String memberName) async {
  final bytes = await _loadBytes(url);
  if (bytes == null) {
    showAppSnackBar('이미지를 불러오지 못해 공유할 수 없어요');
    return;
  }
  final ext = imageExtensionOf(bytes);
  final fileName = '${scheduleImageBaseName(memberName, DateTime.now())}.$ext';
  try {
    await SharePlus.instance.share(ShareParams(
      files: [
        XFile.fromData(bytes,
            mimeType: ext == 'jpg' ? 'image/jpeg' : 'image/$ext')
      ],
      fileNameOverrides: [fileName],
      text: memberName.isEmpty ? null : '$memberName 주간 스케줄',
    ));
  } catch (_) {
    showAppSnackBar('공유하지 못했어요. 잠시 후 다시 시도해 주세요');
  }
}
