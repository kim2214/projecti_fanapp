import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyz_fan_app/controllers/global_controller.dart';
import 'package:honeyz_fan_app/font_style_sheet.dart';

class GroupSelectWidget extends StatelessWidget {
  const GroupSelectWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final globalController = Get.find<GlobalController>();

    return SafeArea(
      child: Scaffold(
        body: FutureBuilder(
          future: globalController.loadStreamerFireStore(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            //해당 부분은 data를 아직 받아 오지 못했을때 실행되는 부분
            if (snapshot.hasData == false) {
              return Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Color(0x0fff5e88).withOpacity(1.0),
                  ),
                ),
              );
            }
            //error가 발생하게 될 경우 반환하게 되는 부분
            else if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(fontSize: 15),
                ),
              );
            }
            // 데이터를 정상적으로 받아오게 되면 다음 부분을 실행
            else {
              return Center(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 1,
                        child: InkWell(
                          onTap: () async {
                            globalController.selectedGroup.value = 'honeyz';
                            await globalController
                                .loadScheduleFireStore(
                                    sequence: globalController.honeyzSequence)
                                .then(
                              (schedule) {
                                if (schedule.isNotEmpty) {
                                  context.push('/baseScreen');
                                }
                              },
                            );
                          },
                          child: Container(
                            height: double.infinity,
                            color: Color(0x0FFF5E88).withOpacity(1.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/honeyz_logo.png',
                                  width: 150.0,
                                  height: 150.0,
                                ),
                                Text(
                                  '허니즈',
                                  style: FontStyleSheet.basicText
                                      .copyWith(fontSize: 25.0),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: InkWell(
                          onTap: () async {
                            globalController.selectedGroup.value = 'acaxia';
                            await globalController
                                .loadScheduleFireStore(
                                    sequence: globalController.acaxiaSequence)
                                .then(
                              (schedule) {
                                if (schedule.isNotEmpty) {
                                  context.push('/baseScreen');
                                }
                              },
                            );
                          },
                          child: Container(
                            height: double.infinity,
                            color: Color(0x0FCCD1F9).withOpacity(1.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/acaxia_logo.png',
                                  width: 150.0,
                                  height: 150.0,
                                ),
                                Text(
                                  '아카시아',
                                  style: FontStyleSheet.basicText
                                      .copyWith(fontSize: 25.0),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
