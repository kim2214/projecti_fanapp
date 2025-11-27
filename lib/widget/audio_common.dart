import 'dart:math';
import 'package:flutter/material.dart';

// 밝은 시안 테마 (#30bcec 기반)
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

class SeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final Duration bufferedPosition;
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangeEnd;

  const SeekBar({
    Key? key,
    required this.duration,
    required this.position,
    required this.bufferedPosition,
    this.onChanged,
    this.onChangeEnd,
  }) : super(key: key);

  @override
  SeekBarState createState() => SeekBarState();
}

class SeekBarState extends State<SeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final position = _dragValue ?? widget.position.inMilliseconds.toDouble();
    final duration = widget.duration.inMilliseconds.toDouble();

    return Column(
      children: [
        // 슬라이더
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 5.0,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 7.0,
              elevation: 3.0,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18.0),
            activeTrackColor: AudioTheme.primary,
            inactiveTrackColor: AudioTheme.primary.withAlpha(51),
            thumbColor: Colors.white,
            overlayColor: AudioTheme.primary.withAlpha(40),
          ),
          child: Slider(
            min: 0.0,
            max: duration > 0 ? duration : 1.0,
            value: min(position, duration > 0 ? duration : 1.0).clamp(0.0, duration > 0 ? duration : 1.0),
            onChanged: (value) {
              setState(() {
                _dragValue = value;
              });
              widget.onChanged?.call(Duration(milliseconds: value.round()));
            },
            onChangeEnd: (value) {
              widget.onChangeEnd?.call(Duration(milliseconds: value.round()));
              setState(() {
                _dragValue = null;
              });
            },
          ),
        ),
        // 시간 표시
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(widget.position),
                style: const TextStyle(
                  color: AudioTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatDuration(widget.duration),
                style: const TextStyle(
                  color: AudioTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

class HiddenThumbComponentShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.zero;

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {}
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

void showSliderDialog({
  required BuildContext context,
  required String title,
  required int divisions,
  required double min,
  required double max,
  String valueSuffix = '',
  required double value,
  required Stream<double> stream,
  required ValueChanged<double> onChanged,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AudioTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AudioTheme.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: StreamBuilder<double>(
        stream: stream,
        builder: (context, snapshot) => SizedBox(
          height: 100.0,
          child: Column(
            children: [
              Text(
                '${snapshot.data?.toStringAsFixed(1)}$valueSuffix',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24.0,
                  color: AudioTheme.primary,
                ),
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AudioTheme.primary,
                  inactiveTrackColor: AudioTheme.primary.withAlpha(51),
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  divisions: divisions,
                  min: min,
                  max: max,
                  value: snapshot.data ?? value,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

T? ambiguate<T>(T? value) => value;
