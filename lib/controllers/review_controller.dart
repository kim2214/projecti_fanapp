import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱을 충분히·긍정적으로 사용한 시점에 네이티브 인앱 리뷰(스토어 평점) 요청을
/// 띄운다. 실행 횟수와 마지막 요청일을 기기 로컬에 영속화해 과도한 노출을 막는다.
///
/// 실제 다이얼로그 노출 여부는 OS가 연간 쿼터로 최종 결정하며, requestReview()는
/// 성공/노출 여부를 알려주지 않는다. 따라서 "요청을 시도했다"는 사실만으로
/// 마지막 요청일을 기록해, 우리 쪽에서 반복 호출하지 않도록 한다.
class ReviewController extends GetxService {
  ReviewController({InAppReview? inAppReview})
      : _inAppReview = inAppReview ?? InAppReview.instance;

  static const String _kLaunchCount = 'review_launch_count';
  static const String _kLastRequestEpochDay = 'review_last_request_day';

  /// 리뷰 요청 전 필요한 최소 누적 실행 횟수 (첫인상 구간 회피).
  static const int minLaunches = 3;

  /// 두 번의 리뷰 요청 사이 최소 간격(일).
  static const int minDaysBetween = 60;

  final InAppReview _inAppReview;

  /// main()에서 앱 실행마다 1회 호출해 누적 실행 횟수를 늘린다.
  Future<void> registerAppLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_kLaunchCount) ?? 0;
    await prefs.setInt(_kLaunchCount, count + 1);
  }

  /// 긍정적 순간(최애 지정 직후·홈 진입 등)에 호출한다. 조건을 만족하고 기기에서
  /// 리뷰 요청이 가능할 때만 실제로 요청하며, 실패는 흐름을 막지 않도록 삼킨다.
  Future<void> maybeRequestReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final launchCount = prefs.getInt(_kLaunchCount) ?? 0;
      final lastRequestEpochDay = prefs.getInt(_kLastRequestEpochDay);

      if (!isEligible(
        launchCount: launchCount,
        lastRequestEpochDay: lastRequestEpochDay,
        todayEpochDay: _todayEpochDay(),
      )) {
        return;
      }

      // Play 미설치·디버그/사이드로드 빌드에선 false가 정상이며 다이얼로그도 안 뜬다.
      if (!await _inAppReview.isAvailable()) return;

      await _inAppReview.requestReview();
      // 노출 여부는 OS가 결정하므로 알 수 없다. 시도했다는 사실만 기록해
      // 반복 호출을 막는다.
      await prefs.setInt(_kLastRequestEpochDay, _todayEpochDay());
    } catch (e, st) {
      // 리뷰 요청 실패가 앱 사용을 방해해선 안 된다. non-fatal로만 관측.
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: '인앱 리뷰 요청 실패',
        fatal: false,
      );
    }
  }

  /// 리뷰를 요청해도 되는지 판정한다 (SharedPreferences/시계와 분리된 순수 로직).
  /// - 누적 실행 횟수가 [minLaunches] 이상
  /// - 이전 요청이 없거나, 마지막 요청으로부터 [minDaysBetween]일 이상 경과
  @visibleForTesting
  static bool isEligible({
    required int launchCount,
    required int? lastRequestEpochDay,
    required int todayEpochDay,
  }) {
    if (launchCount < minLaunches) return false;
    if (lastRequestEpochDay == null) return true;
    return todayEpochDay - lastRequestEpochDay >= minDaysBetween;
  }

  /// 에포크(1970-01-01) 기준 경과 일수. 시:분:초/타임존 노이즈 없이 "며칠 지났나"만 본다.
  static int _todayEpochDay() =>
      DateTime.now().millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
}
