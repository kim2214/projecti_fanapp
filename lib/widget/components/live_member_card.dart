import 'package:flutter/material.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:projecti_fan_app/model/live_member_entry.dart';

/// 통합 LIVE 화면용 세로 풀폭 카드.
/// 그룹 뱃지로 소속을 구분하고, 시청자 수/업타임/방송 제목을 보여준다.
class LiveMemberCard extends StatelessWidget {
  final LiveMemberEntry entry;
  final VoidCallback onTap;
  final bool isFavorite;

  const LiveMemberCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.isFavorite = false,
  });

  // 그룹별 테마 컬러 (앱 전역에서 쓰는 값과 동일)

  @override
  Widget build(BuildContext context) {
    final status = entry.status;
    final groupColor = entry.isHoneyz ? AppColors.honeyz : AppColors.acaxia;
    final borderColor = isFavorite
        ? AppColors.favorite.withAlpha(160)
        : AppColors.live.withAlpha(60);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: isFavorite ? 2 : 1.5),
          boxShadow: [
            BoxShadow(
              color: (isFavorite ? AppColors.favorite : AppColors.live)
                  .withAlpha(20),
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
                // 프로필 + LIVE 링
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.live, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: groupColor.withAlpha(30),
                    backgroundImage: AssetImage(entry.assetPath),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isFavorite) ...[
                            const Icon(Icons.star_rounded,
                                size: 18, color: AppColors.favorite),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              entry.memberName,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: context.textMain,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildGroupBadge(entry.isHoneyz, groupColor),
                        ],
                      ),
                      if (status.liveCategoryValue?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
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
              ],
            ),
            // 방송 제목
            if (status.liveTitle?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                status.liveTitle!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textMain,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            // 시청자 수 / 업타임 / 바로가기
            Row(
              children: [
                if (status.viewerCountText.isNotEmpty) ...[
                  Icon(Icons.visibility_rounded,
                      size: 14, color: context.textFaint),
                  const SizedBox(width: 4),
                  Text(
                    status.viewerCountText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.textSub,
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                if (status.uptime.isNotEmpty) ...[
                  Icon(Icons.schedule_rounded,
                      size: 14, color: context.textFaint),
                  const SizedBox(width: 4),
                  Text(
                    status.uptime,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.textSub,
                    ),
                  ),
                ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildGroupBadge(bool isHoneyz, Color groupColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: groupColor.withAlpha(40),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isHoneyz ? '허니즈' : '아카시아',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isHoneyz ? AppColors.honeyzDark : AppColors.acaxiaText,
        ),
      ),
    );
  }
}
