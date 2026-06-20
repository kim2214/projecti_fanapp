import 'package:flutter/material.dart';

// 밝은 시안 테마 (#30bcec 기반) — YouTube 화면에서 사용
class AudioTheme {
  // 메인 컬러
  static const Color primary = Color(0xFF30bcec);
  static const Color primaryLight = Color(0xFF7DD3F4);
  static const Color primaryDark = Color(0xFF1A9BC7);

  // 배경 (밝은 시안 그라데이션용)
  static const Color backgroundLight = Color(0xFFE8F7FC);
  static const Color backgroundMid = Color(0xFFD0F0FA);
  static const Color background = Color(0xFFB8E8F7);

  // Surface (카드, 버튼 배경)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF0FAFD);
  static const Color surfaceTint = Color(0xFFE0F4FA);

  // 텍스트
  static const Color textPrimary = Color(0xFF1A3A4A);
  static const Color textSecondary = Color(0xFF5A8A9A);

  // 액센트
  static const Color accent = Color(0xFF0D98D0);
}
