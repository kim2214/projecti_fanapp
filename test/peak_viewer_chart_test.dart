// 최고 동시 시청자 추이 차트의 순수 판정(점 선별·평균)과 렌더링 라벨 검증.
// Firestore 없이 LiveSessionModel.fromJson에 값을 주입한다 (기존 테스트 관례).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/model/live_session_model.dart';
import 'package:projecti_fan_app/widget/components/peak_viewer_chart.dart';

LiveSessionModel _session(int day, int? peak) => LiveSessionModel.fromJson({
      'liveTitle': '방송 $day',
      'startedAt': Timestamp.fromDate(DateTime(2026, 9, day, 20)),
      'endedAt': Timestamp.fromDate(DateTime(2026, 9, day, 23)),
      if (peak != null) 'peakConcurrentUserCount': peak,
    });

void main() {
  group('PeakViewerChart.pointsOf', () {
    test('시청자 수 없는 세션은 제외하고 오래된 → 최신 순으로 뒤집는다', () {
      final latestFirst = [
        _session(10, 300),
        _session(9, null),
        _session(8, 100)
      ];
      final points = PeakViewerChart.pointsOf(latestFirst);
      expect(points.map((s) => s.peakConcurrentUserCount), [100, 300]);
    });

    test('최대 개수를 넘는 오래된 세션은 버린다', () {
      final latestFirst = [for (int d = 12; d >= 1; d--) _session(d, d)];
      final points = PeakViewerChart.pointsOf(latestFirst, max: 10);
      expect(points.length, 10);
      expect(points.first.peakConcurrentUserCount, 3); // 1·2일은 잘림
      expect(points.last.peakConcurrentUserCount, 12);
    });
  });

  test('averageLabel은 천 단위 콤마, 빈 목록은 빈 문자열', () {
    expect(PeakViewerChart.averageLabel([]), '');
    expect(
      PeakViewerChart.averageLabel([_session(1, 1000), _session(2, 1500)]),
      '평균 1,250명',
    );
  });

  testWidgets('점이 2개 이상이면 헤더·최고값·양끝 날짜만 그린다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PeakViewerChart(
          sessions: [_session(10, 2000), _session(9, 1384), _session(8, 500)],
          color: Colors.pink,
          colorDark: Colors.red,
        ),
      ),
    ));

    expect(find.text('최고 동시 시청자 · 최근 3회'), findsOneWidget);
    expect(find.text('평균 1,294명'), findsOneWidget);
    expect(find.text('2,000'), findsOneWidget); // 최고점 직접 라벨
    expect(find.text('1,384'), findsNothing); // 나머지 막대엔 숫자 없음
    expect(find.text('9/8'), findsOneWidget);
    expect(find.text('9/10'), findsOneWidget);
    expect(find.text('9/9'), findsNothing);
  });

  testWidgets('점이 하나면 아무것도 그리지 않는다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PeakViewerChart(
        sessions: [_session(10, 2000), _session(9, null)],
        color: Colors.pink,
        colorDark: Colors.red,
      ),
    ));
    expect(find.byType(Text), findsNothing);
  });
}
