import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:projecti_fan_app/model/group.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/widget/components/round_icon_button.dart';

/// 스케줄 상세 화면 인자.
///
/// 이미지 URL은 '?'/'&'를 포함할 수 있어(예: Storage의 `?alt=media&token=...`)
/// 쿼리 파라미터로 넘기면 URL이 잘려 이미지를 못 불러온다. go_router의 extra로
/// 통째로 전달해 인코딩 문제를 아예 없앤다.
typedef ScheduleDetailArgs = ({String imageURL, String name});

class ScheduleDetail extends StatelessWidget {
  final String? imageURL;
  final String? name;

  const ScheduleDetail({super.key, required this.imageURL, required this.name});

  @override
  Widget build(BuildContext context) {
    final globalController = Get.find<GlobalController>();
    final group = globalController.currentGroup;
    final themeColor = AppColors.group(group);
    // 글자·아이콘용 (배경 틴트·그림자는 themeColor 유지)
    final inkColor = switch (group) {
      Group.honeyz => AppColors.honeyz,
      Group.acaxia => context.acaxiaInk,
    };

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          children: [
            // 커스텀 앱바
            _buildAppBar(context, themeColor, inkColor),
            // 이미지 영역
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withAlpha(20),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: (imageURL == null || imageURL!.isEmpty)
                      ? _buildUnavailable(context)
                      : ExtendedImage.network(
                          imageURL!,
                          fit: BoxFit.contain,
                          mode: ExtendedImageMode.gesture,
                          initGestureConfigHandler: (state) => GestureConfig(
                            minScale: 1.0,
                            maxScale: 5.0,
                            speed: 1.0,
                            initialScale: 1.0,
                            inPageView: false,
                          ),
                          cache: true,
                          loadStateChanged: (ExtendedImageState state) {
                            switch (state.extendedImageLoadState) {
                              case LoadState.loading:
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: inkColor,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        '스케줄을 불러오는 중...',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: context.textFaint,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              case LoadState.failed:
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported_rounded,
                                        size: 48,
                                        color: context.textFaint,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '이미지를 불러올 수 없습니다',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: context.textFaint,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      TextButton.icon(
                                        onPressed: () {
                                          state.reLoadImage();
                                        },
                                        icon: Icon(
                                          Icons.refresh_rounded,
                                          size: 18,
                                          color: inkColor,
                                        ),
                                        label: Text(
                                          '다시 시도',
                                          style: TextStyle(
                                            color: inkColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
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
            // 하단 힌트
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pinch_rounded,
                    size: 18,
                    color: context.textFaint,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '핀치하여 확대/축소',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textFaint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 인자 없이 진입해(복원·딥링크) 보여줄 이미지가 없을 때의 화면.
  Widget _buildUnavailable(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_rounded,
            size: 48,
            color: context.textFaint,
          ),
          const SizedBox(height: 12),
          Text(
            '스케줄 정보를 불러올 수 없습니다',
            style: TextStyle(
              fontSize: 14,
              color: context.textFaint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Color themeColor, Color inkColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 뒤로가기 버튼
          RoundIconButton.back(context, color: inkColor),
          const SizedBox(width: 16),
          // 타이틀
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textMain,
                  ),
                ),
                Text(
                  '주간 스케줄',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textFaint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // 그룹 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: themeColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: inkColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'SCHEDULE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: inkColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
