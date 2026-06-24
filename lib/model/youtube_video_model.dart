class YouTubeVideoModel {
  final String? videoId;
  final String? title;
  final String? description;
  final String? thumbnailUrl;
  final String? channelTitle;
  final DateTime? publishedAt;

  YouTubeVideoModel({
    this.videoId,
    this.title,
    this.description,
    this.thumbnailUrl,
    this.channelTitle,
    this.publishedAt,
  });

  /// 로컬 캐시 영속화용 직렬화 (shared_preferences)
  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'title': title,
        'description': description,
        'thumbnailUrl': thumbnailUrl,
        'channelTitle': channelTitle,
        'publishedAt': publishedAt?.toIso8601String(),
      };

  factory YouTubeVideoModel.fromJson(Map<String, dynamic> json) =>
      YouTubeVideoModel(
        videoId: json['videoId'] as String?,
        title: json['title'] as String?,
        description: json['description'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        channelTitle: json['channelTitle'] as String?,
        publishedAt: json['publishedAt'] != null
            ? DateTime.tryParse(json['publishedAt'] as String)
            : null,
      );

  /// YouTube 앱/웹 URL 생성
  String get youtubeUrl => 'https://www.youtube.com/watch?v=$videoId';

  /// 포맷된 날짜 (YYYY.MM.DD)
  String get formattedDate {
    if (publishedAt == null) return '';
    return '${publishedAt!.year}.${publishedAt!.month.toString().padLeft(2, '0')}.${publishedAt!.day.toString().padLeft(2, '0')}';
  }

  /// 상대적 시간 표시 (예: 3일 전, 2주 전)
  String get relativeTime {
    if (publishedAt == null) return '';
    final now = DateTime.now();
    final difference = now.difference(publishedAt!);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}년 전';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}개월 전';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}주 전';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else {
      return '방금 전';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is YouTubeVideoModel && other.videoId == videoId;
  }

  @override
  int get hashCode => videoId.hashCode;
}
