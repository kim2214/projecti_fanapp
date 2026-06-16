import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:projecti_fan_app/model/live_check_model.dart';
import 'package:projecti_fan_app/model/live_member_entry.dart';
import 'package:projecti_fan_app/model/schedule_model.dart';
import 'package:projecti_fan_app/model/streamer_model.dart';

class GlobalController extends GetxController {
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  // 라이브 상태 주기 갱신
  static const Duration _liveRefreshInterval = Duration(minutes: 2);
  Timer? _liveRefreshTimer;
  AppLifecycleListener? _lifecycleListener;

  @override
  void onInit() {
    super.onInit();

    // 주기적으로 양쪽 그룹 라이브 상태 갱신 (통합 LIVE 화면 대응)
    _liveRefreshTimer = Timer.periodic(
      _liveRefreshInterval,
      (_) => refreshAllLiveStatus(),
    );

    // 앱이 포그라운드로 복귀하면 즉시 갱신
    _lifecycleListener = AppLifecycleListener(
      onResume: refreshAllLiveStatus,
    );
  }

  @override
  void onClose() {
    _liveRefreshTimer?.cancel();
    _lifecycleListener?.dispose();
    super.onClose();
  }

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
      {required List<String> sequence, bool forceRefresh = false}) async {
    if (selectedGroup.value == 'honeyz') {
      if (forceRefresh || honeyzScheduleList.isEmpty) {
        QuerySnapshot<Map<String, dynamic>> snapshot =
            await _fireStore.collection("schedule").get();

        final List<ScheduleModel> loaded = [];
        for (int i = 0; i < sequence.length; i++) {
          for (var snapshot in snapshot.docs) {
            if (sequence[i] == snapshot.id) {
              loaded.add(ScheduleModel.fromJson(snapshot.data()));
            }
          }
        }
        honeyzScheduleList.value = loaded;
      }
      return honeyzScheduleList;
    } else if (selectedGroup.value == 'acaxia') {
      if (forceRefresh || acaxiaScheduleList.isEmpty) {
        QuerySnapshot<Map<String, dynamic>> snapshot =
            await _fireStore.collection("schedule_acaxia").get();

        final List<ScheduleModel> loaded = [];
        for (int i = 0; i < sequence.length; i++) {
          for (var snapshot in snapshot.docs) {
            if (sequence[i] == snapshot.id) {
              loaded.add(ScheduleModel.fromJson(snapshot.data()));
            }
          }
        }
        acaxiaScheduleList.value = loaded;
      }
      return acaxiaScheduleList;
    }

    return [];
  }

  Future<List<StreamerModel>> loadStreamerFireStore(
      {bool forceRefresh = false}) async {
    if (selectedGroup.value == 'honeyz') {
      if (forceRefresh || honeyz.isEmpty) {
        QuerySnapshot<Map<String, dynamic>> snapshot =
            await _fireStore.collection("honeyz").get();

        final List<StreamerModel> loaded = [];
        for (int i = 0; i < honeyzSequence.length; i++) {
          for (var snapshot in snapshot.docs) {
            if (honeyzSequence[i] == snapshot.id) {
              loaded.add(StreamerModel.fromJson(snapshot.data()));
            }
          }
        }
        honeyz.value = loaded;
      }
      return honeyz;
    } else if (selectedGroup.value == 'acaxia') {
      if (forceRefresh || acaxia.isEmpty) {
        QuerySnapshot<Map<String, dynamic>> snapshot =
            await _fireStore.collection("acaxia").get();

        final List<StreamerModel> loaded = [];
        for (int i = 0; i < acaxiaSequence.length; i++) {
          for (var snapshot in snapshot.docs) {
            if (acaxiaSequence[i] == snapshot.id) {
              loaded.add(StreamerModel.fromJson(snapshot.data()));
            }
          }
        }
        acaxia.value = loaded;
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

  Future<List<LiveCheckModel>> liveCheck({bool forceRefresh = false}) async {
    if (selectedGroup.value == 'honeyz') {
      if (forceRefresh || honeyzliveCheckList.isEmpty) {
        await refreshLiveStatus();
      }
      return honeyzliveCheckList;
    } else if (selectedGroup.value == 'acaxia') {
      if (forceRefresh || acaxialiveCheckList.isEmpty) {
        await refreshLiveStatus();
      }
      return acaxialiveCheckList;
    }

    return [];
  }

  /// 현재 선택된 그룹의 라이브 상태를 새로 조회해서 교체
  Future<void> refreshLiveStatus() async {
    await _refreshGroupLiveStatus(selectedGroup.value);
  }

  /// 양쪽 그룹(허니즈+아카시아)의 라이브 상태를 동시에 갱신 (통합 LIVE 화면용)
  Future<void> refreshAllLiveStatus() async {
    await Future.wait([
      _refreshGroupLiveStatus('honeyz'),
      _refreshGroupLiveStatus('acaxia'),
    ]);
  }

  /// 지정한 그룹의 라이브 상태를 새로 조회해서 교체
  Future<void> _refreshGroupLiveStatus(String group) async {
    if (group != 'honeyz' && group != 'acaxia') return;

    final broadcastIDList =
        group == 'honeyz' ? honeyzBrodcastIDList : acaxiaBrodcastIDList;
    final liveCheckList =
        group == 'honeyz' ? honeyzliveCheckList : acaxialiveCheckList;

    final results = await Future.wait(
      broadcastIDList.map((id) => _fetchLiveStatus(id)),
    );

    // 멤버 순서와 인덱스가 어긋나지 않도록 실패한 항목은 기본값으로 채움
    liveCheckList.value = [
      for (final result in results)
        result ?? LiveCheckModel(status: 'CLOSE', liveTitle: null),
    ];
  }

  /// 두 그룹을 통합한 현재 방송 중(LIVE) 멤버 목록.
  /// 시청자 수 내림차순으로 정렬되며, isLive인 멤버만 포함한다.
  List<LiveMemberEntry> get liveMembersAcrossGroups {
    final entries = <LiveMemberEntry>[];

    void collect(
      String group,
      List<LiveCheckModel> statuses,
      List<String> names,
      List<String> assets,
      List<String> ids,
    ) {
      // 리스트 길이가 어긋날 수 있으므로 최소 길이까지만 안전하게 순회
      final count = [statuses.length, names.length, assets.length, ids.length]
          .reduce((a, b) => a < b ? a : b);
      for (int i = 0; i < count; i++) {
        if (statuses[i].isLive) {
          entries.add(LiveMemberEntry(
            group: group,
            memberKey: assets[i],
            memberName: names[i],
            assetPath: 'assets/$group/${assets[i]}_profile.png',
            broadcastId: ids[i],
            status: statuses[i],
          ));
        }
      }
    }

    collect('honeyz', honeyzliveCheckList, honeyzNameList, honeyzAssetName,
        honeyzBrodcastIDList);
    collect('acaxia', acaxialiveCheckList, acaxiaNameList, acaxiaAssetName,
        acaxiaBrodcastIDList);

    // 시청자 수 내림차순 (null은 0으로 취급해 뒤로)
    entries.sort((a, b) => (b.status.concurrentUserCount ?? 0)
        .compareTo(a.status.concurrentUserCount ?? 0));

    return entries;
  }
}
