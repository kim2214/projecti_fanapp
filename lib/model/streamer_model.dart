import 'package:flutter/foundation.dart';

class StreamerModel {
  final String? name;
  final String? profileName;
  final String? youtube;
  final String? chzzk;
  final String? twitter;

  /// 생일 (Firestore "birthday" 필드, "MM-DD" 형식. 연도는 무시하고 매년 반복)
  final String? birthday;

  /// 팬 커뮤니티 링크 (Firestore "cafe"/"discord" 필드, 선택). 없으면 프로필
  /// SNS 섹션에 카드가 나타나지 않는다.
  final String? cafe;
  final String? discord;

  StreamerModel(
      {required this.name,
      required this.profileName,
      required this.youtube,
      required this.chzzk,
      required this.twitter,
      this.birthday,
      this.cafe,
      this.discord});

  /// Firestore 문서가 없는 멤버용 빈 모델 (프로필 화면 라우트 폴백).
  factory StreamerModel.empty() => StreamerModel(
        name: null,
        profileName: null,
        youtube: null,
        chzzk: null,
        twitter: null,
      );

  /// Firestore 문서는 콘솔에서 손으로 고치므로 필드 타입이 틀릴 수 있다
  /// (예: birthday를 숫자·Timestamp로 입력). 문자열이 아닌 값은 없는 것으로
  /// 본다 — 그대로 넣으면 TypeError로 그룹 프로필 전체 로드가 실패한다.
  factory StreamerModel.fromJson(Map<String, dynamic> json) {
    String? str(String key) => json[key] is String ? json[key] as String : null;
    return StreamerModel(
      name: str("name"),
      profileName: str("profile_name"),
      youtube: str("youtube"),
      chzzk: str("chzzk"),
      twitter: str("twitter"),
      birthday: str("birthday"),
      cafe: str("cafe"),
      discord: str("discord"),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      // fromJson과 동일한 키를 써서 라운드트립이 깨지지 않게 한다.
      "profile_name": profileName,
      "youtube": youtube,
      "chzzk": chzzk,
      "twitter": twitter,
      "birthday": birthday,
      "cafe": cafe,
      "discord": discord,
    };
  }

  /// "MM-DD"를 (month, day)로 파싱. 형식이 잘못되면 null.
  (int, int)? get _monthDay {
    final raw = birthday;
    if (raw == null) return null;
    final parts = raw.split('-');
    if (parts.length != 2) return null;
    final month = int.tryParse(parts[0]);
    final day = int.tryParse(parts[1]);
    if (month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1) return null;
    // 그 달에 없는 날("02-30", "04-31")은 다음 달로 넘어가 라벨과 D-day가
    // 어긋나므로 오류로 본다. 윤년(2000)으로 검사해 2월 29일은 허용한다.
    if (DateTime(2000, month, day).month != month) return null;
    return (month, day);
  }

  /// [year]의 생일 날짜. 2월 29일생은 평년엔 2월 28일로 친다
  /// (그대로 만들면 3월 1일로 넘어간다).
  static DateTime _birthdayIn(int year, int month, int day) {
    if (month == 2 && day == 29 && DateTime(year, 2, 29).month != 2) {
      return DateTime(year, 2, 28);
    }
    return DateTime(year, month, day);
  }

  /// 오늘 포함, 가장 가까운 미래의 생일 날짜 (올해 또는 내년). 미설정/오류면 null.
  DateTime? get nextBirthday => nextBirthdayFrom(DateTime.now());

  @visibleForTesting
  DateTime? nextBirthdayFrom(DateTime now) {
    final md = _monthDay;
    if (md == null) return null;
    final today = DateTime(now.year, now.month, now.day);
    var date = _birthdayIn(now.year, md.$1, md.$2);
    if (date.isBefore(today)) {
      date = _birthdayIn(now.year + 1, md.$1, md.$2);
    }
    return date;
  }

  /// 생일까지 남은 일수 (오늘 0, 내일 1 …). 미설정/오류면 null.
  int? get daysUntilBirthday => daysUntilBirthdayFrom(DateTime.now());

  @visibleForTesting
  int? daysUntilBirthdayFrom(DateTime now) {
    final date = nextBirthdayFrom(now);
    if (date == null) return null;
    // 날짜 차이는 UTC로 센다 — 로컬 시각끼리 빼면 서머타임 경계에서 23시간이
    // 되어 inDays가 하루 모자란다.
    final from = DateTime.utc(now.year, now.month, now.day);
    final to = DateTime.utc(date.year, date.month, date.day);
    return to.difference(from).inDays;
  }

  bool get isBirthdayToday => daysUntilBirthday == 0;

  /// 표시용 라벨 (예: "3월 15일"). 미설정/오류면 null.
  String? get birthdayLabel {
    final md = _monthDay;
    if (md == null) return null;
    return '${md.$1}월 ${md.$2}일';
  }
}
