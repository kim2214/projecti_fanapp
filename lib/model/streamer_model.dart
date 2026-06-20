class StreamerModel {
  final String? name;
  final String? profileName;
  final String? youtube;
  final String? chzzk;
  final String? twitter;

  /// 생일 (Firestore "birthday" 필드, "MM-DD" 형식. 연도는 무시하고 매년 반복)
  final String? birthday;

  StreamerModel(
      {required this.name,
      required this.profileName,
      required this.youtube,
      required this.chzzk,
      required this.twitter,
      this.birthday});

  /// Firestore 문서가 없는 멤버용 빈 모델.
  /// 멤버 카탈로그와 1:1 인덱스 정렬을 유지하기 위한 플레이스홀더로 쓰인다.
  factory StreamerModel.empty() => StreamerModel(
        name: null,
        profileName: null,
        youtube: null,
        chzzk: null,
        twitter: null,
      );

  factory StreamerModel.fromJson(Map<String, dynamic> json) {
    return StreamerModel(
      name: json["name"],
      profileName: json["profile_name"],
      youtube: json["youtube"],
      chzzk: json["chzzk"],
      twitter: json["twitter"],
      birthday: json["birthday"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "profileName": profileName,
      "youtube": youtube,
      "chzzk": chzzk,
      "twitter": twitter,
      "birthday": birthday,
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
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return (month, day);
  }

  /// 오늘 포함, 가장 가까운 미래의 생일 날짜 (올해 또는 내년). 미설정/오류면 null.
  DateTime? get nextBirthday {
    final md = _monthDay;
    if (md == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var date = DateTime(now.year, md.$1, md.$2);
    if (date.isBefore(today)) {
      date = DateTime(now.year + 1, md.$1, md.$2);
    }
    return date;
  }

  /// 생일까지 남은 일수 (오늘 0, 내일 1 …). 미설정/오류면 null.
  int? get daysUntilBirthday {
    final date = nextBirthday;
    if (date == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.difference(today).inDays;
  }

  bool get isBirthdayToday => daysUntilBirthday == 0;

  /// 표시용 라벨 (예: "3월 15일"). 미설정/오류면 null.
  String? get birthdayLabel {
    final md = _monthDay;
    if (md == null) return null;
    return '${md.$1}월 ${md.$2}일';
  }
}
