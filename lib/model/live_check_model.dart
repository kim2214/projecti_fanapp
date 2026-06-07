class LiveCheckModel {
  final String? liveTitle;
  final String? status;
  final int? concurrentUserCount;
  final String? liveCategoryValue;
  final String? openDate;

  LiveCheckModel({
    this.liveTitle,
    this.status,
    this.concurrentUserCount,
    this.liveCategoryValue,
    this.openDate,
  });

  bool get isLive => status == 'OPEN';

  factory LiveCheckModel.fromJson(Map<String, dynamic> json) {
    return LiveCheckModel(
      liveTitle: json["liveTitle"],
      status: json["status"],
      concurrentUserCount: json["concurrentUserCount"],
      liveCategoryValue: json["liveCategoryValue"],
      openDate: json["openDate"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "liveTitle": liveTitle,
      "status": status,
      "concurrentUserCount": concurrentUserCount,
      "liveCategoryValue": liveCategoryValue,
      "openDate": openDate,
    };
  }

  /// 방송 경과 시간 (예: 2시간 30분)
  String get uptime {
    if (openDate == null) return '';
    final start = DateTime.tryParse(openDate!);
    if (start == null) return '';
    final diff = DateTime.now().difference(start);
    if (diff.isNegative) return '';
    if (diff.inHours > 0) {
      return '${diff.inHours}시간 ${diff.inMinutes % 60}분';
    }
    return '${diff.inMinutes}분';
  }

  /// 시청자 수 표기 (예: 1,384명)
  String get viewerCountText {
    final count = concurrentUserCount;
    if (count == null) return '';
    final formatted = count.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$formatted명';
  }
}
