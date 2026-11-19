/// 라이브(방송 시작) 알림을 받을 범위.
///
/// 앱 내부에서는 enum으로 다루고, 기기 저장값에는 [id] 문자열을 쓴다
/// (기존 저장 데이터와 호환 — 값을 바꾸지 않는다).
enum LiveNotificationMode {
  all(id: 'all', label: '전체 멤버'),
  favorites(id: 'favorites', label: '최애만'),
  off(id: 'off', label: '끄기');

  const LiveNotificationMode({required this.id, required this.label});

  /// 기기 저장용 식별자.
  final String id;

  /// 알림 설정 화면의 표시 이름.
  final String label;

  /// 저장된 [id]로 모드를 찾는다. 없거나 모르는 값이면 null.
  static LiveNotificationMode? fromId(String? id) {
    for (final mode in values) {
      if (mode.id == id) return mode;
    }
    return null;
  }
}
