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
