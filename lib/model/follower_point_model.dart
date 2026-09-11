/// 서버(recordFollowerCounts)가 매일 기록하는 치지직 팔로워 수 한 점.
/// `follower_history/{memberKey}/daily/{yyyyMMdd}` 문서에 매핑된다.
class FollowerPointModel {
  /// 기록일 (KST 날짜, 문서 ID "yyyyMMdd"에서 파생).
  final DateTime date;
  final int followerCount;

  const FollowerPointModel({required this.date, required this.followerCount});

  /// 문서 ID와 필드에서 만든다. 형식이 맞지 않으면 null (그 점만 건너뛴다).
  static FollowerPointModel? fromDoc(String id, Map<String, dynamic> json) {
    if (id.length != 8) return null;
    final y = int.tryParse(id.substring(0, 4));
    final m = int.tryParse(id.substring(4, 6));
    final d = int.tryParse(id.substring(6, 8));
    final count = json['followerCount'];
    if (y == null || m == null || d == null || count is! num) return null;
    return FollowerPointModel(
      date: DateTime(y, m, d),
      followerCount: count.toInt(),
    );
  }

  /// "9/11"
  String get dateLabel => '${date.month}/${date.day}';
}
