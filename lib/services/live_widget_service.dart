import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/default_firebase_options.dart';
import 'package:projecti_fan_app/model/group.dart';
import 'package:projecti_fan_app/model/live_check_model.dart';
import 'package:projecti_fan_app/model/member.dart';
import 'package:projecti_fan_app/services/chzzk_service.dart';

/// Android 홈스크린 위젯("지금 방송 중")에 데이터를 공급한다.
///
/// 위젯은 앱과 별개로 런처가 그리는 스냅샷이다. 갱신 경로는 세 가지:
/// 1. 앱이 라이브 상태를 갱신할 때 [push] (GlobalController가 호출)
/// 2. 라이브 FCM 수신 시 [refreshFromServer] (main의 백그라운드 핸들러)
/// 3. 위젯 주기 갱신(30분) 때 데이터가 오래됐으면 네이티브가
///    [backgroundCallback]을 호출 → [refreshFromServer]
///
/// 네이티브(LiveStatusWidgetProvider.kt)는 [dataKey]에 저장된 JSON만 읽는다 —
/// 페이로드 형식을 바꾸면 양쪽을 함께 고친다.
///
/// 2·3번 경로는 서버 집계 문서를 우선 읽고, 집계가 없거나 오래됐거나(서버
/// 폴링 중단·빌링 중단) 읽지 못하면 치지직을 직접 조회한다 ([resolveStatus]).
/// 직접 조회도 전부 실패했는데 집계가 오래된 경우엔 페이로드에 `stale: true`를
/// 실어 네이티브가 "상태 확인 불가"를 그리게 한다 — 얼어붙은 목록을 그대로 두는
/// 것도, 빈 목록으로 "모두 휴식 중"이라고 단정하는 것도 둘 다 거짓이 되기 때문이다.
///
/// 클래스에도 `vm:entry-point`가 필요하다 — 네이티브(home_widget 백그라운드
/// 워커)가 콜백 핸들로 정적 메서드에 접근할 때 메서드 pragma만으로는
/// "must be annotated with @pragma('vm:entry-point')" 오류로 콜백이 실행되지
/// 않는다 (실기기에서 확인, 26.08.28).
@pragma('vm:entry-point')
class LiveWidgetService {
  static const String dataKey = 'live_widget_json';
  static const String androidProviderName = 'LiveStatusWidgetProvider';

  static bool get _supported => !kIsWeb && Platform.isAndroid;

  static List<Member> get _allMembers => [
        for (final group in Group.values) ...GlobalController.catalogOf(group),
      ];

  /// 위젯에 그릴 JSON 페이로드. 방송 중인 멤버만 시청자 수 내림차순.
  ///
  /// [stale]이 true면 라이브 목록을 신뢰할 수 없다는 뜻이다(서버 폴링 중단).
  /// 네이티브는 이때 목록·"모두 휴식 중" 대신 "상태 확인 불가"를 그린다.
  /// (순수 — 테스트 대상. URL은 Member.liveUrlOf 한 곳에서 파생한다.)
  @visibleForTesting
  static Map<String, dynamic> buildPayload(
    List<Member> members,
    Map<String, LiveCheckModel> statusByKey,
    DateTime now, {
    bool stale = false,
  }) {
    final live = <Map<String, dynamic>>[];
    for (final member in members) {
      final status = statusByKey[member.key];
      if (status == null || !status.isLive) continue;
      live.add({
        'name': member.name,
        'group': member.group.id,
        'title': status.liveTitle ?? '',
        'viewers': status.concurrentUserCount ?? 0,
        'url': member.liveUrl,
      });
    }
    live.sort((a, b) => (b['viewers'] as int).compareTo(a['viewers'] as int));
    return {
      'updatedAt': now.millisecondsSinceEpoch,
      'stale': stale,
      'live': live,
    };
  }

  /// 현재 라이브 상태(양 그룹 합본 map)로 위젯을 갱신한다.
  /// 위젯은 보조 UI라 Android 외 플랫폼·실패는 조용히 무시한다.
  static Future<void> push(
    Map<String, LiveCheckModel> statusByKey, {
    bool stale = false,
  }) async {
    if (!_supported) return;
    try {
      final payload = buildPayload(
        _allMembers,
        statusByKey,
        DateTime.now(),
        stale: stale,
      );
      await HomeWidget.saveWidgetData<String>(dataKey, json.encode(payload));
      await HomeWidget.updateWidget(androidName: androidProviderName);
    } catch (_) {
      // 위젯 갱신 실패는 앱 동작에 영향 없음.
    }
  }

