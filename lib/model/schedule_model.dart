class ScheduleModel {
  final String? scheduleURL;

  ScheduleModel({
    required this.scheduleURL,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      // 콘솔에서 잘못된 타입을 넣어도 로드 전체가 실패하지 않게 문자열만 받는다.
      scheduleURL: json["schedule_image"] is String
          ? json["schedule_image"] as String
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "schedule_image": scheduleURL,
    };
  }
}
