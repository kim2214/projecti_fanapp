import 'package:cloud_firestore/cloud_firestore.dart';

/// 서버(pollLiveStatus)가 방송 종료 시 기록하는 지난 방송 세션.
/// `live_history/{memberKey}/sessions/{id}` 문서에 매핑된다.
class LiveSessionModel {
  final String? liveTitle;
  final String? liveCategoryValue;

  /// 방송 시작 시각 — chzzk openDate("yyyy-MM-dd HH:mm:ss", KST)를 기기
  /// 로컬 시간으로 해석한다 (주 사용자가 KST라는 전제).
  final DateTime? startedAt;

  /// 방송 종료 시각 — 서버 폴링이 감지한 시각(실제보다 최대 1~3분 늦은 근사값).
  final DateTime? endedAt;

  /// 방송 중 최고 동시 시청자 수.
  final int? peakConcurrentUserCount;

  LiveSessionModel({
    this.liveTitle,
    this.liveCategoryValue,
    this.startedAt,
    this.endedAt,
    this.peakConcurrentUserCount,
  });

  factory LiveSessionModel.fromJson(Map<String, dynamic> json) {
    final openDate = json['openDate'];
    final endedAt = json['endedAt'];
    return LiveSessionModel(
      liveTitle: json['liveTitle'] as String?,
      liveCategoryValue: json['liveCategoryValue'] as String?,
      startedAt: openDate is String ? DateTime.tryParse(openDate) : null,
      endedAt: endedAt is Timestamp ? endedAt.toDate() : null,
      peakConcurrentUserCount: (json['peakConcurrentUserCount'] as num?)?.toInt(),
    );
  }

  /// 방송 길이. 시각이 없거나 음수(시계 불일치)면 null.
  Duration? get duration {
    if (startedAt == null || endedAt == null) return null;
    final d = endedAt!.difference(startedAt!);
    return d.isNegative ? null : d;
  }

  /// "3시간 12분" / "45분". 계산 불가면 빈 문자열.
  String get durationLabel {
    final d = duration;
    if (d == null) return '';
    if (d.inHours > 0) return '${d.inHours}시간 ${d.inMinutes % 60}분';
    return '${d.inMinutes}분';
  }

  /// "8/23". 시작 시각이 없으면 빈 문자열.
  String get dateLabel =>
      startedAt == null ? '' : '${startedAt!.month}/${startedAt!.day}';

  /// "최고 1,384명". 기록이 없으면 빈 문자열.
  String get peakViewerText {
    final count = peakConcurrentUserCount;
    if (count == null) return '';
    final formatted = count.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '최고 $formatted명';
  }
}
