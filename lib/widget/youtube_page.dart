import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/controllers/youtube_controller.dart';
import 'package:projecti_fan_app/widget/audio_common.dart';
import 'package:projecti_fan_app/widget/components/youtube_video_card.dart';

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
    _scrollController.addListener(_onScroll);
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 스크롤이 끝에 도달하면 추가 로드
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      youtubeController.loadMoreVideos();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AudioTheme.backgroundLight,
            AudioTheme.backgroundMid,
            AudioTheme.background,
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
          // 로딩 인디케이터 (추가 로드)
          if (youtubeController.isLoadingMore.value)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    color: youtubeRed,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          // 더 이상 데이터 없음
          if (!youtubeController.hasMore &&
              youtubeController.videoList.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    '모든 동영상을 불러왔습니다',
                    style: TextStyle(
                      fontSize: 13,
                      color: AudioTheme.textSecondary.withAlpha(150),
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

  /// 로딩 중일 때도 멤버 셀렉터는 표시
  Widget _buildLoadingWithSelector() {
    return Column(
      children: [
        _buildHeader(),
        _buildMemberSelector(),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(
              color: youtubeRed,
              strokeWidth: 3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final isHoneyz = globalController.selectedGroup.value == 'honeyz';
    final memberKeys = youtubeController.currentMemberKeys;
    final memberNames = youtubeController.currentMemberNames;
    final selectedKey = youtubeController.effectiveSelectedMemberKey;
    final selectedIndex = memberKeys.indexOf(selectedKey);
    final memberName =
        selectedIndex >= 0 ? memberNames[selectedIndex] : 'YouTube';

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
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AudioTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isHoneyz ? "허니즈" : "아카시아"} YouTube',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AudioTheme.textSecondary,
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
    final memberKeys = youtubeController.currentMemberKeys;
    final memberNames = youtubeController.currentMemberNames;
    final assetNames = youtubeController.currentAssetNames;
    final selectedKey = youtubeController.effectiveSelectedMemberKey;
    final isHoneyz = globalController.selectedGroup.value == 'honeyz';
    final groupFolder = isHoneyz ? 'honeyz' : 'acaxia';

    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: memberKeys.length,
        itemBuilder: (context, index) {
          final isSelected = memberKeys[index] == selectedKey;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                youtubeController.selectMember(memberKeys[index]);
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(0);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? youtubeRed : AudioTheme.surface,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? youtubeRed : youtubeRed.withAlpha(50),
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
                      backgroundImage: AssetImage(
                        'assets/$groupFolder/${assetNames[index]}_profile.png',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      memberNames[index],
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : AudioTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
          color: AudioTheme.surfaceTint,
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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AudioTheme.textPrimary,
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
                      color: AudioTheme.surfaceTint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 50,
                      color: AudioTheme.textSecondary.withAlpha(100),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '오류가 발생했습니다',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AudioTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    youtubeController.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AudioTheme.textSecondary,
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
