import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/default_firebase_options.dart';
import 'package:projecti_fan_app/model/live_check_model.dart';
import 'package:projecti_fan_app/model/member.dart';

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
/// 클래스에도 `vm:entry-point`가 필요하다 — 네이티브(home_widget 백그라운드
/// 워커)가 콜백 핸들로 정적 메서드에 접근할 때 메서드 pragma만으로는
/// "must be annotated with @pragma('vm:entry-point')" 오류로 콜백이 실행되지
/// 않는다 (실기기에서 확인, 26.08.28).
@pragma('vm:entry-point')
class LiveWidgetService {
  static const String dataKey = 'live_widget_json';
  static const String androidProviderName = 'LiveStatusWidgetProvider';

  static bool get _supported => !kIsWeb && Platform.isAndroid;

  /// 위젯에 그릴 JSON 페이로드. 방송 중인 멤버만 시청자 수 내림차순.
  /// (순수 — 테스트 대상. URL은 Member.liveUrlOf 한 곳에서 파생한다.)
  @visibleForTesting
  static Map<String, dynamic> buildPayload(
    List<Member> members,
    Map<String, LiveCheckModel> statusByKey,
    DateTime now,
  ) {
    final live = <Map<String, dynamic>>[];
    for (final member in members) {
      final status = statusByKey[member.key];
      if (status == null || !status.isLive) continue;
      live.add({
        'name': member.name,
        'group': member.group,
        'title': status.liveTitle ?? '',
        'viewers': status.concurrentUserCount ?? 0,
        'url': member.liveUrl,
      });
    }
    live.sort((a, b) => (b['viewers'] as int).compareTo(a['viewers'] as int));
    return {'updatedAt': now.millisecondsSinceEpoch, 'live': live};
  }

  /// 현재 라이브 상태(양 그룹 합본 map)로 위젯을 갱신한다.
  /// 위젯은 보조 UI라 Android 외 플랫폼·실패는 조용히 무시한다.
  static Future<void> push(Map<String, LiveCheckModel> statusByKey) async {
    if (!_supported) return;
    try {
      final payload = buildPayload(
        [...GlobalController.honeyzMembers, ...GlobalController.acaxiaMembers],
        statusByKey,
        DateTime.now(),
      );
      await HomeWidget.saveWidgetData<String>(dataKey, json.encode(payload));
      await HomeWidget.updateWidget(androidName: androidProviderName);
    } catch (_) {
      // 위젯 갱신 실패는 앱 동작에 영향 없음.
    }
  }

  /// 백그라운드 isolate(위젯 주기 갱신·FCM)에서 서버 집계 문서를 직접 읽어
  /// 위젯을 갱신한다. GetX 컨트롤러 없이 동작해야 하므로 Firestore를 바로 읽는다.
  @pragma('vm:entry-point')
  static Future<void> refreshFromServer() async {
    if (!_supported) return;
    try {
      // 위젯을 하나도 놓지 않은 기기는 무음 푸시·주기 갱신 때 Firestore 읽기를
      // 건너뛴다. 조회 자체가 실패하면(플러그인 미등록 등) 갱신 쪽으로 진행한다.
      try {
        if ((await HomeWidget.getInstalledWidgets()).isEmpty) return;
      } catch (_) {}

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
          .timeout(const Duration(seconds: 8));
      final members =
          (snapshot.data()?['members'] as Map?)?.cast<String, dynamic>() ??
              const {};
      final statusByKey = <String, LiveCheckModel>{
        for (final entry in members.entries)
          if (entry.value is Map)
            entry.key: LiveCheckModel.fromJson(
                (entry.value as Map).cast<String, dynamic>()),
      };
      await push(statusByKey);
    } catch (e) {
      // 오프라인 등 — 위젯은 기존 스냅샷을 유지한다. 원인은 로그캣으로만 남긴다
      // (백그라운드 isolate라 Crashlytics 기록 경로가 보장되지 않음).
      debugPrint('LiveWidgetService.refreshFromServer 실패: $e');
    }
  }

  /// home_widget 백그라운드 콜백 진입점 (main에서 registerInteractivityCallback).
  @pragma('vm:entry-point')
  static Future<void> backgroundCallback(Uri? uri) => refreshFromServer();
}
