import 'package:flutter/material.dart';

/// 앱 전역에서 쓰이는 커스텀 컬러 단일 정의.
/// (여러 위젯에 중복돼 있던 그룹 브랜드/시맨틱 컬러를 한 곳으로 통합)
class AppColors {
  AppColors._();

  // ── 그룹 브랜드 ──
  static const Color honeyz = Color(0xFFFF5E88);
  static const Color honeyzDark = Color(0xFFE84A75);
  static const Color acaxia = Color(0xFFCCD1F9);
  static const Color acaxiaDark = Color(0xFFB8BEF0);

  /// 라일락(acaxia)은 텍스트로 쓰기엔 흐려서 별도 톤 사용
  static const Color acaxiaText = Color(0xFF8A90D8);

  // ── 시맨틱 (라이트) ──
  static const Color textPrimary = Color(0xFF1A3A4A);
  static const Color live = Color(0xFFFF3B30);
  static const Color favorite = Color(0xFFFFB300);
  static const Color birthday = Color(0xFFFFA000);

  // ── 시맨틱 (라이트 보조) ──
  static const Color lightTextSecondary = Color(0xFF757575); // grey[600]
  static const Color lightTextFaint = Color(0xFF9E9E9E); // grey[500]/[400]
  static const Color lightDivider = Color(0xFFE0E0E0); // grey[300]
  static const Color lightSurfaceAlt = Color(0xFFF2F2F4);

  // ── 다크 팔레트 ──
  static const Color darkBg = Color(0xFF14151A);
  static const Color darkSurface = Color(0xFF1F2128);
  static const Color darkSurfaceAlt = Color(0xFF262932);
  static const Color darkTextPrimary = Color(0xFFECEDEF);
  static const Color darkTextSecondary = Color(0xFFA8ACB3);
  static const Color darkTextFaint = Color(0xFF787C84);
  static const Color darkDivider = Color(0xFF33363F);

  // ── 그룹 헬퍼 (isHoneyz 분기 반복 제거) ──
  static Color group(bool isHoneyz) => isHoneyz ? honeyz : acaxia;
  static Color groupDark(bool isHoneyz) => isHoneyz ? honeyzDark : acaxiaDark;
}

/// 밝기(brightness)에 따라 전환되는 시맨틱 컬러.
/// 위젯에서 `context.surface`, `context.textMain` 처럼 사용한다.
extension AppColorsX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// 페이지/스캐폴드 배경
  Color get bg => isDark ? AppColors.darkBg : Colors.white;

  /// 카드/컨테이너 표면
  Color get surface => isDark ? AppColors.darkSurface : Colors.white;

  /// 칩/인셋 등 보조 표면
  Color get surfaceAlt =>
      isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;

  /// 본문 주요 텍스트
  Color get textMain =>
      isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

  /// 보조 텍스트 (기존 grey[600])
  Color get textSub =>
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

  /// 흐린 텍스트 (기존 grey[500]/[400])
  Color get textFaint =>
      isDark ? AppColors.darkTextFaint : AppColors.lightTextFaint;

  /// 구분선/연한 보더 (기존 grey[300])
  Color get divider => isDark ? AppColors.darkDivider : AppColors.lightDivider;
}
