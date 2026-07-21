// ReviewController.isEligible 순수 판정 로직 단위 테스트.
// SharedPreferences/시계/네이티브 리뷰 API 없이 경계 조건만 검증한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/controllers/review_controller.dart';

void main() {
  // 판정에 쓰는 임의의 기준 날짜(에포크 일수). 값 자체는 의미 없고 상대 간격만 본다.
  const today = 20000;

  group('ReviewController.isEligible', () {
    test('실행 횟수가 최소치 미만이면 요청하지 않는다', () {
      expect(
        ReviewController.isEligible(
          launchCount: ReviewController.minLaunches - 1,
          lastRequestEpochDay: null,
          todayEpochDay: today,
        ),
        isFalse,
      );
    });

    test('실행 횟수 충분 + 이전 요청 없음이면 요청한다', () {
      expect(
        ReviewController.isEligible(
          launchCount: ReviewController.minLaunches,
          lastRequestEpochDay: null,
          todayEpochDay: today,
        ),
        isTrue,
      );
    });

    test('마지막 요청 이후 간격이 부족하면 요청하지 않는다', () {
      expect(
        ReviewController.isEligible(
          launchCount: 100,
          lastRequestEpochDay: today - (ReviewController.minDaysBetween - 1),
          todayEpochDay: today,
        ),
        isFalse,
      );
    });

    test('마지막 요청 이후 최소 간격이 지나면 다시 요청한다', () {
      expect(
        ReviewController.isEligible(
          launchCount: 100,
          lastRequestEpochDay: today - ReviewController.minDaysBetween,
          todayEpochDay: today,
        ),
        isTrue,
      );
    });
  });
}
