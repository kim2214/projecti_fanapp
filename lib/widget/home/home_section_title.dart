import 'package:flutter/material.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:projecti_fan_app/widget/components/tap_semantics.dart';

/// 가로 스크롤 카드 행의 높이. 고정 높이는 시스템 글꼴을 키우면 카드 안의
/// 다단 텍스트가 넘치므로, 글꼴 배율(최대 1.6배까지)에 맞춰 함께 키운다.
double homeRowHeight(BuildContext context, double base) =>
    base * MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.6);

/// 홈 섹션 제목 (아이콘 + 제목 + 선택적 오른쪽 링크).
class HomeSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget? trailing;

  const HomeSectionTitle({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // trailing 링크는 터치 영역(48dp)을 위해 상하 12·우 8만큼 커지므로 그만큼
      // 바깥 여백을 줄여 보이는 위치를 유지한다.
      padding: trailing == null
          ? const EdgeInsets.fromLTRB(24, 16, 24, 12)
          : const EdgeInsets.fromLTRB(24, 4, 16, 0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: context.textMain,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 섹션 제목 오른쪽의 "전체보기/더보기" 링크. 글자는 작지만 터치 영역은 48dp.
class HomeMoreLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const HomeMoreLink(this.label, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textFaint,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: context.textFaint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
