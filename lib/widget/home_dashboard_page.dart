import 'package:flutter/material.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/model/birthday_entry.dart';
import 'package:projecti_fan_app/controllers/youtube_controller.dart';
import 'package:projecti_fan_app/model/live_check_model.dart';
import 'package:projecti_fan_app/widget/components/youtube_video_card.dart';
import 'package:url_launcher/url_launcher.dart';

/// 홈 대시보드: 지금 방송 중 + 주간 스케줄 바로가기 + 최신 영상
class HomeDashboardWidget extends StatefulWidget {
  /// 하단 탭 전환 콜백 (0: 홈, 1: 스케줄, 2: 멤버, 3: YouTube)
  final void Function(int index) onNavigateToTab;

  const HomeDashboardWidget({super.key, required this.onNavigateToTab});

  @override
  State<HomeDashboardWidget> createState() => _HomeDashboardWidgetState();
}

class _HomeDashboardWidgetState extends State<HomeDashboardWidget>
    with AutomaticKeepAliveClientMixin {
  final GlobalController _globalController = Get.find<GlobalController>();
  final YouTubeController _youtubeController = Get.find<YouTubeController>();

  // 그룹별 테마 컬러

  Worker? _groupChangeWorker;

  @override
  void initState() {
    super.initState();
    _loadData();
    _groupChangeWorker = ever(_globalController.selectedGroup, (_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _groupChangeWorker?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // 라이브 상태 (캐시 있으면 그대로) + 그룹 최신 영상 + 멤버(생일) 데이터
    await Future.wait([
      _globalController.liveCheck(),
      _youtubeController.loadGroupLatestVideos(),
      _globalController.loadStreamerFireStore(),
    ]);
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _globalController.refreshLiveStatus(),
      _youtubeController.loadGroupLatestVideos(forceRefresh: true),
      _globalController.loadStreamerFireStore(forceRefresh: true),
    ]);
  }

  Future<void> _openChzzkLive(String broadcastId) async {
    final uri = Uri.parse('https://chzzk.naver.com/live/$broadcastId');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(() {
      final isHoneyz = _globalController.selectedGroup.value == 'honeyz';
      final themeColor = isHoneyz ? AppColors.honeyz : AppColors.acaxia;
      final themeColorDark = isHoneyz ? AppColors.honeyzDark : AppColors.acaxiaDark;

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              themeColor.withAlpha(30),
              Colors.white,
              themeColor.withAlpha(15),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: RefreshIndicator(
          color: themeColorDark,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(isHoneyz, themeColor, themeColorDark),
              ),
              // 지금 방송 중
              SliverToBoxAdapter(
                child: _buildSectionTitle(
                  icon: Icons.podcasts_rounded,
                  title: '지금 방송 중',
                  color: AppColors.live,
                  trailing: GestureDetector(
                    onTap: () => context.push('/livePage'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '전체보기',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Colors.grey[500],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildLiveSection(isHoneyz, themeColor, themeColorDark),
              ),
              // 다가오는 생일 (데이터 없으면 통째로 생략)
              SliverToBoxAdapter(
                child: _buildBirthdaySection(themeColor, themeColorDark),
              ),
              // 주간 스케줄 바로가기
              SliverToBoxAdapter(
                child: _buildScheduleBanner(themeColor, themeColorDark),
              ),
              // 최신 영상
              SliverToBoxAdapter(
                child: _buildSectionTitle(
                  icon: Icons.play_circle_fill_rounded,
                  title: '최신 영상',
                  color: const Color(0xFFFF0000),
                  trailing: GestureDetector(
                    onTap: () => widget.onNavigateToTab(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '더보기',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Colors.grey[500],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _buildLatestVideos(),
              // 하단 여백
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader(bool isHoneyz, Color themeColor, Color themeColorDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withAlpha(60),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Image.asset(
                  isHoneyz
                      ? 'assets/honeyz_logo.png'
                      : 'assets/acaxia_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'HOME',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: themeColorDark,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isHoneyz ? '허니즈' : '아카시아',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required Color color,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // ---------------- 지금 방송 중 ----------------

  Widget _buildLiveSection(
      bool isHoneyz, Color themeColor, Color themeColorDark) {
    final liveStatusList = isHoneyz
        ? _globalController.honeyzliveCheckList
        : _globalController.acaxialiveCheckList;
    final members =
        _globalController.membersOf(_globalController.selectedGroup.value);

    // 아직 라이브 상태를 불러오는 중
    if (liveStatusList.isEmpty) {
      return Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
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

    // 방송 중인 멤버 인덱스
    final liveIndexes = [
      for (int i = 0; i < liveStatusList.length && i < members.length; i++)
        if (liveStatusList[i].isLive) i
    ];

    if (liveIndexes.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            Icon(
              Icons.nightlight_round,
              size: 32,
              color: themeColor.withAlpha(150),
            ),
            const SizedBox(height: 10),
            Text(
              '지금은 방송 중인 멤버가 없어요',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: liveIndexes.length,
        itemBuilder: (context, i) {
          final index = liveIndexes[i];
          final member = members[index];
          return _buildLiveCard(
            status: liveStatusList[index],
            memberName: member.name,
            assetPath: member.profileAssetPath,
            broadcastId: member.chzzkBroadcastId,
            themeColor: themeColor,
            themeColorDark: themeColorDark,
          );
        },
      ),
    );
  }

  Widget _buildLiveCard({
    required LiveCheckModel status,
    required String memberName,
    required String assetPath,
    required String broadcastId,
    required Color themeColor,
    required Color themeColorDark,
  }) {
    return GestureDetector(
      onTap: () => _openChzzkLive(broadcastId),
      child: Container(
        width: 270,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.live.withAlpha(60), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.live.withAlpha(25),
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
                      Text(
                        memberName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (status.liveCategoryValue?.isNotEmpty == true)
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
                if (status.viewerCountText.isNotEmpty) ...[
                  Icon(Icons.visibility_rounded,
                      size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    status.viewerCountText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (status.uptime.isNotEmpty) ...[
                  Icon(Icons.schedule_rounded,
                      size: 14, color: Colors.grey[500]),
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
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- 다가오는 생일 ----------------


  Widget _buildBirthdaySection(Color themeColor, Color themeColorDark) {
    final group = _globalController.selectedGroup.value;
    final birthdays = _globalController.upcomingBirthdays(group);

    // 생일 데이터가 없으면 섹션 통째로 생략
    if (birthdays.isEmpty) return const SizedBox.shrink();

    final items = birthdays.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(
          icon: Icons.cake_rounded,
          title: '다가오는 생일',
          color: AppColors.birthday,
        ),
        SizedBox(
          height: 92,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            itemBuilder: (context, i) =>
                _buildBirthdayCard(items[i], themeColor, themeColorDark),
          ),
        ),
      ],
    );
  }

  Widget _buildBirthdayCard(
      BirthdayEntry entry, Color themeColor, Color themeColorDark) {
    return Container(
      width: 230,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: entry.isToday
              ? AppColors.birthday.withAlpha(160)
              : themeColor.withAlpha(50),
          width: entry.isToday ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (entry.isToday ? AppColors.birthday : themeColor).withAlpha(25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: themeColor.withAlpha(30),
            backgroundImage: AssetImage(entry.assetPath),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.memberName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  entry.dateLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildDdayChip(entry, themeColorDark),
        ],
      ),
    );
  }

  Widget _buildDdayChip(BirthdayEntry entry, Color themeColorDark) {
    final bg = entry.isToday ? AppColors.birthday : themeColorDark.withAlpha(30);
    final fg = entry.isToday ? Colors.white : themeColorDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        entry.isToday ? '오늘 🎂' : 'D-${entry.daysUntil}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  // ---------------- 주간 스케줄 바로가기 ----------------

  Widget _buildScheduleBanner(Color themeColor, Color themeColorDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: GestureDetector(
        onTap: () => widget.onNavigateToTab(1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [themeColor, themeColorDark],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: themeColor.withAlpha(70),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '주간 스케줄',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '이번 주 멤버들의 방송 일정 확인하기',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- 최신 영상 ----------------

  Widget _buildLatestVideos() {
    final videos = _youtubeController.groupLatestVideos;

    if (_youtubeController.isGroupVideosLoading.value && videos.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF0000),
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (videos.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              '최신 영상을 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: YouTubeVideoCard(
                video: videos[index],
                index: index,
              ),
            );
          },
          childCount: videos.length,
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
