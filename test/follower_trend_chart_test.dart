// 팔로워 추이 차트의 순수 판정(정렬·증감 라벨)과 모델 파싱, 렌더링 라벨 검증.
// Firestore 없이 문서 ID·필드를 직접 주입한다 (기존 테스트 관례).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/model/follower_point_model.dart';
import 'package:projecti_fan_app/utils/date_label.dart';
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
      expect(p?.dateLabel, shortDateLabel(DateTime(2026, 9, 11)));
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
      // 마지막 기록이 오늘/어제면 "최근 N일"
      expect(
          FollowerTrendChart.deltaLabel([_p(1, 100), _p(30, 1334)],
              now: DateTime(2026, 9, 30, 15)),
          '최근 29일 +1,234');
      expect(
          FollowerTrendChart.deltaLabel([_p(1, 100), _p(8, 88)],
              now: DateTime(2026, 9, 9)),
          '최근 7일 -12');
      expect(
          FollowerTrendChart.deltaLabel([_p(1, 5), _p(2, 5)],
              now: DateTime(2026, 9, 2)),
          '최근 1일 ±0');
      expect(FollowerTrendChart.deltaLabel([_p(1, 5)]), '');
    });

    test('deltaLabel: 마지막 기록이 이틀 이상 지났으면 "최근" 대신 구간 날짜', () {
      // 서버 기록이 9/14에 멈춘 채 9/30에 보면 "최근 13일"은 거짓이다.
      expect(
          FollowerTrendChart.deltaLabel([_p(1, 100), _p(14, 1334)],
              now: DateTime(2026, 9, 30)),
          '9/1–9/14 +1,234');
      expect(
          FollowerTrendChart.deltaLabel([_p(1, 100), _p(14, 88)],
              now: DateTime(2026, 9, 16)),
          '9/1–9/14 -12');
    });

    test('xPositionsOf: 날짜에 비례한 가로 위치 — 기록 공백이 넓게 보인다', () {
      // 9/11~9/14 매일 + 9/30 (15일 공백)
      final xs = FollowerTrendChart.xPositionsOf(
          [_p(10, 1), _p(11, 2), _p(12, 3), _p(30, 4)]);
      expect(xs.first, 0);
      expect(xs.last, 1);
      expect(xs[1], closeTo(1 / 20, 1e-9));
      expect(xs[2], closeTo(2 / 20, 1e-9));
    });

    test('xPositionsOf: 점 하나는 0, 모두 같은 날이면 등간격', () {
      expect(FollowerTrendChart.xPositionsOf([_p(1, 1)]), [0.0]);
      expect(FollowerTrendChart.xPositionsOf([_p(1, 1), _p(1, 2), _p(1, 3)]),
          [0.0, 0.5, 1.0]);
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
      // 위젯은 실제 오늘을 쓰므로 오늘 기준으로 점을 만든다.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      FollowerPointModel daysAgo(int n, int count) => FollowerPointModel(
          date: today.subtract(Duration(days: n)), followerCount: count);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FollowerTrendChart(
            history: [
              daysAgo(0, 137187),
              daysAgo(1, 137000),
              daysAgo(2, 136900)
            ],
            color: Colors.pink,
            colorDark: Colors.red,
          ),
        ),
      ));
      expect(find.text('137,187명'), findsOneWidget);
      expect(find.text('최근 2일 +287'), findsOneWidget);
      expect(find.text(daysAgo(2, 0).dateLabel), findsOneWidget);
      expect(find.text(daysAgo(0, 0).dateLabel), findsOneWidget);
      expect(find.text(daysAgo(1, 0).dateLabel), findsNothing);
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
