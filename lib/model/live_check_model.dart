class LiveCheckModel {
  final String? liveTitle;
  final String? status;

  LiveCheckModel({
    this.liveTitle,
    this.status,
  });

  factory LiveCheckModel.fromJson(Map<String, dynamic> json) {
    return LiveCheckModel(
      liveTitle: json["liveTitle"],
      status: json["status"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "liveTitle": liveTitle,
      "status": status,
    };
  }
}
