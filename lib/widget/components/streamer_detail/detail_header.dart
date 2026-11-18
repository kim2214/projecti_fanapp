import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/favorites_controller.dart';
import 'package:projecti_fan_app/model/group.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:projecti_fan_app/widget/components/round_icon_button.dart';

/// 멤버 프로필 상단바 — 뒤로가기·제목·최애 토글.
class StreamerDetailAppBar extends StatelessWidget {
  final Group group;
  final String memberKey;

  const StreamerDetailAppBar({
    super.key,
    required this.group,
    required this.memberKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 글자·아이콘은 groupInk — 아카시아 브랜드색은 흰 배경 대비 1.5:1이다.
          RoundIconButton.back(context, color: context.groupInk(group)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '멤버 프로필',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textMain,
              ),
            ),
          ),
          // 최애 토글
          _FavoriteButton(group: group, memberKey: memberKey),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final Group group;
  final String memberKey;

  const _FavoriteButton({required this.group, required this.memberKey});

  @override
  Widget build(BuildContext context) {
    if (memberKey.isEmpty) return const SizedBox.shrink();
    final favorites = Get.find<FavoritesController>();
    return Obx(() {
      final isFav = favorites.isFavorite(group, memberKey);
      return RoundIconButton(
        icon: isFav ? Icons.star_rounded : Icons.star_outline_rounded,
        color: isFav ? AppColors.favorite : context.textFaint,
        label: isFav ? '최애 해제' : '최애 지정',
        iconSize: 24,
        onTap: () => favorites.toggle(group, memberKey),
      );
    });
  }
}
