import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:honeyz_fan_app/model/music_model.dart';
import 'package:honeyz_fan_app/widget/audio_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../font_style_sheet.dart';
import 'audio_common.dart';

// 백그라운드 오디오 핸들러 (기존과 동일)
class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);

  AudioPlayerHandler() {
    _init();
  }

  Future<void> _init() async {
    // AudioSession 설정
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // 플레이어 상태 변경 리스너
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _player.sequenceStateStream.listen(_updateMediaItem);

    // 플레이어에 플레이리스트 설정
    await _player.setAudioSource(_playlist);
  }

  // 플레이리스트 클리어 메서드 추가
  Future<void> clearQueue() async {
    await _playlist.clear();
  }

  // 오디오 소스 추가
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final audioSource = AudioSource.uri(
      Uri.parse(mediaItem.id),
      tag: mediaItem,
    );
    await _playlist.add(audioSource);
  }

  // 재생
  @override
  Future<void> play() => _player.play();

  // 일시정지
  @override
  Future<void> pause() => _player.pause();

  // 정지
  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(PlaybackState(
      controls: [MediaControl.play],
      processingState: AudioProcessingState.idle,
    ));
  }

  // 탐색
  @override
  Future<void> seek(Duration position) => _player.seek(position);

  // 속도 설정 메서드 추가
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  // PlaybackEvent를 PlaybackState로 변환
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  // 미디어 아이템 업데이트
  void _updateMediaItem(SequenceState? sequenceState) {
    final item = sequenceState?.currentSource?.tag as MediaItem?;
    if (item == null) return;

    mediaItem.add(item);
  }

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
        (position, buffered, duration) =>
            PositionData(position, buffered, duration ?? Duration.zero),
      );

  @override
  Future<void> onTaskRemoved() async {
    // 앱이 종료될 때 오디오 정리
    await stop();
  }
}

class BackgroundAudioWidget extends StatefulWidget {
  final MusicModel musicModel;

  const BackgroundAudioWidget({super.key, required this.musicModel});

  @override
  State<BackgroundAudioWidget> createState() => _BackgroundAudioWidgetState();
}

class _BackgroundAudioWidgetState extends State<BackgroundAudioWidget> {
  AudioPlayerHandler? _audioHandler;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
  }

  Future<void> _initializeAudio() async {
    try {
      // main에서 이미 초기화된 AudioService 핸들러 가져오기
      _audioHandler = AudioManager.instance.audioHandler;

      if (_audioHandler != null) {
        // 기존 큐 클리어하고 새 음악 로드
        await _audioHandler!.clearQueue();
        await _loadAndPlayMusic();
      }
    } catch (e) {
      print("Error initializing audio: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAndPlayMusic() async {
    try {
      String? audioURL = await extractAudioUrl(widget.musicModel.musicURL!);

      final mediaItem = MediaItem(
        id: audioURL!,
        title: widget.musicModel.title ?? 'Unknown Title',
        artist: widget.musicModel.name ?? 'Unknown Artist',
        artUri: Uri.parse(widget.musicModel.thumbnail ?? ''),
        duration: null, // 실제 재생 시 자동으로 설정됨
      );

      await _audioHandler!.addQueueItem(mediaItem);
    } catch (e) {
      print("Error loading audio source: $e");
    }
  }

  Future<String?> extractAudioUrl(String videoUrl) async {
    var youtube = YoutubeExplode();
    var streamManifest =
        await youtube.videos.streamsClient.getManifest(videoUrl);
    var audioOnlyStreams = streamManifest.audioOnly;
    var audioStream = audioOnlyStreams.withHighestBitrate();
    return audioStream.url.toString();
  }

  @override
  void dispose() {
    // dispose에서는 AudioService를 완전히 중지하지 않고,
    // 필요시 음악만 정지
    _audioHandler?.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0x0fff5e88).withOpacity(1.0),
      body: SafeArea(
        child: Center(
          child: _isLoading || _audioHandler == null
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 앨범 아트
                    Container(
                      height: 350,
                      width: 350,
                      decoration: BoxDecoration(
                        border: Border.all(width: 5.0, color: Colors.black),
                        borderRadius: BorderRadius.circular(7.0),
                      ),
                      child: Image.network(
                        widget.musicModel.thumbnail ?? '',
                        fit: BoxFit.fill,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.music_note, size: 100);
                        },
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // 제목과 아티스트
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          Text(
                            widget.musicModel.title ?? 'Unknown Title',
                            style: FontStyleSheet.musicTitle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.musicModel.name ?? 'Unknown Artist',
                            style: FontStyleSheet.musicArtistName,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 진행률 바
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: StreamBuilder<PositionData>(
                        stream: _audioHandler?.positionDataStream,
                        builder: (context, snapshot) {
                          final data = snapshot.data ??
                              PositionData(
                                  Duration.zero, Duration.zero, Duration.zero);
                          return Row(
                            children: [
                              Expanded(
                                child: SeekBar(
                                  duration: data.duration,
                                  position: data.position,
                                  bufferedPosition: data.bufferedPosition,
                                  onChangeEnd: _audioHandler?._player.seek,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // 컨트롤 버튼
                    BackgroundControlButtons(audioHandler: _audioHandler!),
                  ],
                ),
        ),
      ),
    );
  }
}

class BackgroundControlButtons extends StatelessWidget {
  final AudioPlayerHandler audioHandler;

  const BackgroundControlButtons({Key? key, required this.audioHandler})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, snapshot) {
        final playbackState = snapshot.data;
        final processingState =
            playbackState?.processingState ?? AudioProcessingState.idle;
        final playing = playbackState?.playing ?? false;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 볼륨 버튼 (간소화)
            IconButton(
              icon: const Icon(Icons.volume_up),
              onPressed: () {
                // 볼륨 조절 다이얼로그 표시
                _showVolumeDialog(context);
              },
            ),

            // 재생/일시정지 버튼
            if (processingState == AudioProcessingState.loading ||
                processingState == AudioProcessingState.buffering)
              Container(
                margin: const EdgeInsets.all(8.0),
                width: 64.0,
                height: 64.0,
                child: const CircularProgressIndicator(),
              )
            else if (!playing)
              IconButton(
                icon: const Icon(Icons.play_arrow),
                iconSize: 64.0,
                onPressed: audioHandler.play,
              )
            else if (processingState != AudioProcessingState.completed)
              IconButton(
                icon: const Icon(Icons.pause),
                iconSize: 64.0,
                onPressed: audioHandler.pause,
              )
            else
              IconButton(
                icon: const Icon(Icons.replay),
                iconSize: 64.0,
                onPressed: () => audioHandler.seek(Duration.zero),
              ),

            // 속도 조절 버튼
            StreamBuilder<PlaybackState>(
              stream: audioHandler.playbackState,
              builder: (context, snapshot) {
                final speed = snapshot.data?.speed ?? 1.0;
                return IconButton(
                  icon: Text(
                    "${speed.toStringAsFixed(1)}x",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    // 속도 조절 로직
                    final newSpeed = speed >= 1.5 ? 0.5 : speed + 0.25;
                    audioHandler.setSpeed(newSpeed);
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showVolumeDialog(BuildContext context) {
    // 볼륨 조절 다이얼로그 구현
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Volume Control'),
        content: const Text('Volume control will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
