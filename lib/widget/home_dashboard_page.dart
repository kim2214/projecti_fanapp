import 'package:flutter/material.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/model/birthday_entry.dart';
import 'package:projecti_fan_app/controllers/review_controller.dart';
import 'package:projecti_fan_app/controllers/youtube_controller.dart';
import 'package:projecti_fan_app/model/live_check_model.dart';
import 'package:projecti_fan_app/model/live_session_model.dart';
import 'package:projecti_fan_app/model/member.dart';
import 'package:projecti_fan_app/model/streamer_model.dart';
import 'package:projecti_fan_app/widget/components/video_card_skeleton.dart';
import 'package:projecti_fan_app/widget/components/youtube_video_card.dart';
import 'package:projecti_fan_app/utils/external_link.dart';
import 'package:projecti_fan_app/widget/components/tap_semantics.dart';

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

    // 홈 대시보드 진입은 앱을 계속 쓰고 있다는 신호. 실행 횟수·요청 간격 조건을
    // 만족할 때만 실제로 리뷰가 뜬다 (판정은 ReviewController가 소유).
    if (Get.isRegistered<ReviewController>()) {
      Get.find<ReviewController>().maybeRequestReview();
    }
  }

  @override
  void dispose() {
    _groupChangeWorker?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // 라이브 상태 (캐시 있으면 그대로) + 멤버(생일) 데이터.
    // 그룹 최신 영상은 YouTubeController가 자체 ever(selectedGroup)로 단일
    // 소유한다 — 여기서도 부르면 그룹 전환마다 RSS fan-out이 두 벌 나간다.
    await Future.wait([
      _globalController.liveCheck(),
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
    final uri = Uri.parse(Member.liveUrlOf(broadcastId));
    await openExternalUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(() {
      final isHoneyz = _globalController.selectedGroup.value == 'honeyz';
      final themeColor = isHoneyz ? AppColors.honeyz : AppColors.acaxia;
      final themeColorDark =
          isHoneyz ? AppColors.honeyzDark : AppColors.acaxiaDark;

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              themeColor.withAlpha(30),
              context.bg,
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
                  trailing: TapSemantics(
                      child: GestureDetector(
                    onTap: () => context.push('/livePage'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '전체보기',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.textFaint,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: context.textFaint,
                        ),
                      ],
                    ),
                  )),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildLiveSection(isHoneyz, themeColor, themeColorDark),
              ),
              // 오늘 방송했어요 (기록 없으면 통째로 생략)
              SliverToBoxAdapter(
                child: _buildEndedTodaySection(themeColor, themeColorDark),
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
                  trailing: TapSemantics(
                      child: GestureDetector(
                    onTap: () => widget.onNavigateToTab(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '더보기',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.textFaint,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: context.textFaint,
                        ),
                      ],
                    ),
                  )),
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
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.textMain,
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

  /// 가로 스크롤 카드 행의 높이. 고정 높이는 시스템 글꼴을 키우면 카드 안의
  /// 다단 텍스트가 넘치므로, 글꼴 배율(최대 1.6배까지)에 맞춰 함께 키운다.
  double _scaledHeight(double base) =>
      base * MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.6);

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
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: context.textMain,
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
    final liveStatus = isHoneyz
        ? _globalController.honeyzLiveStatus
        : _globalController.acaxiaLiveStatus;
    final members =
        _globalController.membersOf(_globalController.selectedGroup.value);

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

    // 방송 중인 멤버 (카탈로그 순서, key로 상태 조회)
    final liveMembers = [
      for (final member in members)
        if (liveStatus[member.key]?.isLive == true) member
    ];

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
                color: context.textFaint,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: _scaledHeight(200),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: liveMembers.length,
        itemBuilder: (context, i) {
          final member = liveMembers[i];
          return _buildLiveCard(
            status: liveStatus[member.key]!,
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
    return TapSemantics(
        child: GestureDetector(
      onTap: () => _openChzzkLive(broadcastId),
      child: Container(
        width: 270,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surface,
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.textMain,
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
                  const SizedBox(width: 12),
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

  // ---------------- 다가오는 생일 ----------------

  // ---------------- 오늘 방송했어요 ----------------

  /// 오늘 방송을 마친 멤버 목록 (서버 집계의 lastSessions 기반). 놓친 방송을
  /// 바로 알 수 있게 하고, 탭하면 프로필의 "지난 방송"으로 이어진다.
  Widget _buildEndedTodaySection(Color themeColor, Color themeColorDark) {
    final group = _globalController.selectedGroup.value;
    final entries = _globalController.endedTodaySessions(group);
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(
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
                _buildEndedTodayRow(entries[i].member, entries[i].session,
                    themeColor, themeColorDark),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEndedTodayRow(Member member, LiveSessionModel session,
      Color themeColor, Color themeColorDark) {
    final details = [
      session.durationLabel,
      session.endedAgoLabel(),
    ].where((s) => s.isNotEmpty).join(' · ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          // 프로필 데이터가 아직 없으면 빈 모델 — 화면은 group/key로 그려진다.
          final streamer =
              _globalController.streamerOf(member.group, member.key) ??
                  StreamerModel.empty();
          context.push(
            '/streamerDetail?group=${member.group}&key=${member.key}',
            extra: streamer,
          );
        },
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
                        style: TextStyle(fontSize: 12, color: context.textSub),
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
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: context.textFaint),
            ],
          ),
        ),
      ),
    );
  }

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
          height: _scaledHeight(92),
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
        color: context.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: entry.isToday
              ? AppColors.birthday.withAlpha(160)
              : themeColor.withAlpha(50),
          width: entry.isToday ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (entry.isToday ? AppColors.birthday : themeColor).withAlpha(25),
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.textMain,
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
                    color: context.textSub,
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
    final bg =
        entry.isToday ? AppColors.birthday : themeColorDark.withAlpha(30);
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
      child: TapSemantics(
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
      )),
    );
  }

  // ---------------- 최신 영상 ----------------

  Widget _buildLatestVideos() {
    final videos = _youtubeController.groupLatestVideos;

    if (_youtubeController.isGroupVideosLoading.value && videos.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: VideoCardSkeleton(),
            ),
            childCount: 4,
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
                color: context.textFaint,
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
