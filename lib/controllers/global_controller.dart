import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:projecti_fan_app/model/live_check_model.dart';
import 'package:projecti_fan_app/model/schedule_model.dart';
import 'package:projecti_fan_app/model/streamer_model.dart';

class GlobalController extends GetxController {
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  RxString selectedGroup = ''.obs;
  RxList<String> selectedMusicGroup = <String>['all', 'honeyz', 'acaxia'].obs;

  RxString selectedMusicGroupString = 'all'.obs;

  RxList<ScheduleModel> honeyzScheduleList = <ScheduleModel>[].obs;
  RxList<ScheduleModel> acaxiaScheduleList = <ScheduleModel>[].obs;
  RxList<StreamerModel> honeyz = <StreamerModel>[].obs;
  RxList<StreamerModel> acaxia = <StreamerModel>[].obs;
  RxList<LiveCheckModel> honeyzliveCheckList = <LiveCheckModel>[].obs;
  RxList<LiveCheckModel> acaxialiveCheckList = <LiveCheckModel>[].obs;

  List<String> honeyzSequence = [
    "honeychurros",
    "ayauke",
    "damyui",
    "ddddragon",
    "ohwayo",
    "mangnae",
  ];

  List<String> acaxiaSequence = [
    "popopopo",
    "violetaMone",
    "blaireRose",
    "hasiyo",
    "ryushiho",
  ];

  List<String> honeyzNameList = [
    "허니츄러스",
    "아야",
    "담유이",
    "디디디용",
    "오화요",
    "망내",
  ];

  List<String> acaxiaNameList = [
    "포포포포",
    "비올레타 모네",
    "블레어 로즈",
    "하시요",
    "류시호",
  ];

  List<String> honeyzAssetName = [
    "honeychurros",
    "ayauke",
    "damyui",
    "ddddragon",
    "ohwayo",
    "mangnae"
  ];

  List<String> acaxiaAssetName = [
    "popopopo",
    "violetaMone",
    "blaireRose",
    "hasiyo",
    "ryushiho",
  ];

  List<String> honeyzBrodcastIDList = [
    "c0d9723cbb75dc223c6aa8a9d4f56002",
    "abe8aa82baf3d3ef54ad8468ee73e7fc",
    "b82e8bc2505e37156b2d1140ba1fc05c",
    "798e100206987b59805cfb75f927e965",
    "65a53076fe1a39636082dd6dba8b8a4b",
    "bd07973b6021d72512240c01a386d5c9",
  ];

  List<String> acaxiaBrodcastIDList = [
    "3e3781d3bd20dadc2f6f6d5d30091195",
    "5c897b3e639045ca6e314bbaff991f73",
    "dae2de8eaa005a59163f2e4c045e1aa1",
    "b33c957eac9335d38e4043c3dca97675",
    "f36320c432d9f06095ce2cfbbf681c26",
  ];

  Future<List<ScheduleModel>> loadScheduleFireStore(
      {required List<String> sequence}) async {
    if (selectedGroup.value == 'honeyz') {
      if (honeyzScheduleList.isEmpty) {
        QuerySnapshot<Map<String, dynamic>> snapshot =
            await _fireStore.collection("schedule").get();

        for (int i = 0; i < sequence.length; i++) {
          for (var snapshot in snapshot.docs) {
            if (sequence[i] == snapshot.id) {
              honeyzScheduleList.add(ScheduleModel.fromJson(snapshot.data()));
            }
          }
        }
      }
      return honeyzScheduleList;
    } else if (selectedGroup.value == 'acaxia') {
      if (acaxiaScheduleList.isEmpty) {
        QuerySnapshot<Map<String, dynamic>> snapshot =
            await _fireStore.collection("schedule_acaxia").get();

        for (int i = 0; i < sequence.length; i++) {
          for (var snapshot in snapshot.docs) {
            if (sequence[i] == snapshot.id) {
              acaxiaScheduleList.add(ScheduleModel.fromJson(snapshot.data()));
            }
          }
        }
      }
      return acaxiaScheduleList;
    }

    return [];
  }

  Future<List<StreamerModel>> loadStreamerFireStore() async {
    if (selectedGroup.value == 'honeyz') {
      if (honeyz.isEmpty) {
        QuerySnapshot<Map<String, dynamic>> snapshot =
            await _fireStore.collection("honeyz").get();

        for (int i = 0; i < honeyzSequence.length; i++) {
          for (var snapshot in snapshot.docs) {
            if (honeyzSequence[i] == snapshot.id) {
              honeyz.add(StreamerModel.fromJson(snapshot.data()));
            }
          }
        }
      }
      return honeyz;
    } else if (selectedGroup.value == 'acaxia') {
      if (acaxia.isEmpty) {
        QuerySnapshot<Map<String, dynamic>> snapshot =
            await _fireStore.collection("acaxia").get();

        for (int i = 0; i < acaxiaSequence.length; i++) {
          for (var snapshot in snapshot.docs) {
            if (acaxiaSequence[i] == snapshot.id) {
              acaxia.add(StreamerModel.fromJson(snapshot.data()));
            }
          }
        }
      }
      return acaxia;
    }

    return [];
  }

  Future<LiveCheckModel?> _fetchLiveStatus(String broadcastId) async {
    final url = Uri.parse(
        'https://api.chzzk.naver.com/polling/v2/channels/$broadcastId/live-status');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(decodedBody);
        return LiveCheckModel.fromJson(data['content']);
      }
    } catch (_) {
      // error handled silently
    }
    return null;
  }

  Future<List<LiveCheckModel>> liveCheck() async {
    if (selectedGroup.value == 'honeyz') {
      if (honeyzliveCheckList.isEmpty) {
        final results = await Future.wait(
          honeyzBrodcastIDList.map((id) => _fetchLiveStatus(id)),
        );
        for (final result in results) {
          if (result != null) {
            honeyzliveCheckList.add(result);
          }
        }
      }
      return honeyzliveCheckList;
    } else if (selectedGroup.value == 'acaxia') {
      if (acaxialiveCheckList.isEmpty) {
        final results = await Future.wait(
          acaxiaBrodcastIDList.map((id) => _fetchLiveStatus(id)),
        );
        for (final result in results) {
          if (result != null) {
            acaxialiveCheckList.add(result);
          }
        }
      }
      return acaxialiveCheckList;
    }

    return [];
  }
}
