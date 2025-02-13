class ScheduleModel {
  final String? scheduleURL;

  ScheduleModel({
    required this.scheduleURL,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      scheduleURL: json["schedule_image"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "schedule_image": scheduleURL,
    };
  }
}