  /// 백그라운드 isolate(위젯 주기 갱신·FCM)에서 위젯을 갱신한다. GetX 컨트롤러
  /// 없이 동작해야 하므로 Firestore·치지직을 직접 읽는다 ([resolveStatus]).
  @pragma('vm:entry-point')
  static Future<void> refreshFromServer() async {
    if (!_supported) return;
    // 위젯을 하나도 놓지 않은 기기는 무음 푸시·주기 갱신 때 조회를 건너뛴다.
    // 조회 자체가 실패하면(플러그인 미등록 등) 갱신 쪽으로 진행한다.
    try {
      if ((await HomeWidget.getInstalledWidgets()).isEmpty) return;
    } catch (_) {}

    // 백그라운드 isolate라 Crashlytics 기록 경로가 보장되지 않는다 — 치지직
    // 오류도 로그캣으로만 남긴다. 일회성 클라이언트라 끝나면 닫는다.
    final chzzk = ChzzkService(
      reportError: (error, _, reason) =>
          debugPrint('LiveWidgetService 치지직 조회 오류 ($reason): $error'),
    );
    try {
      final result = await resolveStatus(
        readAggregate: _readAggregate,
        chzzk: chzzk,
        now: DateTime.now,
      );
      // null = 판단할 근거가 없음(오프라인 등) — 위젯은 기존 스냅샷을 유지한다.
      if (result != null) await push(result.status, stale: result.stale);
    } finally {
      chzzk.close();
    }
  }

  /// 서버 집계 문서(`live_status/current`)를 읽는다. 이 isolate에서 Firebase가
  /// 아직 초기화되지 않았으면 초기화한다.
  static Future<Map<String, dynamic>?> _readAggregate() async {
    if (Firebase.apps.isEmpty) {
      // google-services가 네이티브에서 기본 앱을 이미 만들어 두므로, 이 isolate의
      // 첫 초기화는 [core/duplicate-app]으로 실패할 수 있다 — main.dart와 동일하게
      // 무시하고 기존 앱을 재사용한다 (실기기에서 확인, 26.08.28).
      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
      } on FirebaseException catch (e) {
        if (e.code != 'duplicate-app') rethrow;
      }
    }
    final snapshot = await FirebaseFirestore.instance
        .doc('live_status/current')
        .get()
        .timeout(ChzzkService.defaultTimeout);
    return snapshot.data();
  }

  /// 위젯에 그릴 상태를 정한다 (B안 — 서버가 멈춰도 위젯이 정확하도록).
  ///
  /// 1. 서버 집계가 신선하면 그대로 쓴다 (치지직 요청 없음).
  /// 2. 집계가 없거나 오래됐거나 읽기에 실패하면 치지직을 직접 조회한다.
  ///    한 명이라도 성공하면 그 결과를 쓴다 — 실패한 멤버는 비방송으로 보인다.
  /// 3. 직접 조회도 전원 실패하면: 집계를 읽었으나 오래된 경우 `stale`(확인
  ///    불가), 집계도 못 읽은 경우(오프라인) null(기존 스냅샷 유지).
  ///
  /// [readAggregate]·[chzzk]·[now]를 주입받는다 — Firestore·네트워크 없이 테스트.
  @visibleForTesting
  static Future<({Map<String, LiveCheckModel> status, bool stale})?>
      resolveStatus({
    required Future<Map<String, dynamic>?> Function() readAggregate,
    required ChzzkService chzzk,
    required DateTime Function() now,
  }) async {
    ({Map<String, LiveCheckModel> status, bool stale})? aggregate;
    try {
      aggregate = statusFromAggregate(await readAggregate(), now());
      if (!aggregate.stale) return aggregate;
    } catch (e) {
      debugPrint('LiveWidgetService 서버 집계 조회 실패 → 치지직 직접 조회: $e');
    }

    final members = _allMembers;
    final results = await Future.wait(
        members.map((m) => chzzk.fetchLiveStatus(m.chzzkBroadcastId)));
    if (results.any((r) => r != null)) {
      return (
        status: {
          for (var i = 0; i < members.length; i++)
            if (results[i] case final status?) members[i].key: status,
        },
        stale: false,
      );
    }
    return aggregate;
  }

  /// 집계 문서(`live_status/current`)를 위젯이 그릴 상태로 바꾼다.
  ///
  /// 서버 폴링이 멈추면(Functions 중단·장애) 집계 문서는 마지막 상태로 얼어붙는다.
  /// 앱 화면은 직접 폴링으로 폴백하지만 이 백그라운드 경로에는 폴백이 없으므로,
  /// 오래된 집계는 그리지 않고 [stale]로 표시해 네이티브가 "확인 불가"를 그리게
  /// 한다. (얼어붙은 목록을 그리면 "방송 중"이, 빈 목록을 그리면 "모두 휴식 중"이
  /// 거짓이 된다 — 둘 다 단정이라 어느 쪽도 맞지 않는다.)
  /// (Firestore 읽기와 분리된 순수 변환 — 테스트 대상)
  @visibleForTesting
  static ({Map<String, LiveCheckModel> status, bool stale}) statusFromAggregate(
      Map<String, dynamic>? data, DateTime now) {
    if (data == null ||
        GlobalController.isAggregateStale(
            data['updatedAt'], now, GlobalController.serverStatusMaxAge)) {
      return (status: const {}, stale: true);
    }
    final members =
        (data['members'] as Map?)?.cast<String, dynamic>() ?? const {};
    return (
      status: {
        for (final entry in members.entries)
          if (entry.value is Map)
            entry.key: LiveCheckModel.fromJson(
                (entry.value as Map).cast<String, dynamic>()),
      },
      stale: false,
    );
  }

  /// home_widget 백그라운드 콜백 진입점 (main에서 registerInteractivityCallback).
  @pragma('vm:entry-point')
  static Future<void> backgroundCallback(Uri? uri) => refreshFromServer();
}
