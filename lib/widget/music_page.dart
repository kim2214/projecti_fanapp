import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/controllers/music_controller.dart';
import 'package:projecti_fan_app/font_style_sheet.dart';
import 'package:projecti_fan_app/model/music_model.dart';
import 'package:projecti_fan_app/widget/components/music_card.dart';
import 'package:get/get.dart';

class MusicPageWidget extends StatefulWidget {
  const MusicPageWidget({super.key});

  @override
  State<MusicPageWidget> createState() => _MusicPageWidgetState();
}

class _MusicPageWidgetState extends State<MusicPageWidget>
    with AutomaticKeepAliveClientMixin {
  final musicController = Get.find<MusicController>();

  @override
  void initState() {
    super.initState();
  }

  Future<List<MusicModel>> _loadFirestore() async {
    FirebaseFirestore _firestore = FirebaseFirestore.instance;

    if (musicController.originMusicList.isEmpty) {
      QuerySnapshot<Map<String, dynamic>> _snapshot = await _firestore
          .collection("music")
          .orderBy('created_at', descending: false)
          .get();
      musicController.originMusicList.value =
          _snapshot.docs.map((e) => MusicModel.fromJson(e.data())).toList();
      musicController.musicList.value =
          _snapshot.docs.map((e) => MusicModel.fromJson(e.data())).toList();
    }

    return musicController.musicList;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    RxString? selectedValue = '전체(프로젝트아이)'.obs;

    List<String> items = ['전체(프로젝트아이)', '허니즈', '아카시아'];

    final globalController = Get.find<GlobalController>();

    return FutureBuilder(
      future: _loadFirestore(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        //해당 부분은 data를 아직 받아 오지 못했을때 실행되는 부분
        if (snapshot.hasData == false) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Color(0x0fff5e88).withOpacity(1.0),
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
          return Obx(
            () => Column(
              children: [
                globalController.selectedMusicGroupString.value == 'all'
                    ? Image.asset(
                        'assets/projecti_logo.png',
                        width: 150,
                        height: 150,
                      )
                    : globalController.selectedMusicGroupString.value ==
                            'honeyz'
                        ? Image.asset(
                            'assets/honeyz_logo.png',
                            width: 150,
                            height: 150,
                          )
                        : Image.asset(
                            'assets/acaxia_logo.png',
                            width: 150,
                            height: 150,
                          ),
                DropdownButton<String>(
                  // 초기값이 설정되지 않은 경우를 위해 value가 null일 수 있으므로 String? 타입 사용
                  value: selectedValue.value,
                  alignment: Alignment.center,
                  hint: const Text('그룹을 선택해 주세요'),
                  icon: const Icon(Icons.arrow_downward),

                  style: FontStyleSheet.musicArtistName
                      .copyWith(color: Colors.black),
                  underline: const SizedBox.shrink(),
                  onChanged: (String? newValue) {
                    // setState(() {
                    selectedValue.value = newValue!;
                    globalController.selectedMusicGroupString.value =
                        globalController
                            .selectedMusicGroup[items.indexOf(newValue)];

                    if (globalController
                            .selectedMusicGroup[items.indexOf(newValue)] ==
                        'all') {
                      musicController.musicList.value =
                          musicController.originMusicList;
                    } else {
                      musicController.musicList.value = musicController
                          .originMusicList
                          .where((music) => music.group!.contains(
                              globalController
                                  .selectedMusicGroup[items.indexOf(newValue)]))
                          .toList();
                    }
                  },
                  items: items.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    itemCount: musicController.musicList.length,
                    itemBuilder: (context, index) {
                      return Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(10.0),
                          ),
                        ),
                        child: MusicCard(
                          musicModel: musicController.musicList[index],
                          index: index,
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => SizedBox(
                      height: 30.0,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
