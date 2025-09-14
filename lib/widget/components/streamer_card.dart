import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyz_fan_app/controllers/global_controller.dart';
import 'package:honeyz_fan_app/font_style_sheet.dart';
import 'package:honeyz_fan_app/model/streamer_model.dart';
import 'package:honeyz_fan_app/model/live_check_model.dart';

class StreamerCard extends StatelessWidget {
  final int index;
  final StreamerModel streamer;
  final LiveCheckModel status;

  const StreamerCard({
    super.key,
    required this.index,
    required this.streamer,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final globalController = Get.find<GlobalController>();

    return InkWell(
      onTap: () {
        context.push('/streamerDetail', extra: streamer);
      },
      child: Column(
        children: [
          Obx(
            () => Image.asset(globalController.selectedGroup.value == 'honeyz'
                ? 'assets/honeyz/${globalController.honeyzAssetName[index]}_profile.png'
                : 'assets/acaxia/${globalController.acaxiaAssetName[index]}_profile.png'),
          ),
          SizedBox(
            height: 20,
          ),
          Obx(
            () => Text(
              globalController.selectedGroup.value == 'honeyz'
                  ? globalController.honeyzNameList[index]
                  : globalController.acaxiaNameList[index],
              style: FontStyleSheet.streamerCardItem,
            ),
          ),
          Visibility(
            visible: status.status! == 'OPEN',
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  status.liveTitle!,
                  style: FontStyleSheet.streamerCardItem,
                  textAlign: TextAlign.center,
                ),
                Text(
                  "LIVE",
                  style: FontStyleSheet.streamerCardItem.copyWith(
                    color: Colors.lightGreenAccent.withOpacity(1.0),
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
