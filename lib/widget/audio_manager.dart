import 'package:audio_service/audio_service.dart';
import 'package:honeyz_fan_app/widget/audio_widget.dart';

// AudioManager 싱글톤 클래스
class AudioManager {
  static AudioManager? _instance;
  static AudioPlayerHandler? _audioHandler;

  static AudioManager get instance {
    _instance ??= AudioManager._internal();
    return _instance!;
  }

  AudioManager._internal();

  // AudioService 초기화 (main에서 한 번만 호출)
  static Future<void> initialize() async {
    if (_audioHandler == null) {
      _audioHandler = await AudioService.init(
        builder: () => AudioPlayerHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.devkim.honeyz_fan_app.channel.audio',
          androidNotificationChannelName: 'Music Player',
          androidNotificationOngoing: true,
          androidShowNotificationBadge: true,
          androidNotificationClickStartsActivity: true,
          androidNotificationIcon: 'mipmap/projecti_fanapp_icon',
        ),
      ) as AudioPlayerHandler;
    }
  }

  // AudioHandler 가져오기
  AudioPlayerHandler? get audioHandler => _audioHandler;

  // AudioHandler가 초기화되었는지 확인
  bool get isInitialized => _audioHandler != null;
}