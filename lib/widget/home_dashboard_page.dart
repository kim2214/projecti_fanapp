import 'package:flutter/material.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/model/group.dart';
import 'package:projecti_fan_app/controllers/review_controller.dart';
import 'package:projecti_fan_app/controllers/youtube_controller.dart';
import 'package:projecti_fan_app/widget/components/video_card_skeleton.dart';
import 'package:projecti_fan_app/widget/components/youtube_video_card.dart';
import 'package:projecti_fan_app/widget/components/tap_semantics.dart';
import 'package:projecti_fan_app/widget/home/home_birthday_section.dart';
import 'package:projecti_fan_app/widget/home/home_ended_today_section.dart';
import 'package:projecti_fan_app/widget/home/home_favorites_section.dart';
import 'package:projecti_fan_app/widget/home/home_live_section.dart';
import 'package:projecti_fan_app/widget/home/home_section_title.dart';

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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(() {
      final group = _globalController.currentGroup;
      final themeColor = AppColors.group(group);
      final themeColorDark = AppColors.groupDark(group);

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
                child: _buildHeader(group, themeColor, themeColorDark),
              ),
              // 지금 방송 중
              SliverToBoxAdapter(
                child: HomeSectionTitle(
                  icon: Icons.podcasts_rounded,
                  title: '지금 방송 중',
                  color: AppColors.live,
                  trailing: HomeMoreLink('전체보기',
                      onTap: () => context.push('/livePage')),
                ),
              ),
              // 섹션마다 자체 Obx — 라이브 맵이 2분마다 바뀌어도 헤더·배너·영상은
              // 다시 빌드하지 않는다. 바깥 Obx는 선택 그룹만 구독한다.
              SliverToBoxAdapter(
                child: HomeLiveSection(
                    group: group,
                    themeColor: themeColor,
                    themeColorDark: themeColorDark),
              ),
              // 내 최애 (현재 그룹에 최애가 없으면 통째로 생략)
              SliverToBoxAdapter(
                child: HomeFavoritesSection(
                    group: group,
                    themeColor: themeColor,
                    themeColorDark: themeColorDark),
              ),
              // 오늘 방송했어요 (기록 없으면 통째로 생략)
              SliverToBoxAdapter(
                child: HomeEndedTodaySection(
                    themeColor: themeColor, themeColorDark: themeColorDark),
              ),
              // 다가오는 생일 (데이터 없으면 통째로 생략)
              SliverToBoxAdapter(
                child: HomeBirthdaySection(
                    themeColor: themeColor, themeColorDark: themeColorDark),
              ),
              // 주간 스케줄 바로가기
              SliverToBoxAdapter(
                child: _buildScheduleBanner(themeColor, themeColorDark),
              ),
              // 최신 영상
              SliverToBoxAdapter(
                child: HomeSectionTitle(
                  icon: Icons.play_circle_fill_rounded,
                  title: '최신 영상',
                  color: const Color(0xFFFF0000),
                  trailing: HomeMoreLink('더보기',
                      onTap: () => widget.onNavigateToTab(3)),
                ),
              ),
              Obx(() => _buildLatestVideos()),
              // 도움말·문의·앱 정보 입구 (상단 바는 좁아 여기에 둔다)
              SliverToBoxAdapter(child: _buildHelpLink()),
              // 하단 여백
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader(Group group, Color themeColor, Color themeColorDark) {
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
                  group.logoAsset,
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
                  group.label,
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

  // ---------------- 도움말 링크 ----------------

  Widget _buildHelpLink() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Center(
        child: TapSemantics(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/help'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.help_outline_rounded,
                      size: 16, color: context.textFaint),
                  const SizedBox(width: 6),
                  Text(
                    '도움말 · 문의 · 앱 정보',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textFaint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
