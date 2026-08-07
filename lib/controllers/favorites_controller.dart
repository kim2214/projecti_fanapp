import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/notification_controller.dart';
import 'package:projecti_fan_app/controllers/review_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 최애 멤버(즐겨찾기)를 기기 로컬에 영속화하는 컨트롤러.
/// 멤버는 'group:memberKey' 형식(예: 'honeyz:ohwayo')으로 식별한다.
///
/// 최애가 바뀌면 [NotificationController]에 알려 라이브 알림 토픽(`live_<key>`)
/// 구독을 동기화한다. (토픽/FCM 로직은 NotificationController가 소유)
class FavoritesController extends GetxController {
  static const String _prefsKey = 'favorite_members';

  /// 현재 최애로 지정된 멤버 ID 목록 (Obx 구독용)
  final RxList<String> favoriteIds = <String>[].obs;

  String _id(String group, String key) => '$group:$key';

  bool isFavorite(String group, String key) =>
      favoriteIds.contains(_id(group, key));

  /// 최애 지정/해제 토글 후 영속화
  Future<void> toggle(String group, String key) async {
    final id = _id(group, key);
    final added = !favoriteIds.contains(id);
    if (added) {
      favoriteIds.add(id);
    } else {
      favoriteIds.remove(id);
    }
    await _save();
    _syncLiveTopics();

    // 최애를 '새로 지정'한 순간은 명확한 만족 신호 → 리뷰 요청을 시도한다
    // (실제 노출 여부·빈도는 ReviewController가 판정).
    if (added && Get.isRegistered<ReviewController>()) {
      Get.find<ReviewController>().maybeRequestReview();
    }
  }

  /// onInit에서 fire-and-forget으로 호출되므로 예외를 밖으로 흘리면
  /// 아무도 잡지 못해 fatal로 집계된다. 최애 목록은 없어도 앱이 동작한다.
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      favoriteIds.value = prefs.getStringList(_prefsKey) ?? <String>[];
    } catch (_) {
      // 못 읽으면 빈 목록으로 시작.
    }
    _syncLiveTopics();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, favoriteIds.toList());
    } catch (_) {
      // 저장 실패는 무시 (이번 실행 동안은 메모리 목록이 유지된다).
    }
  }

  /// 최애 목록('group:key')에서 멤버 key만 추출해 라이브 토픽 구독을 동기화한다.
  ///
  /// fire-and-forget이라 실패(오프라인 등 FCM 구독 오류)를 여기서 잡지 않으면
  /// 아무도 잡지 못해 PlatformDispatcher를 통해 fatal 크래시로 오분류된다.
  /// 구독 성공 시에만 집합이 영속되므로, 실패해도 다음 호출에서 다시 시도된다.
  void _syncLiveTopics() {
    if (!Get.isRegistered<NotificationController>()) return;
    final keys = favoriteIds.map((id) => id.split(':').last).toSet();
    unawaited(
      Get.find<NotificationController>()
          .syncLiveSubscriptions(keys)
          .catchError((Object e, StackTrace st) {
        FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: '라이브 알림 토픽 구독 동기화 실패',
          fatal: false,
        );
      }),
    );
  }

  @override
  void onInit() {
    super.onInit();
    _load();
  }
}
