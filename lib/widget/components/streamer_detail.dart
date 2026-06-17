import 'package:flutter/material.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/model/streamer_model.dart';
import 'package:url_launcher/url_launcher.dart';

class StreamerDetail extends StatelessWidget {
  final StreamerModel pjiMember;

  const StreamerDetail({super.key, required this.pjiMember});

  // 그룹별 테마 컬러

  @override
  Widget build(BuildContext context) {
    final globalController = Get.find<GlobalController>();
    final isHoneyz = globalController.selectedGroup.value == 'honeyz';
    final themeColor = isHoneyz ? AppColors.honeyz : AppColors.acaxia;
    final themeColorDark = isHoneyz ? AppColors.honeyzDark : AppColors.acaxiaDark;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // 커스텀 앱바
          SliverToBoxAdapter(
            child: _buildAppBar(context, themeColor),
          ),
          // 프로필 섹션
          SliverToBoxAdapter(
            child: _buildProfileSection(isHoneyz, themeColor, themeColorDark),
          ),
          // SNS 링크 섹션
          SliverToBoxAdapter(
            child: _buildSocialSection(themeColor, themeColorDark),
          ),
          // 하단 여백
          const SliverToBoxAdapter(
            child: SizedBox(height: 50),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Color themeColor) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: themeColor,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '멤버 프로필',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: themeColor.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'PROFILE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: themeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(
      bool isHoneyz, Color themeColor, Color themeColorDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: themeColor.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // 프로필 이미지
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    themeColor.withAlpha(40),
                    themeColor.withAlpha(80),
                  ],
                ),
              ),
              child: Image.asset(
                isHoneyz
                    ? 'assets/honeyz/${pjiMember.profileName}_profile.png'
                    : 'assets/acaxia/${pjiMember.profileName}_profile.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 이름 및 정보
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 그룹 뱃지
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [themeColor, themeColorDark],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isHoneyz ? 'HONEYZ' : 'ACAXIA',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 이름
                Text(
                  pjiMember.name ?? '',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${isHoneyz ? "허니즈" : "아카시아"} 소속',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSection(Color themeColor, Color themeColorDark) {
    final socialLinks = [
      SocialLink(
        name: '치지직',
        icon: 'assets/icons/chzzk_icon.png',
        url: pjiMember.chzzk,
        color: const Color(0xFF00FFA3),
        description: '라이브 방송 시청',
      ),
      SocialLink(
        name: 'YouTube',
        icon: 'assets/icons/youtube_icon.png',
        url: pjiMember.youtube,
        color: const Color(0xFFFF0000),
        description: '영상 콘텐츠',
      ),
      SocialLink(
        name: 'X (Twitter)',
        icon: 'assets/icons/x_icon.png',
        url: pjiMember.twitter,
        color: const Color(0xFF000000),
        description: '소식 및 업데이트',
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
                Icon(
                  Icons.link_rounded,
                  size: 20,
                  color: themeColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'SNS & 채널',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ...socialLinks.map((link) => _buildSocialCard(link, themeColor)),
        ],
      ),
    );
  }

  Widget _buildSocialCard(SocialLink link, Color themeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: link.url != null && link.url!.isNotEmpty
              ? () async {
                  final uri = Uri.parse(link.url!);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 아이콘
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: link.color.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      link.icon,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 텍스트
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        link.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                // 화살표
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
                    color: themeColor,
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
  final String icon;
  final String? url;
  final Color color;
  final String description;

  const SocialLink({
    required this.name,
    required this.icon,
    required this.url,
    required this.color,
    required this.description,
  });
}
