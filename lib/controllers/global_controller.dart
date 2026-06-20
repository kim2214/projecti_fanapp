import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:projecti_fan_app/model/birthday_entry.dart';
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

  /// 그룹별 스케줄 컬렉션 이름. (멤버/스트리머 컬렉션 이름은 그룹 이름과 동일)
  static const Map<String, String> _scheduleCollection = {
    'honeyz': 'schedule',
    'acaxia': 'schedule_acaxia',
  };

  RxList<ScheduleModel> _scheduleCacheOf(String group) =>
      group == 'honeyz' ? honeyzScheduleList : acaxiaScheduleList;
  RxList<StreamerModel> _streamerCacheOf(String group) =>
      group == 'honeyz' ? honeyz : acaxia;
  RxList<LiveCheckModel> _liveCacheOf(String group) =>
      group == 'honeyz' ? honeyzliveCheckList : acaxialiveCheckList;

  /// 컬렉션의 모든 문서를 문서 ID(= 멤버 key) 기준 Map으로 반환.
  /// 멤버-문서 매칭을 O(n²) 중첩 루프 대신 O(1) 조회로 처리하기 위함.
  Future<Map<String, Map<String, dynamic>>> _fetchDocsByKey(
      String collection) async {
    final snapshot = await _fireStore.collection(collection).get();
    return {for (final doc in snapshot.docs) doc.id: doc.data()};
  }

  Future<List<ScheduleModel>> loadScheduleFireStore(
      {bool forceRefresh = false}) async {
    final group = selectedGroup.value;
    final collection = _scheduleCollection[group];
    if (collection == null) return [];

    final cache = _scheduleCacheOf(group);
    if (forceRefresh || cache.isEmpty) {
      final docsByKey = await _fetchDocsByKey(collection);
      // 카탈로그 순서대로, 문서가 있는 멤버만 (스케줄 미등록 멤버는 제외)
      cache.value = [
        for (final member in membersOf(group))
          if (docsByKey[member.key] != null)
            ScheduleModel.fromJson(docsByKey[member.key]!),
      ];
    }
    return cache;
  }

  Future<List<StreamerModel>> loadStreamerFireStore(
      {bool forceRefresh = false}) async {
    final group = selectedGroup.value;
    if (group != 'honeyz' && group != 'acaxia') return [];

    final cache = _streamerCacheOf(group);
    if (forceRefresh || cache.isEmpty) {
      // 스트리머 컬렉션 이름은 그룹 이름과 동일하다.
      final docsByKey = await _fetchDocsByKey(group);
      // 카탈로그(membersOf)와 순서·길이가 1:1 정렬되도록 key로 매칭한다.
      // 문서가 없는 멤버는 빈 모델로 채워 인덱스 정렬을 보장한다 — UI는 이름/프로필을
      // 카탈로그에서 가져오므로(group_page) 빈 모델도 안전하게 렌더된다.
      cache.value = [
        for (final member in membersOf(group))
          docsByKey[member.key] != null
              ? StreamerModel.fromJson(docsByKey[member.key]!)
              : StreamerModel.empty(),
      ];
    }
    return cache;
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
      // 비공식 polling 엔드포인트라 응답 형식이 바뀌면 무증상 실패할 수 있어 기록한다.
      developer.log(
        'chzzk 라이브 상태 조회 실패 (HTTP ${response.statusCode}): $broadcastId',
        name: 'GlobalController',
      );
    } catch (e, st) {
      developer.log(
        'chzzk 라이브 상태 조회 예외: $broadcastId',
        name: 'GlobalController',
        error: e,
        stackTrace: st,
      );
    }
    return null;
  }

  Future<List<LiveCheckModel>> liveCheck({bool forceRefresh = false}) async {
    final group = selectedGroup.value;
    if (group != 'honeyz' && group != 'acaxia') return [];

    final cache = _liveCacheOf(group);
    if (forceRefresh || cache.isEmpty) {
      await refreshLiveStatus();
    }
    return cache;
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

    final liveCheckList = _liveCacheOf(group);

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

  /// 지정 그룹의 다가오는 생일 (가까운 순). birthday 미설정 멤버는 제외.
  /// Member(이름/에셋)와 StreamerModel(생일)을 인덱스로 매칭한다.
  List<BirthdayEntry> upcomingBirthdays(String group) {
    final members = membersOf(group);
    final streamers = group == 'honeyz' ? honeyz : acaxia;
    final count =
        members.length < streamers.length ? members.length : streamers.length;

    final entries = <BirthdayEntry>[];
    for (int i = 0; i < count; i++) {
      final days = streamers[i].daysUntilBirthday;
      final label = streamers[i].birthdayLabel;
      if (days == null || label == null) continue;
      entries.add(BirthdayEntry(
        memberName: members[i].name,
        assetPath: members[i].profileAssetPath,
        daysUntil: days,
        dateLabel: label,
      ));
    }

    entries.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
    return entries;
  }
}
