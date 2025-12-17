import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:projecti_fan_app/controllers/favorite_controller.dart';
import 'package:projecti_fan_app/controllers/music_controller.dart';
import 'package:projecti_fan_app/model/music_model.dart';
import 'package:projecti_fan_app/widget/audio_common.dart';

class MusicCard extends StatelessWidget {
  final MusicModel musicModel;
  final int index;

  const MusicCard({
    super.key,
    required this.musicModel,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final musicController = Get.find<MusicController>();
    final favoriteController = Get.find<FavoriteController>();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push('/audioPage', extra: musicModel);
          musicController.musicIndex.value = index;
        },
        borderRadius: BorderRadius.circular(16),
        child: Obx(() {
          final isFavorite = favoriteController.isFavorite(musicModel);

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AudioTheme.surface.withAlpha(220),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFavorite
                    ? AudioTheme.primary.withAlpha(80)
                    : AudioTheme.primary.withAlpha(30),
                width: isFavorite ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isFavorite
                      ? AudioTheme.primary.withAlpha(25)
                      : AudioTheme.primary.withAlpha(15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // 썸네일 with favorite badge
                Stack(
                  children: [
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
                    // 즐겨찾기 뱃지
                    if (isFavorite)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AudioTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AudioTheme.surface,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AudioTheme.primary.withAlpha(60),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                // 곡 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
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
                          ),
                        ],
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
          );
        }),
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
