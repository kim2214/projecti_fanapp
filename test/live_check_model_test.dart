import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/model/live_check_model.dart';

void main() {
  group('LiveCheckModel.thumbnailUrl', () {
    final now = DateTime.fromMillisecondsSinceEpoch(10 * 60 * 1000 * 7 + 1);

    test('{type}을 480으로 치환하고 10분 단위 캐시 버스터를 붙인다', () {
      final m = LiveCheckModel.fromJson({
        'status': 'OPEN',
        'liveImageUrl': 'https://cdn/a/image_{type}.jpg',
      });
      expect(m.thumbnailUrl(now: now), 'https://cdn/a/image_480.jpg?t=7');
      // 같은 10분 안에서는 URL이 같아 이미지 캐시가 재사용된다.
      expect(m.thumbnailUrl(now: now.add(const Duration(minutes: 9))),
          'https://cdn/a/image_480.jpg?t=7');
      expect(m.thumbnailUrl(now: now.add(const Duration(minutes: 10))),
          'https://cdn/a/image_480.jpg?t=8');
    });

    test('템플릿이 없거나(직접 폴링) 자리표시자가 없으면 null', () {
      expect(LiveCheckModel(status: 'OPEN').thumbnailUrl(), isNull);
      expect(
        LiveCheckModel(status: 'OPEN', liveImageUrl: 'https://cdn/a.jpg')
            .thumbnailUrl(),
        isNull,
      );
    });

    test('toJson/fromJson 라운드트립에 liveImageUrl이 포함된다', () {
      final m =
          LiveCheckModel(status: 'OPEN', liveImageUrl: 'https://x/{type}');
      expect(
          LiveCheckModel.fromJson(m.toJson()).liveImageUrl, 'https://x/{type}');
    });
  });
}
