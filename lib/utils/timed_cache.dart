/// 키별 값에 유효 시간(TTL)을 붙인 단순 메모리 캐시.
///
/// 멤버 프로필의 보조 데이터(지난 방송·팔로워 기록)처럼 "열 때마다 Firestore를
/// 수십 건 읽지만 값은 몇 분 안에 바뀌지 않는" 조회에 쓴다. 실패는 저장하지
/// 않으므로(호출자가 예외를 그대로 던짐) 다음 조회에서 재시도된다.
class TimedCache<T> {
  final Duration ttl;
  final Map<String, ({T value, DateTime fetchedAt})> _entries = {};

  TimedCache(this.ttl);

  /// TTL 안의 값. 없거나 만료됐으면 null. ([now]는 테스트용 주입)
  T? get(String key, {DateTime? now}) {
    final hit = _entries[key];
    if (hit == null) return null;
    final age = (now ?? DateTime.now()).difference(hit.fetchedAt);
    return age < ttl ? hit.value : null;
  }

  void put(String key, T value, {DateTime? now}) {
    _entries[key] = (value: value, fetchedAt: now ?? DateTime.now());
  }

  /// 캐시에 있으면 그대로, 없으면 [fetch] 결과를 저장하고 돌려준다.
  Future<T> getOrFetch(String key, Future<T> Function() fetch) async {
    final hit = get(key);
    if (hit != null) return hit;
    final value = await fetch();
    put(key, value);
    return value;
  }
}
