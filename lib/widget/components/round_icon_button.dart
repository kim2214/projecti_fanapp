import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:projecti_fan_app/widget/components/tap_semantics.dart';

/// 상세 화면 상단의 44×44 둥근 표면 버튼 (뒤로가기·최애 등).
/// 아이콘만 있으므로 스크린리더용 [label]을 반드시 준다.
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final double iconSize;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.iconSize = 22,
  });

  /// 현재 화면을 닫는 뒤로가기 버튼.
  factory RoundIconButton.back(BuildContext context, {required Color color}) =>
      RoundIconButton(
        icon: Icons.arrow_back_rounded,
        color: color,
        label: '뒤로가기',
        onTap: () => context.pop(),
      );

  @override
  Widget build(BuildContext context) {
    return TapSemantics(
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppColors.softShadow,
          ),
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }
}
