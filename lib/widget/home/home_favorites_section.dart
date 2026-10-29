import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:projecti_fan_app/controllers/favorites_controller.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/model/group.dart';
import 'package:projecti_fan_app/model/member.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:projecti_fan_app/widget/components/tap_semantics.dart';
import 'package:projecti_fan_app/widget/home/home_section_title.dart';

/// 홈 "내 최애" — 현재 그룹에 최애가 없으면 통째로 생략.
class HomeFavoritesSection extends StatelessWidget {
  final Group group;
  final Color themeColor;
  final Color themeColorDark;

  const HomeFavoritesSection(
      {super.key,
      required this.group,
      required this.themeColor,
      required this.themeColorDark});

  GlobalController get _globalController => Get.find<GlobalController>();
  FavoritesController get _favorites => Get.find<FavoritesController>();

  @override
  Widget build(BuildContext context) => Obx(
      () => _buildFavoritesSection(context, group, themeColor, themeColorDark));

  /// 현재 그룹의 최애 멤버 바로가기 (카탈로그 순서). 탭하면 멤버 프로필로
  /// 간다 — 방송 중이면 위 "지금 방송 중" 카드가 이미 있으므로 여기선 배지만
  /// 붙인다. 최애 목록을 Obx 안에서 읽어 지정/해제가 바로 반영된다.
  Widget _buildFavoritesSection(BuildContext context, Group group,
      Color themeColor, Color themeColorDark) {
    final favorites = [
      for (final member in _globalController.membersOf(group))
        if (_favorites.isFavorite(group, member.key)) member
    ];
    if (favorites.isEmpty) return const SizedBox.shrink();

    final liveStatus = _globalController.liveStatusOf(group);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomeSectionTitle(
          icon: Icons.star_rounded,
          title: '내 최애',
          color: AppColors.favorite,
        ),
        SizedBox(
          height: homeRowHeight(context, 96),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: favorites.length,
            itemBuilder: (context, i) => _buildFavoriteTile(
              context,
              favorites[i],
              isLive: liveStatus[favorites[i].key]?.isLive == true,
              themeColor: themeColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteTile(BuildContext context, Member member,
      {required bool isLive, required Color themeColor}) {
    return TapSemantics(
      label: '${member.name} 프로필${isLive ? ', 방송 중' : ''}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context
            .push('/streamerDetail?group=${member.group.id}&key=${member.key}'),
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isLive ? AppColors.live : themeColor.withAlpha(90),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: themeColor.withAlpha(30),
                      backgroundImage: AssetImage(member.profileAssetPath),
                    ),
                  ),
                  if (isLive)
                    Positioned(
                      bottom: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.live,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                member.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.textMain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
