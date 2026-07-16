import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/notification_controller.dart';
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
    if (favoriteIds.contains(id)) {
      favoriteIds.remove(id);
    } else {
      favoriteIds.add(id);
    }
    await _save();
    _syncLiveTopics();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    favoriteIds.value = prefs.getStringList(_prefsKey) ?? <String>[];
    _syncLiveTopics();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, favoriteIds.toList());
  }

  /// 최애 목록('group:key')에서 멤버 key만 추출해 라이브 토픽 구독을 동기화한다.
  void _syncLiveTopics() {
    if (!Get.isRegistered<NotificationController>()) return;
    final keys = favoriteIds.map((id) => id.split(':').last).toSet();
    Get.find<NotificationController>().syncLiveSubscriptions(keys);
  }

  @override
  void onInit() {
    super.onInit();
    _load();
  }
}
