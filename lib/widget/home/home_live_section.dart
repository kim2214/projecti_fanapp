import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/favorites_controller.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/model/group.dart';
import 'package:projecti_fan_app/model/live_check_model.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:projecti_fan_app/utils/external_link.dart';
import 'package:projecti_fan_app/widget/components/live_stats_row.dart';
import 'package:projecti_fan_app/widget/components/live_thumbnail.dart';
import 'package:projecti_fan_app/widget/components/status_message.dart';
import 'package:projecti_fan_app/widget/components/tap_semantics.dart';
import 'package:projecti_fan_app/widget/home/home_section_title.dart';

/// 홈 "지금 방송 중" — 현재 그룹의 방송 중 멤버 카드(최애 먼저).
/// 자체 Obx라 라이브 맵이 바뀌어도 홈의 다른 섹션은 다시 빌드하지 않는다.
class HomeLiveSection extends StatelessWidget {
  final Group group;
  final Color themeColor;
  final Color themeColorDark;

  const HomeLiveSection(
      {super.key,
      required this.group,
      required this.themeColor,
      required this.themeColorDark});

  GlobalController get _globalController => Get.find<GlobalController>();
  FavoritesController get _favorites => Get.find<FavoritesController>();

  @override
  Widget build(BuildContext context) =>
      Obx(() => _buildLiveSection(context, group, themeColor, themeColorDark));

  Widget _buildLiveSection(BuildContext context, Group group, Color themeColor,
      Color themeColorDark) {
    final liveStatus = _globalController.liveStatusOf(group);
    final members = _globalController.membersOf(group);

    // 아직 라이브 상태를 불러오는 중 (폴링 전이면 맵이 비어 있음)
    if (liveStatus.isEmpty) {
      return Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: themeColorDark,
            strokeWidth: 2,
          ),
        ),
      );
    }

    // 방송 중인 멤버 — 최애 먼저, 그다음 카탈로그 순서 (key로 상태 조회).
    // 최애 목록을 Obx 안에서 읽으므로 최애를 바꾸면 순서도 바로 바뀐다.
    final liveMembers = _favorites.favoritesFirst(
      [
        for (final member in members)
          if (liveStatus[member.key]?.isLive == true) member
      ],
      (m) => m.group,
      (m) => m.key,
    );

    // 마지막 갱신에서 상태를 하나도 받지 못했다(오프라인 등) — 캐시는 직전 값이거나
    // 전원 CLOSE라 "방송 중인 멤버가 없어요"는 사실이 아닐 수 있다.
    final unavailable = _globalController.liveUnavailableGroups.contains(group);

    if (liveMembers.isEmpty && unavailable) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: StatusMessage(
          compact: true,
          icon: Icons.wifi_off_rounded,
          iconColor: themeColor.withAlpha(150),
          title: '방송 상태를 확인하지 못했어요',
          subtitle: '연결을 확인한 뒤 당겨서 새로고침해 주세요',
        ),
      );
    }

    if (liveMembers.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: themeColor.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: StatusMessage(
          compact: true,
          icon: Icons.nightlight_round,
          iconColor: themeColor.withAlpha(150),
          title: '지금은 방송 중인 멤버가 없어요',
        ),
      );
    }

    // 카드 폭 270 - 패딩 32 = 238 → 16:9 썸네일 134 + 간격 12. 한 명이라도
    // 썸네일이 있으면 줄 전체를 그만큼 키운다 (가로 스크롤 줄은 높이가 하나).
    final hasThumbnail =
        liveMembers.any((m) => liveStatus[m.key]?.thumbnailUrl() != null);
    final cards = SizedBox(
      height: homeRowHeight(context, 200) + (hasThumbnail ? 146 : 0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: liveMembers.length,
        itemBuilder: (context, i) {
          final member = liveMembers[i];
          return _buildLiveCard(
            context,
            status: liveStatus[member.key]!,
            memberName: member.name,
            assetPath: member.profileAssetPath,
            broadcastId: member.chzzkBroadcastId,
            isFavorite: _favorites.isFavorite(member.group, member.key),
            themeColor: themeColor,
            themeColorDark: themeColorDark,
          );
        },
      ),
    );
    if (!unavailable) return cards;

    // 직전에 받은 방송 목록은 남겨 두되, 지금 상태가 아닐 수 있음을 알린다.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(
            '연결이 불안정해 최신 상태가 아닐 수 있어요',
            style: TextStyle(fontSize: 12, color: context.textFaint),
          ),
        ),
        cards,
      ],
    );
  }

  Widget _buildLiveCard(
    BuildContext context, {
    required LiveCheckModel status,
    required String memberName,
    required String assetPath,
    required String broadcastId,
    required bool isFavorite,
    required Color themeColor,
    required Color themeColorDark,
  }) {
    // 최애 강조는 통합 LIVE 카드(LiveMemberCard)와 같은 테두리·별 표시.
    final accent = isFavorite ? AppColors.favorite : AppColors.live;
    return TapSemantics(
        child: GestureDetector(
      onTap: () => openChzzkLive(broadcastId),
      child: Container(
        width: 270,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withAlpha(isFavorite ? 160 : 60),
            width: isFavorite ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withAlpha(25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 방송 썸네일 (서버 집계에 있을 때만)
            LiveThumbnail(url: status.thumbnailUrl()),
            Row(
              children: [
                // 프로필 + LIVE 링
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.live, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: themeColor.withAlpha(30),
                    backgroundImage: AssetImage(assetPath),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isFavorite) ...[
                            const Icon(Icons.star_rounded,
                                size: 16, color: AppColors.favorite),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              memberName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.textMain,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (status.liveCategoryValue?.isNotEmpty == true)
                        Text(
                          status.liveCategoryValue!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: context.textFaint,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // LIVE 뱃지
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.live,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 방송 제목
            Expanded(
              child: Text(
                status.liveTitle ?? '',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.textMain,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            // 시청자 수 / 업타임
            Row(
              children: [
                Expanded(child: LiveStatsRow(status: status)),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: context.textFaint,
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }
}
