/// 짧은 날짜 라벨. 올해면 "9/11", 다른 해면 "25.9.11" — 작년 기록이 올해처럼
/// 읽히지 않게 연도를 붙인다. [now]는 테스트용 주입.
String shortDateLabel(DateTime date, {DateTime? now}) {
  final thisYear = (now ?? DateTime.now()).year;
  if (date.year == thisYear) return '${date.month}/${date.day}';
  final yy = (date.year % 100).toString().padLeft(2, '0');
  return '$yy.${date.month}.${date.day}';
}
