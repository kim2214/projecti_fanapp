import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:projecti_fan_app/model/youtube_video_model.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:projecti_fan_app/widget/audio_common.dart';

class YouTubeVideoCard extends StatelessWidget {
  final YouTubeVideoModel video;
  final int index;

  // YouTube 브랜드 색상
  static const Color youtubeRed = Color(0xFFFF0000);

  const YouTubeVideoCard({
    super.key,
    required this.video,
    required this.index,
  });

  Future<void> _openYouTube() async {
    final url = Uri.parse(video.youtubeUrl);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openYouTube,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.surface,
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
              // 썸네일 (16:9 비율)
              _buildThumbnail(context),
              const SizedBox(width: 14),
              // 비디오 정보
              Expanded(child: _buildVideoInfo(context)),
              // YouTube 재생 버튼
              _buildPlayButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    return Container(
      width: 120,
      height: 68, // 16:9 비율 (120 / 16 * 9 = 67.5)
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: youtubeRed.withAlpha(30),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExtendedImage.network(
              video.thumbnailUrl ?? '',
              fit: BoxFit.cover,
              cache: true,
              loadStateChanged: (ExtendedImageState state) {
                switch (state.extendedImageLoadState) {
                  case LoadState.loading:
                    return Container(
                      color: context.surfaceAlt,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: youtubeRed,
                          ),
                        ),
                      ),
                    );
                  case LoadState.failed:
                    return Container(
                      color: context.surfaceAlt,
                      child: const Icon(
                        Icons.play_circle_outline_rounded,
                        color: youtubeRed,
                        size: 32,
                      ),
                    );
                  case LoadState.completed:
                    return null;
                }
              },
            ),
            // 재생 오버레이
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withAlpha(30),
                      Colors.transparent,
                      Colors.black.withAlpha(30),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_filled_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 제목
        Text(
          video.title ?? 'Unknown Title',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.textMain,
            letterSpacing: -0.3,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        // 날짜 및 채널명
        Row(
          children: [
            // 날짜 뱃지
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: youtubeRed.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                video.relativeTime,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: youtubeRed.withAlpha(200),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 채널명
            Expanded(
              child: Text(
                video.channelTitle ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSub,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: _openYouTube,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: youtubeRed.withAlpha(15),
          border: Border.all(
            color: youtubeRed.withAlpha(40),
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: youtubeRed,
          size: 22,
        ),
      ),
    );
  }
}
