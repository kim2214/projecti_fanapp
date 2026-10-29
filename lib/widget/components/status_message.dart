import 'package:flutter/material.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';

/// 비어 있음·불러오기 실패 안내 (아이콘 + 제목 + 보조 문구 + 선택적 "다시 시도").
/// 홈 라이브 섹션·통합 LIVE·스케줄 탭·스케줄 상세가 같은 모양과 문구 톤을 쓴다.
///
/// [compact]는 홈 카드 안처럼 좁은 자리용으로 아이콘·글자를 줄인다.
/// 배경·여백·정렬(카드, Center 등)은 놓이는 자리에 맞게 호출부가 감싼다.
class StatusMessage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;

  /// 있으면 "다시 시도" 버튼을 붙인다. 버튼 색은 [actionColor] (기본 [iconColor]).
  final VoidCallback? onRetry;
  final Color? actionColor;
  final bool compact;

  const StatusMessage({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onRetry,
    this.actionColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final retryColor = actionColor ?? iconColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 32 : 48, color: iconColor),
        SizedBox(height: compact ? 10 : 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 14 : 15,
            fontWeight: FontWeight.w500,
            color: context.textFaint,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: compact ? 4 : 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: context.textFaint),
          ),
        ],
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh_rounded, size: 18, color: retryColor),
            label: Text(
              '다시 시도',
              style: TextStyle(color: retryColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}
