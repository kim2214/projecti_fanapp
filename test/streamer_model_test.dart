// 생일 파생 로직 — "MM-DD"를 다음 생일/남은 일수/표시 라벨로 변환한다.
// now를 주입해 결정적으로 검증한다(getter는 DateTime.now()로 위임).

import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/model/streamer_model.dart';

StreamerModel withBirthday(String? birthday) => StreamerModel(
      name: 'x',
      profileName: 'x',
      youtube: null,
      chzzk: null,
      twitter: null,
      birthday: birthday,
    );

void main() {
  group('birthdayLabel', () {
    test('정상 "MM-DD" → "M월 D일"', () {
      expect(withBirthday('03-15').birthdayLabel, '3월 15일');
      expect(withBirthday('12-01').birthdayLabel, '12월 1일');
    });

    test('미설정/형식 오류 → null', () {
      expect(withBirthday(null).birthdayLabel, isNull);
      expect(withBirthday('0315').birthdayLabel, isNull); // 구분자 없음
      expect(withBirthday('13-01').birthdayLabel, isNull); // 월 범위 초과
      expect(withBirthday('00-15').birthdayLabel, isNull); // 월 범위 미만
      expect(withBirthday('03-40').birthdayLabel, isNull); // 일 범위 초과
      expect(withBirthday('aa-bb').birthdayLabel, isNull); // 숫자 아님
    });
  });

  group('nextBirthdayFrom / daysUntilBirthdayFrom', () {
    test('아직 안 지난 올해 생일', () {
      final m = withBirthday('03-15');
      final now = DateTime(2026, 1, 1);
      expect(m.nextBirthdayFrom(now), DateTime(2026, 3, 15));
      expect(m.daysUntilBirthdayFrom(now), 73);
    });

    test('이미 지난 생일은 내년으로 넘어간다', () {
      final m = withBirthday('01-01');
      final now = DateTime(2026, 12, 31);
      expect(m.nextBirthdayFrom(now), DateTime(2027, 1, 1));
      expect(m.daysUntilBirthdayFrom(now), 1);
    });

    test('오늘이 생일이면 남은 일수 0 (올해 유지)', () {
      final m = withBirthday('06-07');
      final now = DateTime(2026, 6, 7, 15, 30); // 시각이 있어도 날짜 기준
      expect(m.nextBirthdayFrom(now), DateTime(2026, 6, 7));
      expect(m.daysUntilBirthdayFrom(now), 0);
    });

    test('미설정/오류면 null', () {
      final now = DateTime(2026, 1, 1);
      expect(withBirthday(null).nextBirthdayFrom(now), isNull);
      expect(withBirthday(null).daysUntilBirthdayFrom(now), isNull);
      expect(withBirthday('13-01').daysUntilBirthdayFrom(now), isNull);
    });
  });

  group('그 달에 없는 날짜', () {
    test('"02-30"·"04-31"은 다음 달로 넘기지 않고 오류(null)', () {
      expect(withBirthday('02-30').birthdayLabel, isNull);
      expect(withBirthday('04-31').birthdayLabel, isNull);
      expect(withBirthday('02-30').daysUntilBirthdayFrom(DateTime(2026, 1, 1)),
          isNull);
    });

    test('2월 29일생은 평년엔 2월 28일, 윤년엔 2월 29일', () {
      final m = withBirthday('02-29');
      expect(m.birthdayLabel, '2월 29일');
      expect(m.nextBirthdayFrom(DateTime(2026, 1, 1)), DateTime(2026, 2, 28));
      expect(m.nextBirthdayFrom(DateTime(2027, 3, 1)), DateTime(2028, 2, 29));
    });
  });

  group('fromJson 타입 방어', () {
    test('문자열이 아닌 필드는 크래시 없이 null로 본다', () {
      final m = StreamerModel.fromJson({
        'name': '이름',
        'birthday': 315, // 숫자로 잘못 입력
        'youtube': ['잘못된', '값'],
        'chzzk': 'https://chzzk.naver.com/x',
      });
      expect(m.name, '이름');
      expect(m.birthday, isNull);
      expect(m.youtube, isNull);
      expect(m.chzzk, 'https://chzzk.naver.com/x');
    });
  });
}
