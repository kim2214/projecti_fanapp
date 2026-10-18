// 천 단위 쉼표 표기 — 시청자 수·팔로워 수 표시에 공통 사용.

import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/utils/number_format.dart';

void main() {
  test('천 미만은 그대로', () {
    expect(formatCount(0), '0');
    expect(formatCount(1), '1');
    expect(formatCount(999), '999');
  });

  test('천 단위마다 쉼표 — 경계값 포함', () {
    expect(formatCount(1000), '1,000');
    expect(formatCount(1384), '1,384');
    expect(formatCount(10000), '10,000');
    expect(formatCount(1000000), '1,000,000');
  });
}
