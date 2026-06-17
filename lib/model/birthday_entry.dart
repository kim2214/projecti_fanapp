/// 홈 "다가오는 생일" 섹션 표시용 경량 모델.
/// Member(이름/에셋)와 StreamerModel(생일)을 묶어 카드가 바로 그릴 수 있게 한다.
class BirthdayEntry {
  /// 표시 이름 (Member.name)
  final String memberName;

  /// 프로필 에셋 경로 (Member.profileAssetPath)
  final String assetPath;

  /// 생일까지 남은 일수 (0 = 오늘)
  final int daysUntil;

  /// 표시용 날짜 라벨 (예: '3월 15일')
  final String dateLabel;

  const BirthdayEntry({
    required this.memberName,
    required this.assetPath,
    required this.daysUntil,
    required this.dateLabel,
  });

  bool get isToday => daysUntil == 0;
}
