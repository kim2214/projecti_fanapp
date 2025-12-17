import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:projecti_fan_app/controllers/favorite_controller.dart';
import 'package:projecti_fan_app/controllers/music_controller.dart';
import 'package:projecti_fan_app/model/music_model.dart';
import 'package:projecti_fan_app/widget/audio_common.dart';

class FavoritesPageWidget extends StatelessWidget {
  const FavoritesPageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteController = Get.find<FavoriteController>();

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
      child: Obx(() {
        if (favoriteController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: AudioTheme.primary,
              strokeWidth: 3,
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            // 헤더 영역
            SliverToBoxAdapter(
              child: _buildHeader(favoriteController),
            ),
            // 즐겨찾기 개수
            SliverToBoxAdapter(
              child: _buildSongCount(favoriteController),
            ),
            // 즐겨찾기가 비어있을 때
            if (favoriteController.favoriteList.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(),
              )
            else
              // 즐겨찾기 리스트
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _FavoriteCard(
                          musicModel: favoriteController.favoriteList[index],
                          index: index,
                          onRemove: () {
                            favoriteController.removeFavorite(
                                favoriteController.favoriteList[index]);
                          },
                        ),
                      );
                    },
                    childCount: favoriteController.favoriteList.length,
                  ),
                ),
              ),
            // 하단 여백
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(FavoriteController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      child: Row(
        children: [
          // 즐겨찾기 아이콘
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AudioTheme.primary.withAlpha(40),
                  AudioTheme.primaryDark.withAlpha(60),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AudioTheme.primary.withAlpha(40),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AudioTheme.primary,
              size: 40,
            ),
          ),
          const SizedBox(width: 20),
          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '즐겨찾기',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AudioTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'My Favorites',
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

  Widget _buildSongCount(FavoriteController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AudioTheme.surfaceTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  size: 16,
                  color: AudioTheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${controller.favoriteList.length}곡',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AudioTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // 전체 삭제 버튼
          if (controller.favoriteList.isNotEmpty)
            GestureDetector(
              onTap: () => _showClearAllDialog(controller),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withAlpha(50),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Colors.red[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '전체 삭제',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[400],
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

  void _showClearAllDialog(FavoriteController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              '전체 삭제',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Text(
          '즐겨찾기 목록을 모두 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              '취소',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              controller.clearAllFavorites();
              Get.back();
            },
            child: const Text(
              '삭제',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
              Icons.favorite_border_rounded,
              size: 50,
              color: AudioTheme.textSecondary.withAlpha(100),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '즐겨찾기가 비어있습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AudioTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '음악 재생 화면에서 하트를 눌러\n좋아하는 곡을 추가해보세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AudioTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final MusicModel musicModel;
  final int index;
  final VoidCallback onRemove;

  const _FavoriteCard({
    required this.musicModel,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final musicController = Get.find<MusicController>();

    return Dismissible(
      key: Key(musicModel.musicURL ?? index.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.red,
          size: 28,
        ),
      ),
      onDismissed: (_) => onRemove(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // musicList에서 해당 곡의 인덱스 찾기
            final musicIndex = musicController.musicList.indexWhere(
              (m) => m.musicURL == musicModel.musicURL,
            );
            if (musicIndex != -1) {
              musicController.musicIndex.value = musicIndex;
            }
            context.push('/audioPage', extra: musicModel);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AudioTheme.surface.withAlpha(220),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AudioTheme.primary.withAlpha(30),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AudioTheme.primary.withAlpha(15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // 썸네일
                Hero(
                  tag: 'album_art_${musicModel.title}',
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AudioTheme.primary.withAlpha(40),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ExtendedImage.network(
                        musicModel.thumbnail ?? '',
                        fit: BoxFit.cover,
                        cache: true,
                        loadStateChanged: (ExtendedImageState state) {
                          switch (state.extendedImageLoadState) {
                            case LoadState.loading:
                              return Container(
                                color: AudioTheme.surfaceTint,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AudioTheme.primary,
                                    ),
                                  ),
                                ),
                              );
                            case LoadState.failed:
                              return Container(
                                color: AudioTheme.surfaceTint,
                                child: const Icon(
                                  Icons.music_note_rounded,
                                  color: AudioTheme.primary,
                                  size: 24,
                                ),
                              );
                            case LoadState.completed:
                              return null;
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // 곡 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        musicModel.title ?? 'Unknown Title',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AudioTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // 그룹 뱃지
                          if (musicModel.group != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: _getGroupColor(musicModel.group!)
                                    .withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getGroupLabel(musicModel.group!),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _getGroupColor(musicModel.group!),
                                ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              musicModel.name ?? 'Unknown Artist',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AudioTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 즐겨찾기 아이콘 & 재생 버튼
                Row(
                  children: [
                    // 즐겨찾기 표시
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AudioTheme.primary.withAlpha(20),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: AudioTheme.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 재생 버튼
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AudioTheme.surfaceTint,
                        border: Border.all(
                          color: AudioTheme.primary.withAlpha(50),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: AudioTheme.primary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getGroupColor(String group) {
    if (group.contains('honeyz')) {
      return const Color(0xFFFF5E88); // 핑크
    } else if (group.contains('acaxia')) {
      return const Color(0xFF8B5CF6); // 보라
    }
    return AudioTheme.primary; // 기본 시안
  }

  String _getGroupLabel(String group) {
    if (group.contains('honeyz')) {
      return '허니즈';
    } else if (group.contains('acaxia')) {
      return '아카시아';
    }
    return '전체';
  }
}
