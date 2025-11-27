import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:projecti_fan_app/controllers/music_controller.dart';
import 'package:projecti_fan_app/model/music_model.dart';
import 'package:projecti_fan_app/widget/audio_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:get/get.dart' as GetX;

import 'audio_common.dart';

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);

  AudioPlayerHandler() {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _player.sequenceStateStream.listen(_updateMediaItem);

    await _player.setAudioSource(_playlist);
  }

  Future<void> clearQueue() async {
    await _playlist.clear();
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final audioSource = AudioSource.uri(
      Uri.parse(mediaItem.id),
      tag: mediaItem,
    );
    await _playlist.add(audioSource);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(PlaybackState(
      controls: [MediaControl.play],
      processingState: AudioProcessingState.idle,
    ));
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

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
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  Future<void> _initializeAudio() async {
    try {
      _audioHandler = AudioManager.instance.audioHandler;

      if (_audioHandler != null) {
        await _audioHandler!.clearQueue();
        await _loadAndPlayMusic();
      }
    } catch (e) {
      debugPrint("Error initializing audio: $e");
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
        duration: null,
      );

      await _audioHandler!.addQueueItem(mediaItem);
    } catch (e) {
      debugPrint("Error loading audio source: $e");
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
    _audioHandler?.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AudioTheme.backgroundLight,
              AudioTheme.backgroundMid,
              AudioTheme.background,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: _isLoading || _audioHandler == null
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AudioTheme.primary,
                    strokeWidth: 3,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      _buildHeader(context),
                      const Spacer(flex: 1),
                      _buildAlbumArt(),
                      const Spacer(flex: 1),
                      _buildTrackInfo(),
                      const SizedBox(height: 16),
                      _buildSeekBar(),
                      const SizedBox(height: 16),
                      _buildControlButtons(context),
                      const Spacer(flex: 1),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AudioTheme.surface.withAlpha(180),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AudioTheme.textPrimary,
                size: 28,
              ),
              onPressed: () => context.pop(),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AudioTheme.surface.withAlpha(180),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'NOW PLAYING',
                  style: TextStyle(
                    color: AudioTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.musicModel.name ?? '',
                  style: const TextStyle(
                    color: AudioTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AudioTheme.surface.withAlpha(180),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.favorite_border_rounded,
                color: AudioTheme.primary,
                size: 24,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // 화면 높이의 35% 또는 너비의 65% 중 작은 값 사용
    final size = (screenHeight * 0.35).clamp(150.0, screenWidth * 0.65);

    return Hero(
      tag: 'album_art_${widget.musicModel.title}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AudioTheme.primary.withAlpha(80),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: 5,
            ),
            BoxShadow(
              color: AudioTheme.primaryDark.withAlpha(50),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.network(
            widget.musicModel.thumbnail ?? '',
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: AudioTheme.surfaceTint,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AudioTheme.primary,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AudioTheme.surfaceTint,
                child: const Icon(
                  Icons.music_note_rounded,
                  size: 80,
                  color: AudioTheme.primary,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTrackInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AudioTheme.surface.withAlpha(200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            widget.musicModel.title ?? 'Unknown Title',
            style: const TextStyle(
              color: AudioTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            widget.musicModel.name ?? 'Unknown Artist',
            style: const TextStyle(
              color: AudioTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSeekBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AudioTheme.surface.withAlpha(180),
        borderRadius: BorderRadius.circular(16),
      ),
      child: StreamBuilder<PositionData>(
        stream: _audioHandler?.positionDataStream,
        builder: (context, snapshot) {
          final data = snapshot.data ??
              PositionData(Duration.zero, Duration.zero, Duration.zero);
          return SeekBar(
            duration: data.duration,
            position: data.position,
            bufferedPosition: data.bufferedPosition,
            onChangeEnd: _audioHandler?.seek,
          );
        },
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    final musicController = GetX.Get.find<MusicController>();

    return StreamBuilder<PlaybackState>(
      stream: _audioHandler?.playbackState,
      builder: (context, snapshot) {
        final playbackState = snapshot.data;
        final processingState =
            playbackState?.processingState ?? AudioProcessingState.idle;
        final playing = playbackState?.playing ?? false;

        return Column(
          children: [
            // 메인 컨트롤
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AudioTheme.surface.withAlpha(200),
                borderRadius: BorderRadius.circular(35),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 이전곡
                  _buildCircleButton(
                    icon: Icons.skip_previous_rounded,
                    size: 28,
                    enabled: musicController.musicIndex.value != 0,
                    onPressed: () {
                      musicController.musicIndex.value -= 1;
                      context.pushReplacement('/audioPage',
                          extra: musicController
                              .musicList[musicController.musicIndex.value]);
                    },
                  ),

                  // 재생/일시정지
                  _buildPlayButton(processingState, playing),

                  // 다음곡
                  _buildCircleButton(
                    icon: Icons.skip_next_rounded,
                    size: 28,
                    enabled: musicController.musicIndex.value !=
                        (musicController.musicList.length - 1),
                    onPressed: () {
                      musicController.musicIndex.value += 1;
                      context.pushReplacement('/audioPage',
                          extra: musicController
                              .musicList[musicController.musicIndex.value]);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 보조 컨트롤
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSmallButton(
                  icon: Icons.shuffle_rounded,
                  onPressed: () {},
                ),
                const SizedBox(width: 16),
                _buildSmallButton(
                  icon: Icons.repeat_rounded,
                  onPressed: () {},
                ),
                const SizedBox(width: 16),
                StreamBuilder<PlaybackState>(
                  stream: _audioHandler?.playbackState,
                  builder: (context, snapshot) {
                    final speed = snapshot.data?.speed ?? 1.0;
                    return _buildSpeedButton(speed);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required double size,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? AudioTheme.surfaceTint : AudioTheme.surfaceLight,
          border: Border.all(
            color: enabled
                ? AudioTheme.primary.withAlpha(100)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          size: size,
          color: enabled ? AudioTheme.primary : AudioTheme.textSecondary.withAlpha(100),
        ),
      ),
    );
  }

  Widget _buildPlayButton(AudioProcessingState processingState, bool playing) {
    if (processingState == AudioProcessingState.loading ||
        processingState == AudioProcessingState.buffering) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AudioTheme.primaryLight, AudioTheme.primary],
          ),
          boxShadow: [
            BoxShadow(
              color: AudioTheme.primary.withAlpha(100),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.all(18.0),
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        ),
      );
    }

    IconData iconData;
    VoidCallback onPressed;

    if (!playing) {
      iconData = Icons.play_arrow_rounded;
      onPressed = _audioHandler!.play;
    } else if (processingState != AudioProcessingState.completed) {
      iconData = Icons.pause_rounded;
      onPressed = _audioHandler!.pause;
    } else {
      iconData = Icons.replay_rounded;
      onPressed = () => _audioHandler!.seek(Duration.zero);
    }

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AudioTheme.primaryLight, AudioTheme.primary],
          ),
          boxShadow: [
            BoxShadow(
              color: AudioTheme.primary.withAlpha(120),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          iconData,
          size: 34,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSmallButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AudioTheme.surface.withAlpha(200),
          border: Border.all(
            color: AudioTheme.primary.withAlpha(60),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: AudioTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSpeedButton(double speed) {
    return GestureDetector(
      onTap: () {
        final newSpeed = speed >= 1.5 ? 0.5 : speed + 0.25;
        _audioHandler?.setSpeed(newSpeed);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AudioTheme.surface.withAlpha(200),
          border: Border.all(
            color: AudioTheme.primary.withAlpha(60),
            width: 1.5,
          ),
        ),
        child: Text(
          '${speed.toStringAsFixed(2)}x',
          style: const TextStyle(
            color: AudioTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
