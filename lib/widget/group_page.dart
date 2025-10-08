import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:honeyz_fan_app/controllers/global_controller.dart';
import 'package:honeyz_fan_app/widget/components/streamer_card.dart';

class GroupPageWidget extends StatefulWidget {
  const GroupPageWidget({super.key});

  @override
  State<GroupPageWidget> createState() => _GroupPageWidgetState();
}

class _GroupPageWidgetState extends State<GroupPageWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final globalController = Get.find<GlobalController>();
    return Column(
      children: [
        Expanded(
          child: FutureBuilder(
            future: globalController.liveCheck(),
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
                return Column(
                  children: [
                    Obx(
                      () => Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Image.asset(
                          globalController.selectedGroup.value == 'honeyz'
                              ? 'assets/honeyz_logo.png'
                              : 'assets/acaxia_logo.png',
                        ),
                      ),
                    ),
                    Expanded(
                      child: Obx(
                        () => ListView.separated(
                          shrinkWrap: true,
                          itemCount:
                              globalController.selectedGroup.value == 'honeyz'
                                  ? globalController.honeyz.length
                                  : globalController.acaxia.length,
                          padding: EdgeInsets.all(15.0),
                          itemBuilder: (context, index) {
                            return globalController.selectedGroup.value ==
                                    'honeyz'
                                ? Container(
                                    margin:
                                        EdgeInsets.symmetric(vertical: 20.0),
                                    padding: EdgeInsets.all(20.0),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: globalController
                                                      .honeyzliveCheckList[
                                                          index]
                                                      .status ==
                                                  'OPEN'
                                              ? Colors.black
                                              : Colors.red,
                                          width: globalController
                                                      .honeyzliveCheckList[
                                                          index]
                                                      .status ==
                                                  'OPEN'
                                              ? 5.0
                                              : 0.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x0fff5e88)
                                              .withOpacity(1.0),
                                          offset: Offset(0.0, 0.0),
                                        )
                                      ],
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10.0),
                                      ),
                                    ),
                                    child: StreamerCard(
                                      index: index,
                                      streamer: globalController.honeyz[index],
                                      status: globalController
                                          .honeyzliveCheckList[index],
                                    ),
                                  )
                                : Container(
                                    margin:
                                        EdgeInsets.symmetric(vertical: 20.0),
                                    padding: EdgeInsets.all(20.0),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: globalController
                                                      .acaxialiveCheckList[
                                                          index]
                                                      .status ==
                                                  'OPEN'
                                              ? Colors.black
                                              : Colors.red,
                                          width: globalController
                                                      .acaxialiveCheckList[
                                                          index]
                                                      .status ==
                                                  'OPEN'
                                              ? 5.0
                                              : 0.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x0fff5e88)
                                              .withOpacity(1.0),
                                          offset: Offset(0.0, 0.0),
                                        )
                                      ],
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10.0),
                                      ),
                                    ),
                                    child: StreamerCard(
                                      index: index,
                                      streamer: globalController.acaxia[index],
                                      status: globalController
                                          .acaxialiveCheckList[index],
                                    ),
                                  );
                          },
                          separatorBuilder: (context, index) => SizedBox(
                            height: 30.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
