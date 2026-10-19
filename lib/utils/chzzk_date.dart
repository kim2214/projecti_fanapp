/// 치지직 openDate("yyyy-MM-dd HH:mm:ss")를 절대 시각으로 해석한다.
///
/// 문자열에 시간대가 없지만 값은 KST다. `DateTime.tryParse`로 그대로 읽으면
/// 기기 로컬 시간으로 해석돼 해외(비 KST) 기기에서 경과 시간·방송 길이가
/// 시차만큼 틀어진다. 반환값은 기기 로컬 시간(`toLocal`) — Firestore
/// Timestamp.toDate()와 같은 기준이라 섞어 계산해도 된다.
/// 다른 형식(시간대 포함 ISO 등)은 tryParse에 맡기고, 해석 불가면 null.
DateTime? parseChzzkOpenDate(String raw) {
  final m = _kstPattern.firstMatch(raw.trim());
  if (m == null) return DateTime.tryParse(raw)?.toLocal();
  int g(int i) => int.parse(m.group(i)!);
  // KST = UTC+9 (서머타임 없음). 시가 음수가 돼도 DateTime이 날짜를 넘겨 정규화한다.
  return DateTime.utc(g(1), g(2), g(3), g(4) - 9, g(5), g(6)).toLocal();
}

final RegExp _kstPattern =
    RegExp(r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})$');
