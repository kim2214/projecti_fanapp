// GlobalController의 순수 파생 로직(필터/정렬/인덱스 페어링) 단위 테스트.
// Firebase/네트워크 없이 RxList에 값을 주입하고 getter 결과만 검증한다.
// (_fireStore는 late final이라 Firestore 호출 전까지 초기화되지 않으므로,
//  컨트롤러를 Firebase 초기화 없이 생성할 수 있다.)

import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/model/live_check_model.dart';
import 'package:projecti_fan_app/model/streamer_model.dart';

LiveCheckModel _live({String status = 'CLOSE', int? viewers}) =>
    LiveCheckModel(status: status, concurrentUserCount: viewers);

StreamerModel _streamer({String? birthday}) => StreamerModel(
      name: null,
      profileName: null,
      youtube: null,
      chzzk: null,
      twitter: null,
      birthday: birthday,
    );

void main() {
  // honeyzMembers: [허니츄러스, 아야, 담유이, 디디디용, 오화요, 망내] (6명)
  // acaxiaMembers: [포포포포, 비올레타 모네, 블레어 로즈, 하시요, 류시호] (5명)

  group('liveMembersAcrossGroups', () {
    test('isLive(OPEN)인 멤버만 포함하고 시청자 수 내림차순 정렬', () {
      final c = GlobalController();
      c.honeyzliveCheckList.value = [
        _live(status: 'OPEN', viewers: 100), // 허니츄러스
        _live(status: 'CLOSE'), // 아야
        _live(status: 'OPEN', viewers: 500), // 담유이
        _live(status: 'CLOSE'), // 디디디용
        _live(status: 'CLOSE'), // 오화요
        _live(status: 'CLOSE'), // 망내
      ];
      c.acaxialiveCheckList.value = [
        _live(status: 'OPEN', viewers: 300), // 포포포포
        _live(status: 'CLOSE'),
        _live(status: 'CLOSE'),
        _live(status: 'CLOSE'),
        _live(status: 'CLOSE'),
      ];

      final result = c.liveMembersAcrossGroups;

      expect(result.map((e) => e.memberName).toList(),
          ['담유이', '포포포포', '허니츄러스']);
      expect(result.first.group, 'honeyz');
      expect(result[1].group, 'acaxia');
    });

    test('폴링 전(빈 상태 리스트)이면 빈 목록 — 크래시 없음', () {
      final c = GlobalController();
      expect(c.liveMembersAcrossGroups, isEmpty);
    });

    test('상태 리스트가 멤버보다 짧아도 최소 길이까지만 안전하게 순회', () {
      final c = GlobalController();
      // 6명 중 앞 2개만 제공
      c.honeyzliveCheckList.value = [
        _live(status: 'OPEN', viewers: 10), // 허니츄러스
        _live(status: 'OPEN', viewers: 20), // 아야
      ];

      final result = c.liveMembersAcrossGroups;
      expect(result.map((e) => e.memberName).toList(), ['아야', '허니츄러스']);
    });

    test('concurrentUserCount가 null이면 0으로 취급되어 뒤로 정렬', () {
      final c = GlobalController();
      c.honeyzliveCheckList.value = [
        _live(status: 'OPEN', viewers: null), // 허니츄러스
        _live(status: 'OPEN', viewers: 50), // 아야
        _live(status: 'CLOSE'),
        _live(status: 'CLOSE'),
        _live(status: 'CLOSE'),
        _live(status: 'CLOSE'),
      ];

      final result = c.liveMembersAcrossGroups;
      expect(result.map((e) => e.memberName).toList(), ['아야', '허니츄러스']);
    });
  });

  group('upcomingBirthdays', () {
    test('생일 미설정 멤버는 제외하고, 설정된 멤버만 반환', () {
      final c = GlobalController();
      // honeyzMembers(6명)과 인덱스 정렬: 오화요(index 4)만 생일 설정
      c.honeyz.value = [
        _streamer(),
        _streamer(),
        _streamer(),
        _streamer(),
        _streamer(birthday: '06-15'), // 오화요
        _streamer(),
      ];

      final result = c.upcomingBirthdays('honeyz');
      expect(result.length, 1);
      expect(result.first.memberName, '오화요');
      expect(result.first.assetPath, 'assets/honeyz/ohwayo_profile.png');
      expect(result.first.dateLabel, '6월 15일');
    });

    test('남은 일수 오름차순으로 정렬된다', () {
      final c = GlobalController();
      c.honeyz.value = [
        _streamer(birthday: '01-01'),
        _streamer(birthday: '12-31'),
        _streamer(birthday: '06-15'),
        _streamer(),
        _streamer(),
        _streamer(),
      ];

      final result = c.upcomingBirthdays('honeyz');
      // 정확한 일수는 오늘 날짜에 따라 다르지만, 정렬 순서는 항상 비내림차순이어야 한다.
      for (var i = 0; i + 1 < result.length; i++) {
        expect(result[i].daysUntil <= result[i + 1].daysUntil, isTrue);
      }
    });

    test('스트리머 데이터가 없으면 빈 목록', () {
      final c = GlobalController();
      expect(c.upcomingBirthdays('honeyz'), isEmpty);
    });
  });
}
