// 치지직 openDate(KST, 시간대 없음) 해석 — 기기 타임존과 무관한 절대 시각이어야 한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/utils/chzzk_date.dart';

void main() {
  test('"yyyy-MM-dd HH:mm:ss"는 KST(UTC+9)로 해석한다', () {
    expect(parseChzzkOpenDate('2026-08-23 20:00:00')!.toUtc(),
        DateTime.utc(2026, 8, 23, 11));
  });

  test('KST 자정 직후는 UTC 기준 전날로 넘어간다', () {
    expect(parseChzzkOpenDate('2026-01-01 03:30:15')!.toUtc(),
        DateTime.utc(2025, 12, 31, 18, 30, 15));
  });

  test('반환값은 로컬 시간 (Timestamp.toDate와 같은 기준)', () {
    expect(parseChzzkOpenDate('2026-08-23 20:00:00')!.isUtc, isFalse);
  });

  test('시간대가 붙은 ISO 문자열은 그 시간대를 따른다', () {
    expect(parseChzzkOpenDate('2026-08-23T11:00:00Z')!.toUtc(),
        DateTime.utc(2026, 8, 23, 11));
  });

  test('해석할 수 없으면 null', () {
    expect(parseChzzkOpenDate('not-a-date'), isNull);
    expect(parseChzzkOpenDate(''), isNull);
  });
}
