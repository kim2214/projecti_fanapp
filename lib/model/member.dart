/// 멤버의 정적 메타데이터를 한데 묶은 카탈로그 모델.
/// (이름/에셋/치지직 방송ID/유튜브 채널ID 등 — 여러 병렬 List를 대체)
///
/// Firestore에서 불러오는 동적 데이터(프로필/SNS URL)는 [StreamerModel]이 담당하며,
/// Member는 키/순서를 정의하는 단일 소스(catalog) 역할을 한다.
class Member {
  /// 문서 ID 겸 에셋 이름 (예: 'ohwayo')
  final String key;

  /// 표시 이름 (예: '오화요')
  final String name;

  /// 소속 그룹 ('honeyz' | 'acaxia')
  final String group;

  /// 치지직 라이브 상태 폴링용 방송 ID
  final String chzzkBroadcastId;

  /// YouTube 채널 ID
  final String youtubeChannelId;

  const Member({
    required this.key,
    required this.name,
    required this.group,
    required this.chzzkBroadcastId,
    required this.youtubeChannelId,
  });

  /// 에셋 이름 (현재는 key와 동일)
  String get assetName => key;

  /// 프로필 이미지 에셋 경로 (예: 'assets/honeyz/ohwayo_profile.png')
  String get profileAssetPath => 'assets/$group/${key}_profile.png';

  bool get isHoneyz => group == 'honeyz';

  /// 치지직 라이브 시청 페이지 URL을 broadcastId로 만든다.
  /// (앱 여러 곳·알림 payload에서 broadcastId만 들고 있어 static으로 제공 —
  ///  URL 형식이 바뀌면 이 한 곳만 고친다.)
  static String liveUrlOf(String broadcastId) =>
      'https://chzzk.naver.com/live/$broadcastId';

  /// 이 멤버의 치지직 라이브 시청 URL
  String get liveUrl => liveUrlOf(chzzkBroadcastId);
}
