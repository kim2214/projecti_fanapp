class LiveCheckModel {
  final String? liveTitle;
  final String? status;
  final int? concurrentUserCount;
  final String? liveCategoryValue;
  final String? openDate;

  /// 방송 썸네일 URL 템플릿 (`{type}` 자리에 가로 크기). 서버 집계에서만 오며
  /// (polling 응답엔 없음) 클라 직접 폴링 폴백 시엔 null → 카드가 썸네일 없이 그려진다.
  final String? liveImageUrl;

  LiveCheckModel({
    this.liveTitle,
    this.status,
    this.concurrentUserCount,
    this.liveCategoryValue,
    this.openDate,
    this.liveImageUrl,
  });

  bool get isLive => status == 'OPEN';

  factory LiveCheckModel.fromJson(Map<String, dynamic> json) {
    return LiveCheckModel(
      liveTitle: json["liveTitle"] as String?,
      status: json["status"] as String?,
      // 치지직 JSON은 int지만 Firestore 집계 문서에서 오면 num일 수 있어 방어적으로 변환.
      concurrentUserCount: (json["concurrentUserCount"] as num?)?.toInt(),
      liveCategoryValue: json["liveCategoryValue"] as String?,
      openDate: json["openDate"] as String?,
      liveImageUrl: json["liveImageUrl"] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "liveTitle": liveTitle,
      "status": status,
      "concurrentUserCount": concurrentUserCount,
      "liveCategoryValue": liveCategoryValue,
      "openDate": openDate,
      "liveImageUrl": liveImageUrl,
    };
  }

  /// 카드용 썸네일 URL (가로 480). 템플릿이 없으면 null.
  /// 같은 세션은 URL이 고정이고 CDN 이미지만 갱신되므로, 이미지 캐시가 첫 장면에
  /// 머물지 않게 10분 단위 쿼리를 붙여 주기적으로 다시 받게 한다.
  String? thumbnailUrl({DateTime? now}) {
    final template = liveImageUrl;
    if (template == null || !template.contains('{type}')) return null;
    final bucket =
        (now ?? DateTime.now()).millisecondsSinceEpoch ~/ (10 * 60 * 1000);
    return '${template.replaceAll('{type}', '480')}?t=$bucket';
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
