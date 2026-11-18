import 'package:flutter/material.dart';
import 'package:projecti_fan_app/model/live_check_model.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:projecti_fan_app/utils/external_link.dart';
import 'package:projecti_fan_app/widget/components/live_stats_row.dart';
import 'package:projecti_fan_app/widget/components/tap_semantics.dart';

/// 실시간 LIVE 상태 카드 — 방송 중일 때만 보이고, 탭하면 치지직 라이브로 이동한다.
/// 방송 중이 아니거나([status]가 null·CLOSE) [broadcastId]가 없으면 빈 위젯.
class StreamerLiveCard extends StatelessWidget {
  final LiveCheckModel? status;
  final String? broadcastId;

  const StreamerLiveCard({
    super.key,
    required this.status,
    required this.broadcastId,
  });

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    if (status == null || !status.isLive) return const SizedBox.shrink();

    return TapSemantics(
        child: GestureDetector(
      onTap: () {
        final id = broadcastId;
        if (id != null) openChzzkLive(id);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.live.withAlpha(70), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.live.withAlpha(25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.live,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 6, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '치지직에서 보기',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.textFaint,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 11, color: context.textFaint),
              ],
            ),
            if (status.liveTitle?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                status.liveTitle!,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.textMain,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            LiveStatsRow(status: status),
          ],
        ),
      ),
    ));
  }
}
