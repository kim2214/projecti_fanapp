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

  // ── 시맨틱 ──
  static const Color textPrimary = Color(0xFF1A3A4A);
  static const Color live = Color(0xFFFF3B30);
  static const Color favorite = Color(0xFFFFB300);
  static const Color birthday = Color(0xFFFFA000);

  // ── 그룹 헬퍼 (isHoneyz 분기 반복 제거) ──
  static Color group(bool isHoneyz) => isHoneyz ? honeyz : acaxia;
  static Color groupDark(bool isHoneyz) => isHoneyz ? honeyzDark : acaxiaDark;
}
