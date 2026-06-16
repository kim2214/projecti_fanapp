import 'package:flutter/material.dart';
import 'package:projecti_fan_app/model/live_member_entry.dart';

/// 통합 LIVE 화면용 세로 풀폭 카드.
/// 그룹 뱃지로 소속을 구분하고, 시청자 수/업타임/방송 제목을 보여준다.
class LiveMemberCard extends StatelessWidget {
  final LiveMemberEntry entry;
  final VoidCallback onTap;

  const LiveMemberCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  // 그룹별 테마 컬러 (앱 전역에서 쓰는 값과 동일)
  static const Color honeyzColor = Color(0xFFFF5E88);
  static const Color acaxiaColor = Color(0xFFCCD1F9);
  static const Color liveRed = Color(0xFFFF3B30);
  static const Color textPrimary = Color(0xFF1A3A4A);

  @override
  Widget build(BuildContext context) {
    final status = entry.status;
    final groupColor = entry.isHoneyz ? honeyzColor : acaxiaColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: liveRed.withAlpha(60), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: liveRed.withAlpha(20),
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
                    border: Border.all(color: liveRed, width: 2),
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
                          Flexible(
                            child: Text(
                              entry.memberName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
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
                            color: Colors.grey[500],
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
                    color: liveRed,
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
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
                  Icon(Icons.visibility_rounded, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    status.viewerCountText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                if (status.uptime.isNotEmpty) ...[
                  Icon(Icons.schedule_rounded, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    status.uptime,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '치지직에서 보기',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 11, color: Colors.grey[400]),
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
          color: isHoneyz ? const Color(0xFFE84A75) : const Color(0xFF8A90D8),
        ),
      ),
    );
  }
}
