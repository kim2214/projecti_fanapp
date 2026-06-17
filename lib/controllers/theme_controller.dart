import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 테마 모드(라이트/다크/시스템)를 관리하고 기기에 영속화한다.
class ThemeController extends GetxController {
  static const String _prefsKey = 'theme_mode';

  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  /// main()에서 첫 빌드 전에 호출해 저장된 모드를 선로딩한다.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    themeMode.value = _fromString(prefs.getString(_prefsKey));
  }

  /// system → light → dark → system 순환
  Future<void> cycle() async {
    switch (themeMode.value) {
      case ThemeMode.system:
        themeMode.value = ThemeMode.light;
        break;
      case ThemeMode.light:
        themeMode.value = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        themeMode.value = ThemeMode.system;
        break;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _toString(themeMode.value));
  }

  /// 현재 모드를 나타내는 아이콘
  IconData get icon {
    switch (themeMode.value) {
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
    }
  }

  static ThemeMode _fromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
