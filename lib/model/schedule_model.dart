import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleModel {
  final String? scheduleURL;

  /// 스케줄 이미지가 등록된(바뀐) 시각. 서버(onScheduleWrite)가 이미지 변경 때
  /// `schedule_updated_at`으로 남긴다 — 그 전에 등록된 문서에는 없다.
  final DateTime? updatedAt;

  ScheduleModel({
    required this.scheduleURL,
    this.updatedAt,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    final updatedAt = json["schedule_updated_at"];
    return ScheduleModel(
      // 콘솔에서 잘못된 타입을 넣어도 로드 전체가 실패하지 않게 문자열만 받는다.
      scheduleURL: json["schedule_image"] is String
          ? json["schedule_image"] as String
          : null,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "schedule_image": scheduleURL,
    };
  }
}
