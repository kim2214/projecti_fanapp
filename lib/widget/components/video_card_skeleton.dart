import 'package:flutter/material.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';

/// YouTubeVideoCard와 동일한 레이아웃의 로딩 자리표시자(스켈레톤).
/// 외부 패키지 없이 shimmer(빛이 좌→우로 쓸고 지나가는) 효과를 직접 구현한다.
class VideoCardSkeleton extends StatefulWidget {
  const VideoCardSkeleton({super.key});

  @override
  State<VideoCardSkeleton> createState() => _VideoCardSkeletonState();
}

class _VideoCardSkeletonState extends State<VideoCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final base = isDark ? const Color(0xFF262932) : const Color(0xFFE3E5EA);
    final highlight =
        isDark ? const Color(0xFF343845) : const Color(0xFFF5F6F8);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider.withAlpha(80), width: 1),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) => LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.1, 0.3, 0.4],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              transform:
                  _SlidingGradient(slide: -1.0 + 3.0 * _controller.value),
            ).createShader(bounds),
            child: child,
          );
        },
        child: _skeletonShape(base),
      ),
    );
  }

  Widget _skeletonShape(Color base) {
    Widget box(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return Row(
      children: [
        // 썸네일 (120 x 68 - 카드와 동일)
        box(120, 68),
        const SizedBox(width: 14),
        // 제목 2줄 + 메타 1줄
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              box(double.infinity, 12),
              const SizedBox(height: 8),
              box(140, 12),
              const SizedBox(height: 12),
              box(90, 10),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // 재생 버튼 자리
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: base, shape: BoxShape.circle),
        ),
      ],
    );
  }
}

/// shimmer 하이라이트를 좌→우로 이동시키는 그라데이션 변환.
class _SlidingGradient extends GradientTransform {
  const _SlidingGradient({required this.slide});

  /// -1.0(왼쪽 밖) → 2.0(오른쪽 밖) 범위로 이동.
  final double slide;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slide, 0, 0);
  }
}
