class MusicModel {
  final String? name;
  final String? title;
  final String? musicURL;
  final String? thumbnail;
  final String? group;

  MusicModel(
      {this.name,
      this.title,
      required this.musicURL,
      this.thumbnail,
      this.group});

  factory MusicModel.fromJson(Map<String, dynamic> json) {
    return MusicModel(
        name: json["name"],
        title: json["title"],
        musicURL: json["music_url"],
        thumbnail: json["thumbnail"],
        group: json["group"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "title": title,
      "music_url": musicURL,
      "thumbnail": thumbnail,
      "group": group,
    };
  }

  // 동등성 비교를 위한 override (musicURL 기준으로 동일 여부 판단)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MusicModel && other.musicURL == musicURL;
  }

  @override
  int get hashCode => musicURL.hashCode;
}
