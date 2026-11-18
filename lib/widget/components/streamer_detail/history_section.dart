import 'package:flutter/material.dart';
import 'package:projecti_fan_app/model/group.dart';
import 'package:projecti_fan_app/model/live_session_model.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:projecti_fan_app/utils/external_link.dart';
import 'package:projecti_fan_app/widget/components/peak_viewer_chart.dart';
import 'package:projecti_fan_app/widget/components/tap_semantics.dart';

/// 지난 방송 섹션 — 최근 10회 최고 시청자 추이 차트 + 최근 5개 세션 목록.
/// 데이터가 없거나(신규 배포 직후·미방송 멤버) 조회에 실패하면 섹션 자체를
/// 숨긴다 — 보조 정보라 에러를 띄우지 않는다. 각 줄을 탭하면 치지직 채널
/// 다시보기 목록으로 이동한다(놓친 방송 시청).
class StreamerHistorySection extends StatelessWidget {
  final Group group;
  final Future<List<LiveSessionModel>>? future;
  final String? broadcastId;

  const StreamerHistorySection({
    super.key,
    required this.group,
    required this.future,
    required this.broadcastId,
  });

  @override
  Widget build(BuildContext context) {
    final future = this.future;
    if (future == null) return const SizedBox.shrink();
    final themeColor = AppColors.group(group);

    return FutureBuilder<List<LiveSessionModel>>(
      future: future,
      builder: (context, snapshot) {
        final all = snapshot.data ?? [];
        if (all.isEmpty) return const SizedBox.shrink();
        final sessions = all.take(5).toList();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded,
                        size: 20, color: context.groupInk(group)),
                    const SizedBox(width: 8),
                    Text(
                      '지난 방송',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textMain,
                      ),
                    ),
                  ],
                ),
              ),
              if (PeakViewerChart.pointsOf(all).length >= 2)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: PeakViewerChart(
                    sessions: all,
                    color: themeColor,
                    // 선·최신 막대는 글자용 톤 — 아카시아 브랜드색은 흰 배경에서 흐리다.
                    colorDark: context.groupInk(group),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < sessions.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: context.textFaint.withAlpha(40),
                        ),
                      _SessionRow(
                        session: sessions[i],
                        group: group,
                        broadcastId: broadcastId,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SessionRow extends StatelessWidget {
  final LiveSessionModel session;
  final Group group;
  final String? broadcastId;

  const _SessionRow({
    required this.session,
    required this.group,
    required this.broadcastId,
  });

  @override
  Widget build(BuildContext context) {
    // "3시간 12분 · 최고 1,384명 · Just Chatting" — 없는 값은 항목째 생략.
    final details = [
      session.durationLabel,
      session.peakViewerText,
      session.liveCategoryValue ?? '',
    ].where((s) => s.isNotEmpty).join(' · ');

    return TapSemantics(
      label: '${session.liveTitle ?? '지난 방송'} 다시보기',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap:
              broadcastId == null ? null : () => openChzzkReplay(broadcastId!),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 40,
                  // 다른 해 기록("25.9.11")은 칸에 맞게 줄인다.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      session.dateLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.groupInk(group),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.liveTitle ?? '(제목 없음)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.textMain,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          details,
                          style:
                              TextStyle(fontSize: 12, color: context.textFaint),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.play_circle_outline_rounded,
                    size: 20, color: context.textFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
