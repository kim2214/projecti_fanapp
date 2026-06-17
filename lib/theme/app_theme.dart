import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 앱 전역 라이트/다크 ThemeData.
/// Material 위젯(RefreshIndicator/Slider/Dialog 등)의 기본색이 모드에 맞게 따라오도록 한다.
/// 화면별 세부 색은 `BuildContext`의 시맨틱 토큰(context.surface 등)으로 처리.
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.honeyz,
          brightness: Brightness.light,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.honeyz,
          brightness: Brightness.dark,
        ).copyWith(surface: AppColors.darkSurface),
      );
}
