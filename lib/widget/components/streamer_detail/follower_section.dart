import 'package:flutter/material.dart';
import 'package:projecti_fan_app/model/follower_point_model.dart';
import 'package:projecti_fan_app/model/group.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:projecti_fan_app/widget/components/follower_trend_chart.dart';

/// 팔로워 추이 섹션 — 서버가 매일 기록한 팔로워 수(최근 30일) 차트.
/// 기록이 없거나 조회에 실패하면 섹션을 숨긴다 — 보조 정보라 에러를 띄우지 않는다.
class StreamerFollowerSection extends StatelessWidget {
  final Group group;
  final Future<List<FollowerPointModel>>? future;

  const StreamerFollowerSection({
    super.key,
    required this.group,
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    final future = this.future;
    if (future == null) return const SizedBox.shrink();
    final themeColor = AppColors.group(group);

    return FutureBuilder<List<FollowerPointModel>>(
      future: future,
      builder: (context, snapshot) {
        final history = snapshot.data ?? [];
        if (history.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.softShadow,
          ),
          child: FollowerTrendChart(
            history: history,
            color: themeColor,
            // 선·최신 막대는 글자용 톤 — 아카시아 브랜드색은 흰 배경에서 흐리다.
            colorDark: context.groupInk(group),
          ),
        );
      },
    );
  }
}
