import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 최애 멤버(즐겨찾기)를 기기 로컬에 영속화하는 컨트롤러.
/// 멤버는 'group:memberKey' 형식(예: 'honeyz:ohwayo')으로 식별한다.
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
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    favoriteIds.value = prefs.getStringList(_prefsKey) ?? <String>[];
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, favoriteIds.toList());
  }

  @override
  void onInit() {
    super.onInit();
    _load();
  }
}
