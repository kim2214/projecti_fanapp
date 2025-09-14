import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyz_fan_app/controllers/global_controller.dart';

import '../font_style_sheet.dart';

class SchedulePageWidget extends StatefulWidget {
  const SchedulePageWidget({super.key});

  @override
  State<SchedulePageWidget> createState() => _SchedulePageWidgetState();
}

class _SchedulePageWidgetState extends State<SchedulePageWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final globalController = Get.find<GlobalController>();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 30.0),
          child: Text(
            globalController.selectedGroup.value == 'honeyz'
                ? "허니즈 맴버들의 주간 스케줄 표 입니다."
                : "아카시아 맴버들의 주간 스케줄 표 입니다.",
            style: FontStyleSheet.title,
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          itemCount: globalController.schedule.length,
          padding: EdgeInsets.all(15.0),
          itemBuilder: (context, index) {
            return SizedBox(
              height: 350,
              child: InkWell(
                onTap: () {
                  context.push(
                      '/scheduleDetail?url=${globalController.schedule[index].scheduleURL}&name=${globalController.selectedGroup.value == 'honeyz' ? globalController.honeyzNameList[index] : globalController.acaxiaNameList[index]}');
                },
                child: ScheduleCard(
                  imageURL: globalController.schedule[index].scheduleURL!,
                  index: index,
                ),
              ),
            );
          },
          separatorBuilder: (context, index) => SizedBox(
            height: 30.0,
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class ScheduleCard extends StatelessWidget {
  final String imageURL;
  final int index;

  const ScheduleCard({super.key, required this.imageURL, required this.index});

  @override
  Widget build(BuildContext context) {
    final globalController = Get.find<GlobalController>();

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(5.0)),
          border: Border.all(width: 2.0)),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Color(0x0fff5e88).withOpacity(1.0),
              ),
              child: Center(
                child: Text(
                  globalController.selectedGroup.value == 'honeyz'
                      ? globalController.honeyzNameList[index]
                      : globalController.acaxiaNameList[index],
                  style: FontStyleSheet.listItem,
                ),
              ),
            ),
          ),
          imageURL.isNotEmpty
              ? Expanded(
                  flex: 5,
                  child: ExtendedImage.network(
                    imageURL,
                    fit: BoxFit.fill,
                    mode: ExtendedImageMode.gesture, // 줌/팬 모드 활성화
                    initGestureConfigHandler: (state) => GestureConfig(
                      minScale: 1.0,
                      maxScale: 5.0,
                      speed: 1.0,
                      initialScale: 1.0,
                    ),
                  ))
              : Expanded(
                  flex: 5,
                  child: Center(
                    child: Text(
                        '금주의 ${globalController.selectedGroup.value == 'honeyz' ? globalController.honeyzNameList[index] : globalController.acaxiaNameList[index]}님은 방송이 없습니다.',
                        style: FontStyleSheet.listItem),
                  ),
                ),
        ],
      ),
    );
  }
}
