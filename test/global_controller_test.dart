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
      // 맵에 없는 멤버 = 비방송. OPEN인 멤버만 넣는다.
      c.honeyzLiveStatus.value = {
        'honeychurros': _live(status: 'OPEN', viewers: 100),
        'damyui': _live(status: 'OPEN', viewers: 500),
      };
      c.acaxiaLiveStatus.value = {
        'popopopo': _live(status: 'OPEN', viewers: 300),
      };

      final result = c.liveMembersAcrossGroups;

      expect(result.map((e) => e.memberName).toList(),
          ['담유이', '포포포포', '허니츄러스']);
      expect(result.first.group, 'honeyz');
      expect(result[1].group, 'acaxia');
    });

    test('폴링 전(빈 맵)이면 빈 목록 — 크래시 없음', () {
      final c = GlobalController();
      expect(c.liveMembersAcrossGroups, isEmpty);
    });

    test('일부 멤버만 상태가 있어도 key로 안전하게 매칭', () {
      final c = GlobalController();
      c.honeyzLiveStatus.value = {
        'honeychurros': _live(status: 'OPEN', viewers: 10),
        'ayauke': _live(status: 'OPEN', viewers: 20),
      };

      final result = c.liveMembersAcrossGroups;
      expect(result.map((e) => e.memberName).toList(), ['아야', '허니츄러스']);
    });

    test('CLOSE 상태가 섞여 있어도 OPEN만 포함', () {
      final c = GlobalController();
      c.honeyzLiveStatus.value = {
        'honeychurros': _live(status: 'CLOSE'),
        'ayauke': _live(status: 'OPEN', viewers: 50),
      };

      final result = c.liveMembersAcrossGroups;
      expect(result.map((e) => e.memberName).toList(), ['아야']);
    });

    test('concurrentUserCount가 null이면 0으로 취급되어 뒤로 정렬', () {
      final c = GlobalController();
      c.honeyzLiveStatus.value = {
        'honeychurros': _live(status: 'OPEN', viewers: null),
        'ayauke': _live(status: 'OPEN', viewers: 50),
      };

      final result = c.liveMembersAcrossGroups;
      expect(result.map((e) => e.memberName).toList(), ['아야', '허니츄러스']);
    });
  });

  group('liveStatusFromAggregate', () {
    test('key로 매칭해 상태를 파싱하고, 문서에 없는 멤버는 맵에서 제외', () {
      final c = GlobalController();
      // honeyz 6명 중 담유이만 방송 중
      final members = <String, dynamic>{
        'damyui': {
          'status': 'OPEN',
          'liveTitle': '방송 제목',
          'concurrentUserCount': 1234,
          'liveCategoryValue': 'Just Chatting',
          'openDate': '2026-07-18 20:00:00',
        },
      };

      final result = c.liveStatusFromAggregate('honeyz', members);

      // 문서에 있는 멤버만 맵에 들어간다 (없음 = 소비 측에서 비방송 처리)
      expect(result.length, 1);
      expect(result['damyui']!.isLive, isTrue);
      expect(result['damyui']!.liveTitle, '방송 제목');
      expect(result['damyui']!.concurrentUserCount, 1234);
      expect(result['damyui']!.liveCategoryValue, 'Just Chatting');
      expect(result['honeychurros'], isNull);
    });

    test('concurrentUserCount가 num(double)로 와도 int로 변환된다', () {
      final c = GlobalController();
      final members = <String, dynamic>{
        'ayauke': {'status': 'OPEN', 'concurrentUserCount': 500.0},
      };

      final result = c.liveStatusFromAggregate('honeyz', members);
      expect(result['ayauke']!.concurrentUserCount, 500);
    });

    test('빈 맵이면 빈 결과', () {
      final c = GlobalController();
      final result = c.liveStatusFromAggregate('acaxia', const {});
      expect(result, isEmpty);
    });

    test('다른 그룹의 멤버 key는 무시된다', () {
      final c = GlobalController();
      // honeyz 그룹 변환에 acaxia 멤버(popopopo)를 넣어도 결과에 없어야 한다.
      final members = <String, dynamic>{
        'popopopo': {'status': 'OPEN'},
      };
      final result = c.liveStatusFromAggregate('honeyz', members);
      expect(result, isEmpty);
    });
  });

  group('upcomingBirthdays', () {
    test('생일 미설정 멤버는 제외하고, 설정된 멤버만 반환', () {
      final c = GlobalController();
      // key로 매칭: 오화요만 생일 설정
      c.honeyz.value = {
        'ohwayo': _streamer(birthday: '06-15'),
      };

      final result = c.upcomingBirthdays('honeyz');
      expect(result.length, 1);
      expect(result.first.memberName, '오화요');
      expect(result.first.assetPath, 'assets/honeyz/ohwayo_profile.png');
      expect(result.first.dateLabel, '6월 15일');
    });

    test('남은 일수 오름차순으로 정렬된다', () {
      final c = GlobalController();
      c.honeyz.value = {
        'honeychurros': _streamer(birthday: '01-01'),
        'ayauke': _streamer(birthday: '12-31'),
        'damyui': _streamer(birthday: '06-15'),
      };

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
