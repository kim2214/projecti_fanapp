import 'package:flutter/material.dart';
import 'package:projecti_fan_app/model/group.dart';
import 'package:projecti_fan_app/model/streamer_model.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:projecti_fan_app/utils/app_snackbar.dart';
import 'package:projecti_fan_app/utils/external_link.dart';

/// SNS & 채널 섹션 — 치지직·YouTube·X는 항상, 카페·디스코드는 프로필에 값이
/// 있는 멤버만 표시한다(없는 멤버가 대부분이라 빈 카드를 늘어놓지 않는다).
class StreamerSocialSection extends StatelessWidget {
  final Group group;
  final StreamerModel streamer;

  const StreamerSocialSection({
    super.key,
    required this.group,
    required this.streamer,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = AppColors.group(group);
    final socialLinks = [
      SocialLink(
        name: '치지직',
        icon: 'assets/icons/chzzk_icon.png',
        url: streamer.chzzk,
        color: const Color(0xFF00FFA3),
        description: '라이브 방송 시청',
      ),
      SocialLink(
        name: 'YouTube',
        icon: 'assets/icons/youtube_icon.png',
        url: streamer.youtube,
        color: const Color(0xFFFF0000),
        description: '영상 콘텐츠',
      ),
      SocialLink(
        name: 'X (Twitter)',
        icon: 'assets/icons/x_icon.png',
        url: streamer.twitter,
        color: const Color(0xFF000000),
        description: '소식 및 업데이트',
      ),
      // 팬 커뮤니티 — Firestore 프로필에 값이 있는 멤버만 표시한다 (기본 3개 링크와
      // 달리 없는 멤버가 대부분이라 빈 카드를 늘어놓지 않는다).
      if (streamer.cafe?.isNotEmpty == true)
        SocialLink(
          name: '네이버 카페',
          iconData: Icons.forum_rounded,
          url: streamer.cafe,
          color: const Color(0xFF03C75A),
          description: '팬 커뮤니티',
        ),
      if (streamer.discord?.isNotEmpty == true)
        SocialLink(
          name: '디스코드',
          iconData: Icons.discord,
          url: streamer.discord,
          color: const Color(0xFF5865F2),
          description: '팬 디스코드 서버',
        ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Row(
              children: [
                Icon(Icons.link_rounded,
                    size: 20, color: context.groupInk(group)),
                const SizedBox(width: 8),
                Text(
                  'SNS & 채널',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textMain,
                  ),
                ),
              ],
            ),
          ),
          ...socialLinks.map((link) =>
              _SocialCard(link: link, group: group, themeColor: themeColor)),
        ],
      ),
    );
  }
}

class _SocialCard extends StatelessWidget {
  final SocialLink link;
  final Group group;
  final Color themeColor;

  const _SocialCard({
    required this.link,
    required this.group,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: link.url != null && link.url!.isNotEmpty
              ? () async {
                  // Firestore 값이라 형식이 보장되지 않는다 — parse 예외가
                  // onTap 밖으로 새면 fatal로 집계되므로 tryParse로 받는다.
                  final uri = Uri.tryParse(link.url!);
                  if (uri == null) {
                    showAppSnackBar('링크 주소가 올바르지 않습니다.');
                    return;
                  }
                  await openExternalUrl(uri);
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: link.color.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: link.icon != null
                        ? Image.asset(link.icon!, fit: BoxFit.contain)
                        : Icon(link.iconData, size: 26, color: link.color),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        link.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: themeColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: context.groupInk(group),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SocialLink {
  final String name;

  /// 브랜드 아이콘 에셋 경로. 없으면 [iconData](Material 아이콘)로 그린다.
  final String? icon;
  final IconData? iconData;
  final String? url;
  final Color color;
  final String description;

  const SocialLink({
    required this.name,
    this.icon,
    this.iconData,
    required this.url,
    required this.color,
    required this.description,
  }) : assert(icon != null || iconData != null);
}
