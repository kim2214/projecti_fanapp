import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:projecti_fan_app/model/birthday_entry.dart';
import 'package:projecti_fan_app/model/live_check_model.dart';
import 'package:projecti_fan_app/model/live_member_entry.dart';
import 'package:projecti_fan_app/model/member.dart';
import 'package:projecti_fan_app/model/schedule_model.dart';
import 'package:projecti_fan_app/model/streamer_model.dart';
import 'package:projecti_fan_app/utils/app_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlobalController extends GetxController {
  // 지연 초기화: 생성 시점에 Firebase에 접근하지 않으므로, 순수 로직(정렬/필터)
  // 테스트에서 Firebase 초기화 없이 컨트롤러를 만들 수 있다. 첫 Firestore 호출 시 init.
  late final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  // 라이브 상태 주기 갱신
  static const Duration _liveRefreshInterval = Duration(minutes: 2);

  // 네트워크가 멈췄을 때 무한 대기하지 않도록 하는 요청 타임아웃.
  // 2분마다 폴링되므로, 멈춘 요청이 다음 폴링과 겹쳐 쌓이는 것을 방지한다.
  static const Duration _requestTimeout = Duration(seconds: 8);

  // 서버(Cloud Function pollLiveStatus)가 1분 주기로 11명 상태를 집계하는 문서.
  // 클라는 이 문서를 우선 읽어 치지직 직접 폴링(클라 수 × 11요청)을 대체한다.
  static const String _liveStatusDocPath = 'live_status/current';

  // 집계 문서가 이보다 오래되면(서버 폴링 중단 의심) 치지직 직접 폴링으로 폴백한다.
  // 서버는 1분 주기라 정상이면 1분 미만이며, 몇 번 놓쳐도 견디도록 여유를 둔다.
  static const Duration _serverStatusMaxAge = Duration(minutes: 5);
  Timer? _liveRefreshTimer;
  AppLifecycleListener? _lifecycleListener;

  @override
  void onInit() {
    super.onInit();

    // 포그라운드 상태에서 주기적으로 양쪽 그룹 라이브 상태 갱신 (통합 LIVE 화면 대응)
    _startLiveRefreshTimer();

    // 백그라운드에서는 폴링을 멈추고, 복귀하면 즉시 갱신 후 폴링 재개한다.
    // (백그라운드에서 2분 주기 폴링이 계속 돌면 배터리·네트워크만 낭비된다.)
    _lifecycleListener = AppLifecycleListener(
      onResume: _handleResume,
      onPause: _handlePause,
    );
  }

  @override
  void onClose() {
    _stopLiveRefreshTimer();
    _lifecycleListener?.dispose();
    super.onClose();
  }

  void _startLiveRefreshTimer() {
    _liveRefreshTimer?.cancel();
    _liveRefreshTimer = Timer.periodic(
      _liveRefreshInterval,
      (_) => refreshAllLiveStatus(),
    );
  }

  void _stopLiveRefreshTimer() {
    _liveRefreshTimer?.cancel();
    _liveRefreshTimer = null;
  }

  /// 포그라운드 복귀: 즉시 1회 갱신하고 주기 폴링을 재개한다.
  void _handleResume() {
    refreshAllLiveStatus();
    _startLiveRefreshTimer();
  }

  /// 백그라운드 진입: 주기 폴링을 멈춰 자원 낭비를 막는다.
  void _handlePause() {
    _stopLiveRefreshTimer();
  }

  RxString selectedGroup = ''.obs;

  // 마지막 선택 그룹 영속화 키 — 다음 실행 스플래시에서 복원해 그룹 선택을 건너뛴다.
  static const String _groupPrefsKey = 'selected_group';

  /// 그룹 선택/전환 단일 진입점 — 값 반영과 기기 영속화를 함께 한다.
  /// 값을 먼저 반영하므로 저장이 실패해도 이번 실행 동작에는 영향이 없다
  /// (다음 실행에서 그룹 선택 화면이 다시 뜰 뿐이다).
  Future<void> selectGroup(String group) async {
    selectedGroup.value = group;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_groupPrefsKey, group);
    } catch (_) {
      // 저장 실패는 무시.
    }
  }

  /// 저장된 마지막 선택 그룹을 복원한다. 유효한 그룹이면 [selectedGroup]에
  /// 반영하고 그 값을, 없거나(첫 실행) 유효하지 않으면(읽기 실패 포함) null을
  /// 반환해 호출부(스플래시)가 그룹 선택 화면으로 보내게 한다.
  Future<String?> restoreSelectedGroup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_groupPrefsKey);
      if (saved != 'honeyz' && saved != 'acaxia') return null;
      selectedGroup.value = saved!;
      return saved;
    } catch (_) {
      return null;
    }
  }

  // 스케줄도 멤버 데이터와 동일하게 member.key로 조회하는 Map으로 보관한다.
  // (리스트로 두면 문서가 없는 멤버가 빠지면서 카탈로그와 인덱스가 어긋나,
  //  소비 측에서 다른 멤버의 스케줄에 엉뚱한 이름이 붙는다.)
  RxMap<String, ScheduleModel> honeyzSchedules = <String, ScheduleModel>{}.obs;
  RxMap<String, ScheduleModel> acaxiaSchedules = <String, ScheduleModel>{}.obs;

  // 멤버 데이터/라이브 상태는 member.key로 조회하는 Map으로 보관한다.
  // (카탈로그와 인덱스로 페어링하지 않으므로, 멤버 추가·순서 변경에도 어긋나지 않는다.
  //  문서/조회 결과가 없는 멤버는 맵에 없을 뿐이며, 소비 측은 "없음 = 비방송"으로 다룬다.)
  RxMap<String, StreamerModel> honeyz = <String, StreamerModel>{}.obs;
  RxMap<String, StreamerModel> acaxia = <String, StreamerModel>{}.obs;
  RxMap<String, LiveCheckModel> honeyzLiveStatus =
      <String, LiveCheckModel>{}.obs;
  RxMap<String, LiveCheckModel> acaxiaLiveStatus =
      <String, LiveCheckModel>{}.obs;

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

  RxMap<String, ScheduleModel> _scheduleCacheOf(String group) =>
      group == 'honeyz' ? honeyzSchedules : acaxiaSchedules;

  RxMap<String, StreamerModel> _streamerCacheOf(String group) =>
      group == 'honeyz' ? honeyz : acaxia;

  RxMap<String, LiveCheckModel> _liveCacheOf(String group) =>
      group == 'honeyz' ? honeyzLiveStatus : acaxiaLiveStatus;

  /// 컬렉션의 모든 문서를 문서 ID(= 멤버 key) 기준 Map으로 반환.
  /// 멤버-문서 매칭을 O(n²) 중첩 루프 대신 O(1) 조회로 처리하기 위함.
  ///
  /// 조회 실패(오프라인·unavailable 등) 시 null. 호출부는 캐시를 그대로 두고
  /// 다음 호출에서 재시도한다 — 예외를 그대로 던지면 fire-and-forget 호출부
  /// (initState·RefreshIndicator·onTap)에서 아무도 잡지 못해 fatal로 집계된다.
  Future<Map<String, Map<String, dynamic>>?> _fetchDocsByKey(
      String collection) async {
    try {
      final snapshot = await _fireStore.collection(collection).get();

      // 오프라인에서 로컬 캐시까지 비어 있으면 Firestore는 예외를 던지지 않고
      // "빈 스냅샷"을 성공으로 돌려준다. 그대로 통과시키면 네트워크 실패가
      // "데이터가 없음"으로 둔갑해, 캐시를 빈 값으로 덮어쓰고 사용자에게는
      // 아무 안내도 못 한다. 서버에 닿지 못한 빈 결과는 실패로 취급한다.
      // (문서가 있는 캐시 응답은 그대로 쓴다 — 오프라인에서도 화면이 보여야 한다.)
      if (snapshot.docs.isEmpty && snapshot.metadata.isFromCache) {
        developer.log(
          'Firestore 컬렉션이 비어 있고 캐시 응답 → 오프라인으로 판단: $collection',
          name: 'GlobalController',
        );
        return null;
      }

      return {for (final doc in snapshot.docs) doc.id: doc.data()};
    } catch (e, st) {
      developer.log(
        'Firestore 컬렉션 조회 실패: $collection',
        name: 'GlobalController',
        error: e,
        stackTrace: st,
      );
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Firestore 컬렉션 조회 실패 ($collection)',
        fatal: false,
      );
      return null;
    }
  }

  /// 조회에 실패했고 화면에 보여줄 캐시도 없을 때만 사용자에게 알린다.
  /// 캐시가 남아 있으면 화면은 멀쩡하므로(새로고침 실패 등) 조용히 넘어간다.
  void _notifyLoadFailed() {
    showAppSnackBar('데이터를 불러오지 못했습니다. 네트워크 연결을 확인해 주세요.');
  }

  Future<Map<String, ScheduleModel>> loadScheduleFireStore(
      {bool forceRefresh = false}) async {
    final group = selectedGroup.value;
    final collection = _scheduleCollection[group];
    if (collection == null) return {};

    final cache = _scheduleCacheOf(group);
    if (forceRefresh || cache.isEmpty) {
      final docsByKey = await _fetchDocsByKey(collection);
      // 조회 실패 시 기존 캐시를 빈 값으로 덮어쓰지 않는다.
      if (docsByKey != null) {
        // member.key로 조회하는 맵으로 보관한다. 문서가 없는 멤버는 맵에 없을 뿐이며,
        // UI는 카탈로그를 순서·구성의 단일 소스로 삼아 "스케줄 등록 전"으로 표시한다.
        cache.value = {
          for (final member in membersOf(group))
            if (docsByKey[member.key] != null)
              member.key: ScheduleModel.fromJson(docsByKey[member.key]!),
        };
      } else if (cache.isEmpty) {
        _notifyLoadFailed();
      }
    }
    return cache;
  }

  Future<Map<String, StreamerModel>> loadStreamerFireStore(
      {bool forceRefresh = false}) async {
    final group = selectedGroup.value;
    if (group != 'honeyz' && group != 'acaxia') return {};

    final cache = _streamerCacheOf(group);
    if (forceRefresh || cache.isEmpty) {
      // 스트리머 컬렉션 이름은 그룹 이름과 동일하다.
      final docsByKey = await _fetchDocsByKey(group);
      // 조회 실패 시 기존 캐시를 빈 값으로 덮어쓰지 않는다.
      if (docsByKey != null) {
        // member.key로 조회하는 맵으로 보관한다. 문서가 없는 멤버는 맵에 없을 뿐이며,
        // UI는 이름/프로필을 카탈로그에서 가져오므로(group_page) 누락돼도 안전하다.
        cache.value = {
          for (final member in membersOf(group))
            if (docsByKey[member.key] != null)
              member.key: StreamerModel.fromJson(docsByKey[member.key]!),
        };
      } else if (cache.isEmpty) {
        _notifyLoadFailed();
      }
    }
    return cache;
  }

  Future<LiveCheckModel?> _fetchLiveStatus(String broadcastId) async {
    final url = Uri.parse(
        'https://api.chzzk.naver.com/polling/v2/channels/$broadcastId/live-status');
    try {
      final response = await http.get(url).timeout(_requestTimeout);
      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(decodedBody);
        return LiveCheckModel.fromJson(data['content']);
      }
      // 비공식 polling 엔드포인트라 응답 형식이 바뀌면 무증상 실패할 수 있다.
      // HTTP 비정상 응답은 엔드포인트 계약이 바뀐 신호이므로 Crashlytics에 기록한다.
      developer.log(
        'chzzk 라이브 상태 조회 실패 (HTTP ${response.statusCode}): $broadcastId',
        name: 'GlobalController',
      );
      FirebaseCrashlytics.instance.recordError(
        'chzzk live-status HTTP ${response.statusCode}',
        null,
        reason: 'chzzk 라이브 상태 엔드포인트 비정상 응답',
        fatal: false,
      );
    } catch (e, st) {
      developer.log(
        'chzzk 라이브 상태 조회 예외: $broadcastId',
        name: 'GlobalController',
        error: e,
        stackTrace: st,
      );
      // 일시적 연결 오류(타임아웃/소켓)는 노이즈이므로 제외하고, 응답 파싱 실패 등
      // 엔드포인트 형식 변경을 시사하는 예외만 기록한다.
      final isTransient = e is TimeoutException ||
          e is SocketException ||
          e is http.ClientException;
      if (!isTransient) {
        FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'chzzk 라이브 상태 응답 파싱 실패 (형식 변경 가능성)',
          fatal: false,
        );
      }
    }
    return null;
  }

  Future<Map<String, LiveCheckModel>> liveCheck(
      {bool forceRefresh = false}) async {
    final group = selectedGroup.value;
    if (group != 'honeyz' && group != 'acaxia') return {};

    final cache = _liveCacheOf(group);
    if (forceRefresh || cache.isEmpty) {
      await refreshLiveStatus();
    }
    return cache;
  }

  /// 현재 선택된 그룹의 라이브 상태를 새로 조회해서 교체.
  /// 서버 집계 문서는 양쪽 그룹을 한 번에 채우므로, 성공 시 그대로 반환하고
  /// 실패(문서 없음/오래됨/오류) 시에만 선택 그룹을 직접 폴링한다.
  Future<void> refreshLiveStatus() async {
    if (await _refreshFromServerAggregate()) return;
    await _refreshGroupLiveStatus(selectedGroup.value);
  }

  /// 양쪽 그룹(허니즈+아카시아)의 라이브 상태를 동시에 갱신 (통합 LIVE 화면용).
  /// 서버 집계 우선, 실패 시 두 그룹을 직접 폴링으로 폴백.
  Future<void> refreshAllLiveStatus() async {
    if (await _refreshFromServerAggregate()) return;
    await Future.wait([
      _refreshGroupLiveStatus('honeyz'),
      _refreshGroupLiveStatus('acaxia'),
    ]);
  }

  /// 서버 집계 문서(`live_status/current`)에서 양쪽 그룹 상태를 채운다.
  ///
  /// 성공하면 true. 문서가 없거나(서버 미배포), 너무 오래됐거나(서버 폴링 중단),
  /// 집계가 비었거나(문서 초기화·형식 오류), 조회에 실패하면 false를 반환해
  /// 호출부가 치지직 직접 폴링으로 폴백하게 한다.
  Future<bool> _refreshFromServerAggregate() async {
    try {
      final snapshot = await _fireStore
          .doc(_liveStatusDocPath)
          .get()
          .timeout(_requestTimeout);
      final data = snapshot.data();
      if (data == null) return false;

      // 서버 폴링이 멈췄으면(문서가 오래됨) 신선한 직접 폴링으로 폴백한다.
      if (isAggregateStale(
          data['updatedAt'], DateTime.now(), _serverStatusMaxAge)) {
        return false;
      }

      final members =
          (data['members'] as Map?)?.cast<String, dynamic>() ?? const {};
      final caches = liveCachesFromAggregate(members);
      if (caches == null) return false;
      _liveCacheOf('honeyz').value = caches.honeyz;
      _liveCacheOf('acaxia').value = caches.acaxia;
      return true;
    } catch (e, st) {
      // 일시적 오류 등은 조용히 폴백 (치지직 직접 폴링이 폴백으로 남는다).
      developer.log(
        '서버 라이브 집계 조회 실패 → 치지직 직접 폴링으로 폴백',
        name: 'GlobalController',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// 서버 집계 문서(`live_status/current`)가 오래됐는지(stale) 판정한다.
  /// [updatedAt]이 `Timestamp`이고 [now]와의 차이가 [maxAge]를 초과하면 true
  /// (= 서버 폴링 중단 의심 → 호출부가 치지직 직접 폴링으로 폴백).
  ///
  /// updatedAt이 Timestamp가 아니면(null/누락/형식 오류) false를 반환한다 —
  /// 현재는 이 경우를 "오래되지 않음"으로 보아 집계 데이터를 그대로 사용한다.
  /// (Firestore 읽기와 분리된 순수 판정 — 테스트 대상)
  @visibleForTesting
  static bool isAggregateStale(
      Object? updatedAt, DateTime now, Duration maxAge) {
    return updatedAt is Timestamp &&
        now.difference(updatedAt.toDate()) > maxAge;
  }

  /// 서버 집계 members를 두 그룹의 캐시 값으로 변환한다. 어느 한 그룹도 채우지
  /// 못하면(문서 초기화 직후·형식 오류) null — 홈은 "빈 맵 = 로딩 중"으로
  /// 그리므로, 빈 집계를 성공으로 취급해 캐시를 {}로 덮으면 직접 폴링 폴백이
  /// 막혀 스피너가 영영 사라지지 않는다. 정상 집계는 서버가 매 주기 멤버 전원을
  /// 기록하므로 두 그룹 모두 비지 않는다. (순수 변환 — 테스트 대상)
  @visibleForTesting
  ({Map<String, LiveCheckModel> honeyz, Map<String, LiveCheckModel> acaxia})?
      liveCachesFromAggregate(Map<String, dynamic> members) {
    final honeyz = liveStatusFromAggregate('honeyz', members);
    final acaxia = liveStatusFromAggregate('acaxia', members);
    if (honeyz.isEmpty || acaxia.isEmpty) return null;
    return (honeyz: honeyz, acaxia: acaxia);
  }

  /// 서버 집계 members 맵을 `member.key → 상태` 맵으로 변환한다.
  /// 문서에 없는(또는 형식이 맞지 않는) 멤버는 결과에 넣지 않는다 — 소비 측이
  /// "없음 = 비방송"으로 다루므로 인덱스 정렬 불변식 없이도 안전하다.
  /// (Firestore 읽기와 분리된 순수 변환 — 테스트 대상)
  @visibleForTesting
  Map<String, LiveCheckModel> liveStatusFromAggregate(
      String group, Map<String, dynamic> members) {
    return {
      for (final member in membersOf(group))
        if (members[member.key] is Map)
          member.key: LiveCheckModel.fromJson(
              (members[member.key] as Map).cast<String, dynamic>()),
    };
  }

  /// 지정한 그룹의 라이브 상태를 새로 조회해서 교체.
  /// 조회에 실패한 멤버는 `CLOSE` 기본값으로 채운다 — 폴링을 한 번이라도 시도하면
  /// 맵이 비지 않아, UI가 "로딩 중(맵 비어있음)"과 "전원 비방송"을 구분할 수 있다.
  Future<void> _refreshGroupLiveStatus(String group) async {
    if (group != 'honeyz' && group != 'acaxia') return;

    final members = membersOf(group);
    final results = await Future.wait(
      members.map((m) => _fetchLiveStatus(m.chzzkBroadcastId)),
    );

    _liveCacheOf(group).value = {
      for (var i = 0; i < members.length; i++)
        members[i].key:
            results[i] ?? LiveCheckModel(status: 'CLOSE', liveTitle: null),
    };
  }

  /// 두 그룹을 통합한 현재 방송 중(LIVE) 멤버 목록.
  /// 시청자 수 내림차순으로 정렬되며, isLive인 멤버만 포함한다.
  List<LiveMemberEntry> get liveMembersAcrossGroups {
    final entries = <LiveMemberEntry>[];

    void collect(List<Member> members, Map<String, LiveCheckModel> statuses) {
      for (final member in members) {
        final status = statuses[member.key];
        if (status != null && status.isLive) {
          entries.add(LiveMemberEntry(
            group: member.group,
            memberKey: member.key,
            memberName: member.name,
            assetPath: member.profileAssetPath,
            broadcastId: member.chzzkBroadcastId,
            status: status,
          ));
        }
      }
    }

    collect(honeyzMembers, honeyzLiveStatus);
    collect(acaxiaMembers, acaxiaLiveStatus);

    // 시청자 수 내림차순 (null은 0으로 취급해 뒤로)
    entries.sort((a, b) => (b.status.concurrentUserCount ?? 0)
        .compareTo(a.status.concurrentUserCount ?? 0));

    return entries;
  }

  /// 지정 그룹의 카탈로그 순서대로 스케줄 이미지 URL을 나열한다.
  /// 문서가 없거나 이미지가 비어 있는 멤버는 빈 문자열이 되므로, 결과 길이·순서가
  /// 항상 `membersOf(group)`과 일치한다 — 소비 측이 인덱스로 멤버 이름과 짝지어도
  /// 어긋나지 않는다. (문서 없는 멤버를 걸러낸 리스트를 쓰면 그 뒤 멤버들의 이름이
  ///  한 칸씩 밀려 다른 멤버의 스케줄에 엉뚱한 이름이 붙는다.)
  List<String> scheduleImageUrlsOf(String group) {
    final cache = _scheduleCacheOf(group);
    return [
      for (final member in membersOf(group))
        cache[member.key]?.scheduleURL ?? '',
    ];
  }

  /// 지정 그룹의 다가오는 생일 (가까운 순). birthday 미설정 멤버는 제외.
  /// Member(이름/에셋)와 StreamerModel(생일)을 member.key로 매칭한다.
  List<BirthdayEntry> upcomingBirthdays(String group) {
    final streamers = group == 'honeyz' ? honeyz : acaxia;

    final entries = <BirthdayEntry>[];
    for (final member in membersOf(group)) {
      final streamer = streamers[member.key];
      if (streamer == null) continue;
      final days = streamer.daysUntilBirthday;
      final label = streamer.birthdayLabel;
      if (days == null || label == null) continue;
      entries.add(BirthdayEntry(
        memberName: member.name,
        assetPath: member.profileAssetPath,
        daysUntil: days,
        dateLabel: label,
      ));
    }

    entries.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
    return entries;
  }
}
