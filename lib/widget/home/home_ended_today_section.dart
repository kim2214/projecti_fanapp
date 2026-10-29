import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/model/live_session_model.dart';
import 'package:projecti_fan_app/model/member.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:projecti_fan_app/utils/external_link.dart';
import 'package:projecti_fan_app/widget/components/tap_semantics.dart';
import 'package:projecti_fan_app/widget/home/home_section_title.dart';

/// 홈 "오늘 방송했어요" — 기록이 없으면 통째로 생략.
class HomeEndedTodaySection extends StatelessWidget {
  final Color themeColor;
  final Color themeColorDark;

  const HomeEndedTodaySection(
      {super.key, required this.themeColor, required this.themeColorDark});

  GlobalController get _globalController => Get.find<GlobalController>();

  @override
  Widget build(BuildContext context) =>
      Obx(() => _buildEndedTodaySection(context, themeColor, themeColorDark));

  /// 오늘 방송을 마친 멤버 목록 (서버 집계의 lastSessions 기반). 놓친 방송을
  /// 바로 알 수 있게 하고, 탭하면 치지직 채널 다시보기 목록으로 이동한다
  /// (방금 끝난 방송이 맨 위에 온다). 세션 상세는 멤버 탭의 프로필에서 본다.
  Widget _buildEndedTodaySection(
      BuildContext context, Color themeColor, Color themeColorDark) {
    final group = _globalController.currentGroup;
    final entries = _globalController.endedTodaySessions(group);
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionTitle(
          icon: Icons.history_rounded,
          title: '오늘 방송했어요',
          color: themeColorDark,
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: themeColor.withAlpha(50), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: themeColor.withAlpha(20),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < entries.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: context.textFaint.withAlpha(40),
                  ),
                _buildEndedTodayRow(context, entries[i].member,
                    entries[i].session, themeColor, themeColorDark),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEndedTodayRow(BuildContext context, Member member,
      LiveSessionModel session, Color themeColor, Color themeColorDark) {
    final details = [
      session.durationLabel,
      session.endedAgoLabel(),
    ].where((s) => s.isNotEmpty).join(' · ');

    return TapSemantics(
      label: '${member.name} 다시보기',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => openChzzkReplay(member.chzzkBroadcastId),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: themeColor.withAlpha(30),
                  backgroundImage: AssetImage(member.profileAssetPath),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.textMain,
                        ),
                      ),
                      if (session.liveTitle?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          session.liveTitle!,
                          style:
                              TextStyle(fontSize: 12, color: context.textSub),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          details,
                          style:
                              TextStyle(fontSize: 11, color: context.textFaint),
                        ),
                      ],
                    ],
                  ),
                ),
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
