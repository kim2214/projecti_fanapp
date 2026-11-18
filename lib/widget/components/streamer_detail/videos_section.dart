import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/notification_controller.dart';
import 'package:projecti_fan_app/model/group.dart';
import 'package:projecti_fan_app/model/notification_target.dart';
import 'package:projecti_fan_app/model/youtube_video_model.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:projecti_fan_app/widget/components/status_message.dart';
import 'package:projecti_fan_app/widget/components/youtube_video_card.dart';
import 'package:projecti_fan_app/widget/home/home_section_title.dart';

/// 최신 YouTube 영상 섹션 — 상위 3개를 보여주고, "더보기"는 이 멤버를 고른
/// YouTube 탭으로 넘긴다. 조회 실패 시 [onRetry]로 재시도한다(빈 목록은 재시도
/// 없이 "아직 영상이 없어요"로 표시).
class StreamerVideosSection extends StatelessWidget {
  final Group group;
  final String memberKey;
  final Future<List<YouTubeVideoModel>>? future;
  final VoidCallback onRetry;

  const StreamerVideosSection({
    super.key,
    required this.group,
    required this.memberKey,
    required this.future,
    required this.onRetry,
  });

  void _openAllVideos() {
    Get.find<NotificationController>().pendingTarget.value = NotificationTarget(
      type: NotificationTargetType.videos,
      group: group,
      memberKey: memberKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final future = this.future;
    if (future == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.play_circle_fill_rounded,
                    size: 20, color: Color(0xFFFF0000)),
                const SizedBox(width: 8),
                Text(
                  '최신 영상',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textMain,
                  ),
                ),
                const Spacer(),
                // 여기는 3개만 보인다 — 이 멤버를 고른 YouTube 탭으로 넘긴다.
                // 그룹 전환·화면 정리는 기본 화면이 맡는다(알림 탭과 같은 경로).
                HomeMoreLink('더보기', onTap: _openAllVideos),
              ],
            ),
          ),
          FutureBuilder<List<YouTubeVideoModel>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF0000),
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              final videos = snapshot.data ?? [];
              // 실패는 나갔다 들어오지 않아도 여기서 다시 시도할 수 있게 한다.
              // 빈 목록은 채널에 영상이 없는 경우라 재시도를 붙이지 않는다.
              if (snapshot.hasError || videos.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: snapshot.hasError
                        ? StatusMessage(
                            compact: true,
                            icon: Icons.wifi_off_rounded,
                            iconColor:
                                context.groupInk(group).withAlpha(150),
                            title: '최신 영상을 불러오지 못했어요',
                            onRetry: onRetry,
                            actionColor: context.groupInk(group),
                          )
                        : StatusMessage(
                            compact: true,
                            icon: Icons.videocam_off_rounded,
                            iconColor:
                                context.groupInk(group).withAlpha(150),
                            title: '아직 올라온 영상이 없어요',
                          ),
                  ),
                );
              }
              final top = videos.take(3).toList();
              return Column(
                children: [
                  for (int i = 0; i < top.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: YouTubeVideoCard(video: top[i]),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
