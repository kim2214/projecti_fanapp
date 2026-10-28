// FavoritesController.favoritesFirst 순수 재배치 로직 단위 테스트.
// GetX 등록(onInit) 없이 생성해 favoriteIds만 주입한다 — SharedPreferences·
// FCM 토픽 동기화는 타지 않는다.

import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/controllers/favorites_controller.dart';
import 'package:projecti_fan_app/model/group.dart';

void main() {
  group('favoritesFirst (홈·통합 LIVE 최애 우선 정렬)', () {
    List<(Group, String)> arrange(
        FavoritesController c, List<(Group, String)> items) {
      return c.favoritesFirst(items, (e) => e.$1, (e) => e.$2);
    }

    test('최애를 앞으로, 각 묶음 안의 순서는 유지', () {
      final c = FavoritesController()
        ..favoriteIds.addAll(['honeyz:damyui', 'honeyz:ohwayo']);
      final result = arrange(c, const [
        (Group.honeyz, 'honeychurros'),
        (Group.honeyz, 'ohwayo'),
        (Group.honeyz, 'ayauke'),
        (Group.honeyz, 'damyui'),
      ]);
      expect(result.map((e) => e.$2),
          ['ohwayo', 'damyui', 'honeychurros', 'ayauke']);
    });

    test('같은 key라도 그룹이 다르면 최애가 아니다', () {
      final c = FavoritesController()..favoriteIds.add('acaxia:damyui');
      final result = arrange(c, const [
        (Group.honeyz, 'ayauke'),
        (Group.honeyz, 'damyui'),
      ]);
      expect(result.map((e) => e.$2), ['ayauke', 'damyui']);
    });

    test('최애가 없으면 입력 순서 그대로', () {
      final result = arrange(FavoritesController(), const [
        (Group.acaxia, 'hasiyo'),
        (Group.honeyz, 'ayauke'),
      ]);
      expect(result.map((e) => e.$2), ['hasiyo', 'ayauke']);
    });
  });
}
