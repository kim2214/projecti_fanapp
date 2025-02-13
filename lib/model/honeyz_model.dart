class HoneyzModel {
  final String? name;
  final String? profileName;
  final String? youtube;
  final String? chzzk;
  final String? twitter;

  HoneyzModel(
      {required this.name,
      required this.profileName,
      required this.youtube,
      required this.chzzk,
      required this.twitter});

  factory HoneyzModel.fromJson(Map<String, dynamic> json) {
    return HoneyzModel(
      name: json["name"],
      profileName: json["profile_name"],
      youtube: json["youtube"],
      chzzk: json["chzzk"],
      twitter: json["twitter"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "profileName": profileName,
      "youtube": youtube,
      "chzzk": chzzk,
      "twitter": twitter,
    };
  }
}
