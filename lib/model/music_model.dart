class MusicModel {
  final String? name;
  final String? title;
  final String? musicURL;
  final String? thumbnail;

  MusicModel({
    this.name,
    this.title,
    required this.musicURL,
    this.thumbnail,
  });

  factory MusicModel.fromJson(Map<String, dynamic> json) {
    return MusicModel(
        name: json["name"],
        title: json["title"],
        musicURL: json["music_url"],
        thumbnail: json["thumbnail"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "title": title,
      "musicURL": musicURL,
      "thumbnail": thumbnail,
    };
  }
}
