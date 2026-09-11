import 'package:flutter/material.dart';
import 'package:projecti_fan_app/model/follower_point_model.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';

/// 치지직 팔로워 수 추이 (헤드라인 숫자 + 미니 선 그래프).
///
/// 팔로워는 누적값이라 하루 변화가 전체의 1% 미만이다 — 0 기준 막대로 그리면
/// 전부 같은 높이로 보이므로, 구간의 최소~최대만 담는 선 그래프를 쓴다(선은
/// 축을 잘라도 된다). 단일 지표라 범례는 없고, 값 라벨은 헤드라인(최신값)과
/// 구간 증감만, 날짜는 양 끝만 표시한다. 점이 하나뿐이면 숫자만 보인다.
class FollowerTrendChart extends StatelessWidget {
  /// 최신순 기록 (컨트롤러 조회 결과 그대로).
  final List<FollowerPointModel> history;
  final Color color;
  final Color colorDark;

  const FollowerTrendChart({
    super.key,
    required this.history,
    required this.color,
    required this.colorDark,
  });

  /// 오래된 → 최신 순으로 정렬한 점 목록. (순수 — 테스트 대상)
  static List<FollowerPointModel> pointsOf(List<FollowerPointModel> history) =>
      history.reversed.toList();

  /// 구간 증감 라벨: "최근 30일 +1,234" / "최근 7일 -12" / 변동 없음 "최근 7일 ±0".
  /// 점이 2개 미만이면 빈 문자열. (순수 — 테스트 대상)
  static String deltaLabel(List<FollowerPointModel> points) {
    if (points.length < 2) return '';
    final days = points.last.date.difference(points.first.date).inDays;
    final delta = points.last.followerCount - points.first.followerCount;
    final sign = delta > 0 ? '+' : (delta < 0 ? '-' : '±');
    return '최근 $days일 $sign${formatCount(delta.abs())}';
  }

  static String formatCount(int count) => count.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  static const double _plotHeight = 56;

  @override
  Widget build(BuildContext context) {
    final points = pointsOf(history);
    if (points.isEmpty) return const SizedBox.shrink();

    final latest = formatCount(points.last.followerCount);
    final delta = deltaLabel(points);

    return Semantics(
      label: '치지직 팔로워 $latest명${delta.isEmpty ? '' : ', $delta'}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '팔로워',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textSub,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$latest명',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.textMain,
                    height: 1.1,
                  ),
                ),
                const Spacer(),
                if (delta.isNotEmpty)
                  Text(
                    delta,
                    style: TextStyle(fontSize: 12, color: context.textFaint),
                  ),
              ],
            ),
            if (points.length >= 2) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: _plotHeight,
                width: double.infinity,
                child: CustomPaint(
                  painter: _LinePainter(
                    values: [for (final p in points) p.followerCount],
                    line: colorDark,
                    fill: color.withAlpha(50),
                    ring: context.surface,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(points.first.dateLabel,
                      style: TextStyle(fontSize: 10, color: context.textFaint)),
                  Text(points.last.dateLabel,
                      style: TextStyle(fontSize: 10, color: context.textFaint)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 2px 선 + 연한 면 + 끝점 마커(8px, 표면색 2px 링). y 범위는 값의 최소~최대에
/// 위아래 여백을 더한 것 — 모든 값이 같으면 가운데 수평선.
class _LinePainter extends CustomPainter {
  final List<int> values;
  final Color line;
  final Color fill;
  final Color ring;

  const _LinePainter({
    required this.values,
    required this.line,
    required this.fill,
    required this.ring,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    const pad = 6.0; // 끝점 마커 반지름 + 링이 잘리지 않을 여백
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);

    Offset at(int i) {
      final x = pad + (size.width - pad * 2) * i / (values.length - 1);
      final t = (values[i] - minV) / range;
      final y = pad + (size.height - pad * 2) * (1 - t);
      return Offset(x, y);
    }

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (int i = 1; i < values.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }

    final area = Path.from(path)
      ..lineTo(at(values.length - 1).dx, size.height)
      ..lineTo(at(0).dx, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = fill);

    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final end = at(values.length - 1);
    canvas.drawCircle(end, 6, Paint()..color = ring);
    canvas.drawCircle(end, 4, Paint()..color = line);
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.values != values || old.line != line || old.fill != fill;
}
