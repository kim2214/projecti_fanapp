import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:projecti_fan_app/model/live_check_model.dart';
import 'package:projecti_fan_app/model/live_member_entry.dart';
import 'package:projecti_fan_app/model/member.dart';
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

  // 멤버 정적 카탈로그 — 멤버 1명의 모든 메타데이터를 Member 객체 하나로 묶는다.
  // (기존 *Sequence/*NameList/*AssetName/*BrodcastIDList 병렬 리스트를 대체)
  static const List<Member> honeyzMembers = [
    Member(
        key: 'honeychurros',
        name: '허니츄러스',
        group: 'honeyz',
        chzzkBroadcastId: 'c0d9723cbb75dc223c6aa8a9d4f56002',
        youtubeChannelId: 'UCkQFRBUPh5mcF1kca4f_DvQ'),
    Member(
        key: 'ayauke',
        name: '아야',
        group: 'honeyz',
        chzzkBroadcastId: 'abe8aa82baf3d3ef54ad8468ee73e7fc',
        youtubeChannelId: 'UCZcjMonq-hln97npqkYdHjQ'),
    Member(
        key: 'damyui',
        name: '담유이',
        group: 'honeyz',
        chzzkBroadcastId: 'b82e8bc2505e37156b2d1140ba1fc05c',
        youtubeChannelId: 'UC_XRkKvydFB_wX1dlr7OHrg'),
    Member(
        key: 'ddddragon',
        name: '디디디용',
        group: 'honeyz',
        chzzkBroadcastId: '798e100206987b59805cfb75f927e965',
        youtubeChannelId: 'UCmNurVU0rTyYqU4W4N0Mbgg'),
    Member(
        key: 'ohwayo',
        name: '오화요',
        group: 'honeyz',
        chzzkBroadcastId: '65a53076fe1a39636082dd6dba8b8a4b',
        youtubeChannelId: 'UC1RdgfinRXTboGZLZ4xG5Aw'),
    Member(
        key: 'mangnae',
        name: '망내',
        group: 'honeyz',
        chzzkBroadcastId: 'bd07973b6021d72512240c01a386d5c9',
        youtubeChannelId: 'UCicn6yqObjHrCKWkKL70ALg'),
  ];

  static const List<Member> acaxiaMembers = [
    Member(
        key: 'popopopo',
        name: '포포포포',
        group: 'acaxia',
        chzzkBroadcastId: '3e3781d3bd20dadc2f6f6d5d30091195',
        youtubeChannelId: 'UCXE5gQZ5WIbtT6FJtG2g5ag'),
    Member(
        key: 'violetaMone',
        name: '비올레타 모네',
        group: 'acaxia',
        chzzkBroadcastId: '5c897b3e639045ca6e314bbaff991f73',
        youtubeChannelId: 'UC0dF0Yr7PVddxuIHp_xsFZg'),
    Member(
        key: 'blaireRose',
        name: '블레어 로즈',
        group: 'acaxia',
        chzzkBroadcastId: 'dae2de8eaa005a59163f2e4c045e1aa1',
        youtubeChannelId: 'UC4RqkMZg4xRy0gWizubvPLw'),
    Member(
        key: 'hasiyo',
        name: '하시요',
        group: 'acaxia',
        chzzkBroadcastId: 'b33c957eac9335d38e4043c3dca97675',
        youtubeChannelId: 'UCkmb3uZxHAx10m7QR8XJSpQ'),
    Member(
        key: 'ryushiho',
        name: '류시호',
        group: 'acaxia',
        chzzkBroadcastId: 'f36320c432d9f06095ce2cfbbf681c26',
        youtubeChannelId: 'UC-9fPSlVjMqG3zwbRT2XhXA'),
  ];

  /// 그룹별 멤버 목록
  List<Member> membersOf(String group) =>
      group == 'honeyz' ? honeyzMembers : acaxiaMembers;

  /// 두 그룹 합본 (통합 LIVE 등)
  List<Member> get allMembers => [...honeyzMembers, ...acaxiaMembers];

  Future<List<ScheduleModel>> loadScheduleFireStore(
      {bool forceRefresh = false}) async {
    final sequence = membersOf(selectedGroup.value).map((m) => m.key).toList();
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
        for (final member in honeyzMembers) {
          for (var snapshot in snapshot.docs) {
            if (member.key == snapshot.id) {
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
        for (final member in acaxiaMembers) {
          for (var snapshot in snapshot.docs) {
            if (member.key == snapshot.id) {
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

    final liveCheckList =
        group == 'honeyz' ? honeyzliveCheckList : acaxialiveCheckList;

    final results = await Future.wait(
      membersOf(group).map((m) => _fetchLiveStatus(m.chzzkBroadcastId)),
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

    void collect(List<Member> members, List<LiveCheckModel> statuses) {
      // 폴링 전이면 statuses가 비어 있을 수 있으므로 최소 길이까지만 안전하게 순회
      final count = members.length < statuses.length
          ? members.length
          : statuses.length;
      for (int i = 0; i < count; i++) {
        if (statuses[i].isLive) {
          final member = members[i];
          entries.add(LiveMemberEntry(
            group: member.group,
            memberKey: member.key,
            memberName: member.name,
            assetPath: member.profileAssetPath,
            broadcastId: member.chzzkBroadcastId,
            status: statuses[i],
          ));
        }
      }
    }

    collect(honeyzMembers, honeyzliveCheckList);
    collect(acaxiaMembers, acaxialiveCheckList);

    // 시청자 수 내림차순 (null은 0으로 취급해 뒤로)
    entries.sort((a, b) => (b.status.concurrentUserCount ?? 0)
        .compareTo(a.status.concurrentUserCount ?? 0));

    return entries;
  }
}
