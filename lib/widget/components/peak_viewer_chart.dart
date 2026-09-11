import 'package:flutter/material.dart';
import 'package:projecti_fan_app/model/live_session_model.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';

/// 최근 방송의 최고 동시 시청자 추이 미니 막대 차트.
///
/// 단일 지표라 범례는 없고, 값 라벨은 최고점 하나에만 직접 붙인다(전 막대에
/// 숫자를 달면 읽히지 않는다). 날짜 라벨은 양 끝만. 막대는 밑변에 붙고 위만
/// 둥글게, 막대 사이는 표면색 간격으로 띈다. 개별 값 표(=세션 목록)는 바로
/// 아래 "지난 방송" 목록이 담당하므로 여기서는 추세만 보여준다.
class PeakViewerChart extends StatelessWidget {
  /// 최신순 세션 목록 (컨트롤러 조회 결과 그대로).
  final List<LiveSessionModel> sessions;
  final Color color;
  final Color colorDark;

  const PeakViewerChart({
    super.key,
    required this.sessions,
    required this.color,
    required this.colorDark,
  });

  /// 차트에 그릴 세션만 골라 오래된 → 최신 순으로 돌려준다 (최대 [max]개).
  /// 시청자 수가 없는 세션은 빈 막대 대신 제외한다. (순수 — 테스트 대상)
  static List<LiveSessionModel> pointsOf(List<LiveSessionModel> sessions,
      {int max = 10}) {
    final withPeak =
        sessions.where((s) => s.peakConcurrentUserCount != null).take(max);
    return withPeak.toList().reversed.toList();
  }

  /// "평균 1,234명". 점이 없으면 빈 문자열. (순수 — 테스트 대상)
  static String averageLabel(List<LiveSessionModel> points) {
    if (points.isEmpty) return '';
    final sum = points.fold<int>(0, (a, s) => a + s.peakConcurrentUserCount!);
    return '평균 ${_formatCount(sum ~/ points.length)}명';
  }

  static String _formatCount(int count) => count.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  static const double _plotHeight = 72;
  static const double _labelHeight = 16;

  @override
  Widget build(BuildContext context) {
    final points = pointsOf(sessions);
    // 점 하나로는 추세가 아니다 — 목록의 "최고 N명"만으로 충분.
    if (points.length < 2) return const SizedBox.shrink();

    final maxCount = points
        .map((s) => s.peakConcurrentUserCount!)
        .reduce((a, b) => a > b ? a : b);
    final maxIndex =
        points.indexWhere((s) => s.peakConcurrentUserCount == maxCount);

    return Semantics(
      // 스크린리더에는 막대 대신 요약 문장을 준다. 개별 값은 아래 목록이 읽힌다.
      label: '최근 ${points.length}회 방송 최고 동시 시청자 추이, '
          '최고 ${_formatCount(maxCount)}명, ${averageLabel(points)}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '최고 동시 시청자 · 최근 ${points.length}회',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textSub,
                  ),
                ),
                const Spacer(),
                Text(
                  averageLabel(points),
                  style: TextStyle(fontSize: 12, color: context.textFaint),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: _plotHeight + _labelHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < points.length; i++)
                    Expanded(
                      child: _buildBar(
                        context,
                        points[i],
                        ratio: points[i].peakConcurrentUserCount! / maxCount,
                        isMax: i == maxIndex,
                        isLatest: i == points.length - 1,
                        showDate: i == 0 || i == points.length - 1,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(
    BuildContext context,
    LiveSessionModel session, {
    required double ratio,
    required bool isMax,
    required bool isLatest,
    required bool showDate,
  }) {
    // 값 라벨(최고점, 글자 높이 ≤14) + 2px 간격이 들어갈 자리를 위에 남긴다.
    const labelSpace = 18.0;
    final barHeight = (_plotHeight - labelSpace) * ratio;
    // 최신 방송만 진한 강조색, 나머지는 같은 색조의 연한 단계.
    final barColor = isLatest ? colorDark : color.withAlpha(120);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isMax)
          Text(
            _formatCount(session.peakConcurrentUserCount!),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: context.textMain,
            ),
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
          ),
        const SizedBox(height: 2),
        Container(
          // 인접 막대 사이 2px 표면 간격, 두께는 24px 상한.
          constraints: const BoxConstraints(maxWidth: 24),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          height: barHeight < 3 ? 3 : barHeight,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        SizedBox(
          height: _labelHeight,
          child: showDate
              ? Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    session.dateLabel,
                    style: TextStyle(fontSize: 10, color: context.textFaint),
                    maxLines: 1,
                    softWrap: false,
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
