// LiveWidgetService의 순수 로직 단위 테스트.
// - buildPayload: 네이티브(LiveStatusWidgetProvider.kt)가 읽는 JSON 형식의 계약
// - statusFromAggregate: 오래된 서버 집계를 위젯에 그리지 않는 stale 판정
//   (네이티브는 stale일 때 목록도 "모두 휴식 중"도 아닌 "확인 불가"를 그린다)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/model/live_check_model.dart';
import 'package:projecti_fan_app/services/live_widget_service.dart';

void main() {
  final members = [
    ...GlobalController.honeyzMembers,
    ...GlobalController.acaxiaMembers,
  ];
  final now = DateTime(2026, 8, 28, 21, 0);

  group('LiveWidgetService.buildPayload', () {
    test('방송 중인 멤버만, 시청자 수 내림차순, 네이티브가 읽는 필드 포함', () {
      final payload = LiveWidgetService.buildPayload(
          members,
          {
            'damyui': LiveCheckModel(
                status: 'OPEN', liveTitle: '저챗', concurrentUserCount: 500),
            'popopopo': LiveCheckModel(
                status: 'OPEN', liveTitle: '게임', concurrentUserCount: 900),
            'ayauke': LiveCheckModel(status: 'CLOSE'),
          },
          now);

      expect(payload['updatedAt'], now.millisecondsSinceEpoch);
      expect(payload['stale'], isFalse);
      final live = payload['live'] as List;
      expect(live.map((e) => e['name']).toList(), ['포포포포', '담유이']);
      expect(live.first['group'], 'acaxia');
      expect(live.first['title'], '게임');
      expect(live.first['viewers'], 900);
      expect(live.first['url'],
          'https://chzzk.naver.com/live/3e3781d3bd20dadc2f6f6d5d30091195');
    });

    test('시청자 수·제목이 null이어도 0·빈 문자열로 안전 처리', () {
      final payload = LiveWidgetService.buildPayload(
          members,
          {
            'ohwayo': LiveCheckModel(status: 'OPEN'),
          },
          now);
      final live = payload['live'] as List;
      expect(live.single['viewers'], 0);
      expect(live.single['title'], '');
    });

    test('방송 중인 멤버가 없으면 빈 목록 — 위젯은 휴식 중 문구를 그린다', () {
      final payload = LiveWidgetService.buildPayload(members, const {}, now);
      expect(payload['live'], isEmpty);
      expect(payload['stale'], isFalse);
    });

    test('stale이면 플래그를 실어 보낸다 — 네이티브가 "확인 불가"를 그린다', () {
      // 빈 목록만으로는 "모두 휴식 중"과 구분되지 않으므로 플래그가 필요하다.
      final payload =
          LiveWidgetService.buildPayload(members, const {}, now, stale: true);
      expect(payload['stale'], isTrue);
      expect(payload['live'], isEmpty);
    });
  });

  group('LiveWidgetService.statusFromAggregate (위젯 stale 판정)', () {
    Map<String, dynamic> aggregate(DateTime updatedAt) => {
          'updatedAt': Timestamp.fromDate(updatedAt),
          'members': {
            'damyui': {'status': 'OPEN', 'liveTitle': '저챗'},
          },
        };

    test('신선한 집계는 그대로 파싱하고 stale=false', () {
      final result = LiveWidgetService.statusFromAggregate(
          aggregate(now.subtract(const Duration(minutes: 1))), now);
      expect(result.stale, isFalse);
      expect(result.status['damyui']!.isLive, isTrue);
      expect(result.status['damyui']!.liveTitle, '저챗');
    });

    test('오래된 집계는 stale=true + 빈 맵 — 얼어붙은 방송 중을 그리지 않는다', () {
      // 위젯에는 치지직 직접 폴링 폴백이 없어, 여기서 걸러내지 않으면
      // 마지막으로 방송 중이던 목록이 영구히 남는다.
      final result = LiveWidgetService.statusFromAggregate(
          aggregate(now.subtract(const Duration(minutes: 30))), now);
      expect(result.stale, isTrue);
      expect(result.status, isEmpty);
    });

    test('문서가 없으면 stale=true — "모두 휴식 중"이라고 단정하지 않는다', () {
      final result = LiveWidgetService.statusFromAggregate(null, now);
      expect(result.stale, isTrue);
      expect(result.status, isEmpty);
    });
  });
}
