import 'package:flutter/material.dart';

/// 라이브 카드 상단의 방송 썸네일 (16:9). URL이 없거나 로드에 실패하면 자리를
/// 차지하지 않고 사라진다 — 썸네일은 보조 정보라 카드 나머지는 그대로 그려진다.
class LiveThumbnail extends StatelessWidget {
  final String? url;
  final double radius;

  const LiveThumbnail({super.key, required this.url, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    final src = url;
    if (src == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            src,
            fit: BoxFit.cover,
            // 화면 폭만큼만 디코드 — 480px 원본을 그대로 메모리에 올리지 않는다.
            cacheWidth: 720,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
