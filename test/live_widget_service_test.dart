// LiveWidgetService.buildPayload(홈스크린 위젯 페이로드) 단위 테스트.
// 네이티브(LiveStatusWidgetProvider.kt)가 읽는 JSON 형식의 계약을 고정한다.

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
    });
  });
}
