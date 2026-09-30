// 짧은 날짜 라벨 — 다른 해 기록에만 연도를 붙인다.

import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/utils/date_label.dart';

void main() {
  test('올해면 "M/d"', () {
    expect(shortDateLabel(DateTime(2026, 9, 11), now: DateTime(2026, 12, 31)),
        '9/11');
  });

  test('다른 해면 "yy.M.d" — 작년 기록이 올해처럼 읽히지 않게', () {
    expect(shortDateLabel(DateTime(2025, 9, 11), now: DateTime(2026, 1, 2)),
        '25.9.11');
    expect(shortDateLabel(DateTime(2027, 1, 3), now: DateTime(2026, 12, 31)),
        '27.1.3');
    expect(shortDateLabel(DateTime(2009, 2, 3), now: DateTime(2026, 1, 1)),
        '09.2.3');
  });
}
