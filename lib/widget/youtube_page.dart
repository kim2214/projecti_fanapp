import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  final ScrollController _scrollController = ScrollController();

  // YouTube 브랜드 색상
  static const Color youtubeRed = Color(0xFFFF0000);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 초기 로드
    if (youtubeController.videoList.isEmpty) {
      youtubeController.loadVideos();
    }
  }

  @override
  void dispose() {
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

  void _showChannelSettingsDialog() {
    final textController = TextEditingController(
      text: youtubeController.channelId.value,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: AudioTheme.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: youtubeRed.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.settings, color: youtubeRed, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              '채널 설정',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AudioTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'YouTube 채널 ID를 입력하세요',
              style: TextStyle(fontSize: 14, color: AudioTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              '채널 ID는 "UC"로 시작하는 24자리 문자열입니다.',
              style: TextStyle(
                fontSize: 12,
                color: AudioTheme.textSecondary.withAlpha(150),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              style: const TextStyle(
                color: AudioTheme.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'UC...',
                hintStyle: TextStyle(
                  color: AudioTheme.textSecondary.withAlpha(100),
                ),
                filled: true,
                fillColor: AudioTheme.surfaceTint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: youtubeRed, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '취소',
              style: TextStyle(
                color: AudioTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final newChannelId = textController.text.trim();
              if (newChannelId.isNotEmpty) {
                youtubeController.setChannelId(newChannelId);
              }
              Navigator.pop(context);
            },
            child: const Text(
              '저장',
              style: TextStyle(
                color: youtubeRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
      return const Center(
        child: CircularProgressIndicator(
          color: youtubeRed,
          strokeWidth: 3,
        ),
      );
    }

    // 에러 상태
    if (youtubeController.hasError.value &&
        youtubeController.videoList.isEmpty) {
      return _buildErrorState();
    }

    // 채널 ID 미설정
    if (youtubeController.channelId.value.isEmpty &&
        youtubeController.videoList.isEmpty) {
      return _buildEmptyChannelState();
    }

    return RefreshIndicator(
      onRefresh: youtubeController.refresh,
      color: youtubeRed,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 헤더
          SliverToBoxAdapter(child: _buildHeader()),
          // 비디오 개수 및 설정
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

  Widget _buildHeader() {
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YouTube',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AudioTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Video Collection',
                  style: TextStyle(
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

  Widget _buildVideoCount() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 비디오 개수
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AudioTheme.surfaceTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
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
          // 설정 버튼
          GestureDetector(
            onTap: _showChannelSettingsDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: youtubeRed.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: youtubeRed.withAlpha(40),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.settings_outlined,
                    size: 16,
                    color: youtubeRed.withAlpha(200),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '채널 설정',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: youtubeRed.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _showChannelSettingsDialog,
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: const Text('채널 설정'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AudioTheme.surfaceTint,
                    foregroundColor: AudioTheme.textPrimary,
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
                const SizedBox(width: 12),
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChannelState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: youtubeRed.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_circle_outline_rounded,
                size: 50,
                color: youtubeRed,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'YouTube 채널 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AudioTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '시청할 YouTube 채널 ID를 설정해주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AudioTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showChannelSettingsDialog,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('채널 설정하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: youtubeRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
