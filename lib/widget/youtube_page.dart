import 'package:flutter/material.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/controllers/youtube_controller.dart';
import 'package:projecti_fan_app/widget/youtube_theme.dart';
import 'package:projecti_fan_app/widget/components/video_card_skeleton.dart';
import 'package:projecti_fan_app/widget/components/youtube_video_card.dart';
import 'package:projecti_fan_app/utils/external_link.dart';
import 'package:projecti_fan_app/widget/components/tap_semantics.dart';

class YouTubePageWidget extends StatefulWidget {
  const YouTubePageWidget({super.key});

  @override
  State<YouTubePageWidget> createState() => _YouTubePageWidgetState();
}

class _YouTubePageWidgetState extends State<YouTubePageWidget>
    with AutomaticKeepAliveClientMixin {
  final youtubeController = Get.find<YouTubeController>();
  final globalController = Get.find<GlobalController>();
  final ScrollController _scrollController = ScrollController();

  // YouTube 브랜드 색상
  static const Color youtubeRed = Color(0xFFFF0000);

  Worker? _groupChangeWorker;

  @override
  void initState() {
    super.initState();
    // 초기 로드
    if (youtubeController.videoList.isEmpty) {
      youtubeController.loadVideos();
    }
    // 그룹 변경 시 스크롤 초기화
    _groupChangeWorker = ever(globalController.selectedGroup, (_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    _groupChangeWorker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 멤버의 YouTube 채널 페이지 열기
  Future<void> _openChannelPage() async {
    final url = youtubeController.currentChannelUrl;
    if (url == null) return;
    await openExternalUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? context.bg : null,
        gradient: context.isDark
            ? null
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  YouTubeTheme.backgroundLight,
                  YouTubeTheme.backgroundMid,
                  YouTubeTheme.background,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
      ),
      child: Obx(() => _buildContent()),
    );
  }

  Widget _buildContent() {
    // 로딩 중 (첫 로드)
    if (youtubeController.isLoading.value &&
        youtubeController.videoList.isEmpty) {
      return _buildLoadingWithSelector();
    }

    // 에러 상태
    if (youtubeController.hasError.value &&
        youtubeController.videoList.isEmpty) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: youtubeController.refresh,
      color: youtubeRed,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 헤더
          SliverToBoxAdapter(child: _buildHeader()),
          // 멤버 셀렉터
          SliverToBoxAdapter(child: _buildMemberSelector()),
          // 비디오 개수
          SliverToBoxAdapter(child: _buildVideoCount()),
          // 비디오 리스트
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: YouTubeVideoCard(
                      video: youtubeController.videoList[index],
                      index: index,
                    ),
                  );
                },
                childCount: youtubeController.videoList.length,
              ),
            ),
          ),
          // 전체 영상은 YouTube 채널에서
          if (youtubeController.videoList.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Center(
                  child: OutlinedButton.icon(
                    onPressed: _openChannelPage,
                    icon: const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: youtubeRed,
                    ),
                    label: const Text(
                      'YouTube에서 전체 영상 보기',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: youtubeRed,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: youtubeRed.withAlpha(100)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // 하단 여백
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  /// 로딩 중일 때도 멤버 셀렉터는 표시하고, 본문은 스켈레톤으로 채운다.
  Widget _buildLoadingWithSelector() {
    return Column(
      children: [
        _buildHeader(),
        _buildMemberSelector(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, __) => const VideoCardSkeleton(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final isHoneyz = globalController.selectedGroup.value == 'honeyz';
    final members = youtubeController.currentMembers;
    final selectedKey = youtubeController.effectiveSelectedMemberKey;
    final selectedIndex = members.indexWhere((m) => m.key == selectedKey);
    final memberName =
        selectedIndex >= 0 ? members[selectedIndex].name : 'YouTube';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      child: Row(
        children: [
          // YouTube 아이콘
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  youtubeRed.withAlpha(30),
                  youtubeRed.withAlpha(50),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: youtubeRed.withAlpha(30),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.play_circle_filled_rounded,
              color: youtubeRed,
              size: 40,
            ),
          ),
          const SizedBox(width: 20),
          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memberName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.textMain,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isHoneyz ? "허니즈" : "아카시아"} YouTube',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textSub,
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

  Widget _buildMemberSelector() {
    final members = youtubeController.currentMembers;
    final selectedKey = youtubeController.effectiveSelectedMemberKey;

    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          final isSelected = member.key == selectedKey;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TapSemantics(
                selected: isSelected,
                child: GestureDetector(
                  onTap: () {
                    youtubeController.selectMember(member.key);
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(0);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? youtubeRed : context.surface,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color:
                            isSelected ? youtubeRed : youtubeRed.withAlpha(50),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: youtubeRed.withAlpha(60),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: AssetImage(member.profileAssetPath),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          member.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : context.textMain,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          );
        },
      ),
    );
  }

  Widget _buildVideoCount() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.play_circle_outline_rounded,
              size: 16,
              color: youtubeRed,
            ),
            const SizedBox(width: 6),
            Text(
              '${youtubeController.videoList.length}개 영상',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        _buildHeader(),
        _buildMemberSelector(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: context.surfaceAlt,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 50,
                      color: context.textSub.withAlpha(100),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '오류가 발생했습니다',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    youtubeController.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textSub,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: youtubeController.loadVideos,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('다시 시도'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: youtubeRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
