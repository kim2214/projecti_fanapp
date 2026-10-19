import 'package:flutter/material.dart';
import 'package:projecti_fan_app/model/live_check_model.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';

/// 라이브 카드의 "👁 시청자 수 · 🕒 경과 시간" 줄. 값이 없는 항목은 생략한다.
/// 큰 글꼴·좁은 폭에서는 넘치는 대신 다음 줄로 내린다.
class LiveStatsRow extends StatelessWidget {
  final LiveCheckModel status;

  const LiveStatsRow({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        if (status.viewerCountText.isNotEmpty)
          _stat(context, Icons.visibility_rounded, status.viewerCountText,
              FontWeight.w600),
        if (status.uptime.isNotEmpty)
          _stat(
              context, Icons.schedule_rounded, status.uptime, FontWeight.w500),
      ],
    );
  }

  Widget _stat(
      BuildContext context, IconData icon, String text, FontWeight weight) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.textFaint),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: weight,
            color: context.textSub,
          ),
        ),
      ],
    );
  }
}
