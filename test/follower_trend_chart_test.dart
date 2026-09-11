// 팔로워 추이 차트의 순수 판정(정렬·증감 라벨)과 모델 파싱, 렌더링 라벨 검증.
// Firestore 없이 문서 ID·필드를 직접 주입한다 (기존 테스트 관례).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/model/follower_point_model.dart';
import 'package:projecti_fan_app/widget/components/follower_trend_chart.dart';

FollowerPointModel _p(int day, int count) =>
    FollowerPointModel(date: DateTime(2026, 9, day), followerCount: count);

void main() {
  group('FollowerPointModel.fromDoc', () {
    test('yyyyMMdd 문서 ID와 followerCount를 파싱한다', () {
      final p =
          FollowerPointModel.fromDoc('20260911', {'followerCount': 137187});
      expect(p?.date, DateTime(2026, 9, 11));
      expect(p?.followerCount, 137187);
      expect(p?.dateLabel, '9/11');
    });

    test('ID 형식·값 형식이 어긋나면 null', () {
      expect(FollowerPointModel.fromDoc('2026-09-11', {'followerCount': 1}),
          isNull);
      expect(FollowerPointModel.fromDoc('20260911', {'followerCount': 'x'}),
          isNull);
      expect(FollowerPointModel.fromDoc('20260911', {}), isNull);
    });
  });

  group('FollowerTrendChart', () {
    test('pointsOf는 최신순 입력을 오래된 순으로 뒤집는다', () {
      final points = FollowerTrendChart.pointsOf([_p(11, 300), _p(10, 200)]);
      expect(points.map((p) => p.followerCount), [200, 300]);
    });

    test('deltaLabel: 구간 일수와 부호 있는 증감, 천 단위 콤마', () {
      expect(FollowerTrendChart.deltaLabel([_p(1, 100), _p(30, 1334)]),
          '최근 29일 +1,234');
      expect(
          FollowerTrendChart.deltaLabel([_p(1, 100), _p(8, 88)]), '최근 7일 -12');
      expect(FollowerTrendChart.deltaLabel([_p(1, 5), _p(2, 5)]), '최근 1일 ±0');
      expect(FollowerTrendChart.deltaLabel([_p(1, 5)]), '');
    });

    testWidgets('점이 하나면 헤드라인 숫자만, 증감·날짜는 없다', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FollowerTrendChart(
            history: [_p(11, 137187)],
            color: Colors.pink,
            colorDark: Colors.red,
          ),
        ),
      ));
      expect(find.text('137,187명'), findsOneWidget);
      expect(find.textContaining('최근'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(FollowerTrendChart),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });

    testWidgets('점이 둘 이상이면 증감·양끝 날짜·선 그래프를 그린다', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FollowerTrendChart(
            history: [_p(11, 137187), _p(10, 137000), _p(9, 136900)],
            color: Colors.pink,
            colorDark: Colors.red,
          ),
        ),
      ));
      expect(find.text('137,187명'), findsOneWidget);
      expect(find.text('최근 2일 +287'), findsOneWidget);
      expect(find.text('9/9'), findsOneWidget);
      expect(find.text('9/11'), findsOneWidget);
      expect(find.text('9/10'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(FollowerTrendChart),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });
  });
}
