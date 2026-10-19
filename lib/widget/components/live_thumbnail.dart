import 'package:flutter/material.dart';

/// 라이브 카드 상단의 방송 썸네일 (16:9). URL이 없거나 로드에 실패하면 자리를
/// 차지하지 않고 사라진다 — 썸네일은 보조 정보라 카드 나머지는 그대로 그려진다.
class LiveThumbnail extends StatefulWidget {
  final String? url;
  final double radius;

  const LiveThumbnail({super.key, required this.url, this.radius = 12});

  @override
  State<LiveThumbnail> createState() => _LiveThumbnailState();
}

class _LiveThumbnailState extends State<LiveThumbnail> {
  // 로드 실패한 URL. errorBuilder만으론 바깥 16:9 칸·여백이 남아 빈칸이
  // 보였다 — 실패하면 칸째 접는다. 새 URL(다음 갱신)이 오면 다시 시도한다.
  String? _failedUrl;

  @override
  Widget build(BuildContext context) {
    final src = widget.url;
    if (src == null || src == _failedUrl) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            src,
            fit: BoxFit.cover,
            // 화면 폭만큼만 디코드 — 480px 원본을 그대로 메모리에 올리지 않는다.
            cacheWidth: 720,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) {
              // errorBuilder는 build 중에 불리므로 접기는 다음 프레임에 한다.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && widget.url == src) {
                  setState(() => _failedUrl = src);
                }
              });
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
