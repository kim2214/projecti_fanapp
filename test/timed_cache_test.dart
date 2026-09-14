import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/utils/timed_cache.dart';

void main() {
  final t0 = DateTime(2026, 9, 14, 12);

  test('TTL 안이면 값을 돌려주고, 지나면 null', () {
    final cache = TimedCache<int>(const Duration(minutes: 10));
    cache.put('a', 1, now: t0);
    expect(cache.get('a', now: t0.add(const Duration(minutes: 9))), 1);
    expect(cache.get('a', now: t0.add(const Duration(minutes: 10))), isNull);
    expect(cache.get('b', now: t0), isNull);
  });

  test('getOrFetch는 캐시 적중 시 fetch를 부르지 않고, 실패는 저장하지 않는다', () async {
    final cache = TimedCache<int>(const Duration(minutes: 10));
    var calls = 0;
    Future<int> fetch() async => ++calls;

    expect(await cache.getOrFetch('a', fetch), 1);
    expect(await cache.getOrFetch('a', fetch), 1); // 적중
    expect(calls, 1);

    await expectLater(
      cache.getOrFetch('b', () async => throw StateError('네트워크')),
      throwsStateError,
    );
    expect(cache.get('b'), isNull); // 실패는 남지 않아 다음에 재시도
  });
}
