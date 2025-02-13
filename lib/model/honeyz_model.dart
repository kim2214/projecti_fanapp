class HoneyzModel {
  final String? youtube;

  HoneyzModel({required this.youtube});

  factory HoneyzModel.fromJson(Map<String, dynamic> json) {
    return HoneyzModel(
      youtube: json["youtube"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "youtube": youtube,
    };
  }
}
