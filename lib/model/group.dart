/// 소속 그룹. 그룹별로 달라지는 값(이름·로고·컬렉션)을 한곳에 둔다.
///
/// 앱 내부에서는 enum으로 다루고, 기기 저장값·Firestore 컬렉션·라우트 쿼리·
/// FCM 토픽·최애 ID('group:key') 등 밖으로 나가는 값에는 [id] 문자열을 쓴다
/// (기존 저장 데이터와 호환). 그룹을 추가하면 `switch`를 쓰는 곳(멤버 카탈로그·
/// 캐시 선택·색)이 컴파일 오류로 드러난다 — 나머지 동기화 지점은 add-member skill.
enum Group {
  honeyz(
    id: 'honeyz',
    label: '허니즈',
    labelEn: 'HONEYZ',
    scheduleCollection: 'schedule',
  ),
  acaxia(
    id: 'acaxia',
    label: '아카시아',
    labelEn: 'ACAXIA',
    scheduleCollection: 'schedule_acaxia',
  );

  const Group({
    required this.id,
    required this.label,
    required this.labelEn,
    required this.scheduleCollection,
  });

  /// 저장·통신용 식별자. 멤버 프로필 컬렉션 이름과 에셋 폴더 이름이기도 하다.
  final String id;

  /// 표시 이름 (예: '허니즈')
  final String label;

  /// 영문 표시 이름 (예: 'HONEYZ')
  final String labelEn;

  /// 스케줄 Firestore 컬렉션 이름
  final String scheduleCollection;

  /// 멤버 프로필 Firestore 컬렉션 이름 (그룹 id와 동일)
  String get streamerCollection => id;

  /// 그룹 로고 에셋 경로
  String get logoAsset => 'assets/${id}_logo.png';

  /// [id] 문자열로 그룹을 찾는다. 없거나 모르는 값이면 null.
  static Group? fromId(String? id) {
    for (final group in values) {
      if (group.id == id) return group;
    }
    return null;
  }
}
