// Group enum의 저장·통신용 값 계약 테스트. id·컬렉션 이름은 기기 저장값
// (선택 그룹·최애·알림 설정·영상 캐시)과 Firestore·FCM 토픽에 쓰이므로
// 바뀌면 기존 사용자 데이터가 조용히 깨진다.

import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/model/group.dart';

void main() {
  group('Group', () {
    test('id·컬렉션 이름은 기존 저장 데이터·Firestore와 같은 값', () {
      expect(Group.honeyz.id, 'honeyz');
      expect(Group.acaxia.id, 'acaxia');
      expect(Group.honeyz.streamerCollection, 'honeyz');
      expect(Group.acaxia.streamerCollection, 'acaxia');
      expect(Group.honeyz.scheduleCollection, 'schedule');
      expect(Group.acaxia.scheduleCollection, 'schedule_acaxia');
    });

    test('fromId는 id로 찾고, 모르는 값·null이면 null', () {
      expect(Group.fromId('honeyz'), Group.honeyz);
      expect(Group.fromId('acaxia'), Group.acaxia);
      expect(Group.fromId('oldgroup'), isNull);
      expect(Group.fromId(''), isNull);
      expect(Group.fromId(null), isNull);
    });

    test('로고 에셋 경로', () {
      expect(Group.honeyz.logoAsset, 'assets/honeyz_logo.png');
      expect(Group.acaxia.logoAsset, 'assets/acaxia_logo.png');
    });
  });
}
