// import 'package:audio_session/audio_session.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:honeyz_fan_app/model/music_model.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:rxdart/rxdart.dart';
// import 'package:youtube_explode_dart/youtube_explode_dart.dart';
//
// import '../font_style_sheet.dart';
// import 'audio_common.dart';
//
// class AudioWidget extends StatefulWidget {
//   final MusicModel musicModel;
//
//   const AudioWidget({super.key, required this.musicModel});
//
//   @override
//   State<AudioWidget> createState() => _AudioWidgetState();
// }
//
// class _AudioWidgetState extends State<AudioWidget> with WidgetsBindingObserver {
//   final _player = AudioPlayer();
//
//   @override
//   void initState() {
//     super.initState();
//     ambiguate(WidgetsBinding.instance)!.addObserver(this);
//     SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
//       statusBarColor: Colors.black,
//     ));
//   }
//
//   Future<bool> _init() async {
//     // Inform the operating system of our app's audio attributes etc.
//     // We pick a reasonable default for an app that plays speech.
//     final session = await AudioSession.instance;
//     await session.configure(const AudioSessionConfiguration.speech());
//     // Listen to errors during playback.
//     _player.playbackEventStream.listen((event) {},
//         onError: (Object e, StackTrace stackTrace) {
//       print('A stream error occurred: $e');
//     });
//     // Try to load audio from a source and catch any errors.
//     try {
//       String? audioURL = await extractAudioUrl(widget.musicModel.musicURL!);
//
//       // Set the audio url
//       await _player.setUrl(audioURL!);
//
//       // Set the initial volume
//       await _player.setVolume(1.0);
//     } on PlayerException catch (e) {
//       print("Error loading audio source: $e");
//     }
//     return true;
//   }
//
//   Future<String?> extractAudioUrl(String videoUrl) async {
//     var youtube = YoutubeExplode();
//
//     var streamManifest =
//         await youtube.videos.streamsClient.getManifest(videoUrl);
//
//     var audioOnlyStreams = streamManifest.audioOnly;
//
//     var audioStream = audioOnlyStreams.withHighestBitrate();
//
//     return audioStream.url.toString();
//   }
//
//   @override
//   void dispose() {
//     ambiguate(WidgetsBinding.instance)!.removeObserver(this);
//     // Release decoders and buffers back to the operating system making them
//     // available for other apps to use.
//     _player.dispose();
//     super.dispose();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused) {
//       // Release the player's resources when not in use. We use "stop" so that
//       // if the app resumes later, it will still remember what position to
//       // resume from.
//       _player.stop();
//     }
//   }
//
//   /// Collects the data useful for displaying in a seek bar, using a handy
//   /// feature of rx_dart to combine the 3 streams of interest into one.
//   Stream<PositionData> get _positionDataStream =>
//       Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
//           _player.positionStream,
//           _player.bufferedPositionStream,
//           _player.durationStream,
//           (position, bufferedPosition, duration) => PositionData(
//               position, bufferedPosition, duration ?? Duration.zero));
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0x0fff5e88).withOpacity(1.0),
//       body: SafeArea(
//         child:
//             // Display seek bar. Using StreamBuilder, this widget rebuilds
//             // each time the position, buffered position or duration changes.
//             Center(
//           child: FutureBuilder(
//             future: _init(),
//             builder: (BuildContext context, AsyncSnapshot snapshot) {
//               if (snapshot.hasData == false) {
//                 return Center(
//                   child: CircularProgressIndicator(
//                     backgroundColor: Color(0x0fff5e88).withOpacity(1.0),
//                   ),
//                 );
//               } else if (snapshot.hasError) {
//                 return Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text(
//                     'Error: ${snapshot.error}',
//                     style: TextStyle(fontSize: 15),
//                   ),
//                 );
//               } else {
//                 return Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       height: 350,
//                       width: 350,
//                       decoration: BoxDecoration(
//                         border: Border.all(width: 5.0, color: Colors.black),
//                         borderRadius: BorderRadius.circular(7.0),
//                       ),
//                       child: Image.network(
//                         widget.musicModel.thumbnail ?? '',
//                         fit: BoxFit.fill,
//                       ),
//                     ),
//                     SizedBox(
//                       height: 20.0,
//                     ),
//                     Text(
//                       widget.musicModel.title!,
//                       style: FontStyleSheet.musicTitle,
//                     ),
//                     Text(
//                       widget.musicModel.name!,
//                       style: FontStyleSheet.musicArtistName,
//                     ),
//                     const SizedBox(height: 16),
//                     StreamBuilder<PositionData>(
//                       stream: _positionDataStream,
//                       builder: (context, snapshot) {
//                         final positionData = snapshot.data;
//                         return Row(
//                           children: [
//                             Expanded(
//                               child: SeekBar(
//                                 duration:
//                                     positionData?.duration ?? Duration.zero,
//                                 position:
//                                     positionData?.position ?? Duration.zero,
//                                 bufferedPosition:
//                                     positionData?.bufferedPosition ??
//                                         Duration.zero,
//                                 onChangeEnd: _player.seek,
//                               ),
//                             ),
//                           ],
//                         );
//                       },
//                     ),
//                     // Display play/pause button and volume/speed sliders.
//                     ControlButtons(_player),
//                   ],
//                 );
//               }
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// /// Displays the play/pause button and volume/speed sliders.
// class ControlButtons extends StatelessWidget {
//   final AudioPlayer player;
//
//   const ControlButtons(this.player, {Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // Opens volume slider dialog
//         StreamBuilder<double>(
//           stream: player.volumeStream,
//           initialData: 0,
//           builder: (context, snapshot) {
//             return IconButton(
//               icon: Icon(
//                   snapshot.data == 1.0 ? Icons.volume_up : Icons.volume_off),
//               onPressed: () {
//                 if (snapshot.data == 1.0) {
//                   player.setVolume(0.0);
//                 } else {
//                   player.setVolume(1.0);
//                 }
//               },
//             );
//           },
//         ),
//
//         /// This StreamBuilder rebuilds whenever the player state changes, which
//         /// includes the playing/paused state and also the
//         /// loading/buffering/ready state. Depending on the state we show the
//         /// appropriate button or loading indicator.
//         StreamBuilder<PlayerState>(
//           stream: player.playerStateStream,
//           builder: (context, snapshot) {
//             final playerState = snapshot.data;
//             final processingState = playerState?.processingState;
//             final playing = playerState?.playing;
//             if (processingState == ProcessingState.loading ||
//                 processingState == ProcessingState.buffering) {
//               return Container(
//                 margin: const EdgeInsets.all(8.0),
//                 width: 64.0,
//                 height: 64.0,
//                 child: const CircularProgressIndicator(),
//               );
//             } else if (playing != true) {
//               return IconButton(
//                 icon: const Icon(Icons.play_arrow),
//                 iconSize: 64.0,
//                 onPressed: player.play,
//               );
//             } else if (processingState != ProcessingState.completed) {
//               return IconButton(
//                 icon: const Icon(Icons.pause),
//                 iconSize: 64.0,
//                 onPressed: player.pause,
//               );
//             } else {
//               return IconButton(
//                 icon: const Icon(Icons.replay),
//                 iconSize: 64.0,
//                 onPressed: () => player.seek(Duration.zero),
//               );
//             }
//           },
//         ),
//         // Opens speed slider dialog
//         StreamBuilder<double>(
//           stream: player.speedStream,
//           builder: (context, snapshot) => IconButton(
//             icon: Text("${snapshot.data?.toStringAsFixed(1)}x",
//                 style: const TextStyle(fontWeight: FontWeight.bold)),
//             onPressed: () {
//               showSliderDialog(
//                 context: context,
//                 title: "Adjust speed",
//                 divisions: 10,
//                 min: 0.5,
//                 max: 1.5,
//                 value: player.speed,
//                 stream: player.speedStream,
//                 onChanged: player.setSpeed,
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }

// import 'package:audio_service/audio_service.dart';
// import 'package:audio_session/audio_session.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:honeyz_fan_app/model/music_model.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:rxdart/rxdart.dart';
// import 'package:youtube_explode_dart/youtube_explode_dart.dart';
//
// import '../font_style_sheet.dart';
// import 'audio_common.dart';
//
// // 백그라운드 오디오 핸들러
// class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
//   final _player = AudioPlayer();
//   final _playlist = ConcatenatingAudioSource(children: []);
//
//   AudioPlayerHandler() {
//     _init();
//   }
//
//   Future<void> _init() async {
//     try {
//       // AudioSession 설정
//       final session = await AudioSession.instance;
//       await session.configure(const AudioSessionConfiguration.music());
//
//       // 플레이어 상태 변경 리스너
//       _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
//       _player.sequenceStateStream.listen(_updateMediaItem);
//
//       // 플레이어에 플레이리스트 설정
//       await _player.setAudioSource(_playlist);
//     } catch (e) {
//       print('AudioPlayerHandler 초기화 오류: $e');
//     }
//   }
//
//   // 오디오 소스 추가 (기존 항목 제거 후 새로 추가)
//   Future<void> addQueueItem(MediaItem mediaItem) async {
//     try {
//       // 기존 항목들 제거
//       await _playlist.clear();
//
//       final audioSource = AudioSource.uri(
//         Uri.parse(mediaItem.id),
//         tag: mediaItem,
//       );
//       await _playlist.add(audioSource);
//
//       // MediaItem 미리 설정
//       this.mediaItem.add(mediaItem);
//     } catch (e) {
//       print('오디오 소스 추가 오류: $e');
//     }
//   }
//
//   // 재생
//   @override
//   Future<void> play() async {
//     try {
//       await _player.play();
//     } catch (e) {
//       print('재생 오류: $e');
//     }
//   }
//
//   // 일시정지
//   @override
//   Future<void> pause() async {
//     try {
//       await _player.pause();
//     } catch (e) {
//       print('일시정지 오류: $e');
//     }
//   }
//
//   // 정지
//   @override
//   Future<void> stop() async {
//     try {
//       await _player.stop();
//       playbackState.add(PlaybackState(
//         controls: [MediaControl.play],
//         processingState: AudioProcessingState.idle,
//       ));
//     } catch (e) {
//       print('정지 오류: $e');
//     }
//   }
//
//   // 탐색
//   @override
//   Future<void> seek(Duration position) async {
//     try {
//       await _player.seek(position);
//     } catch (e) {
//       print('탐색 오류: $e');
//     }
//   }
//
//   // 속도 설정 메서드 추가
//   Future<void> setSpeed(double speed) async {
//     try {
//       await _player.setSpeed(speed);
//     } catch (e) {
//       print('속도 설정 오류: $e');
//     }
//   }
//
//   // PlaybackEvent를 PlaybackState로 변환
//   PlaybackState _transformEvent(PlaybackEvent event) {
//     return PlaybackState(
//       controls: [
//         MediaControl.rewind,
//         if (_player.playing) MediaControl.pause else MediaControl.play,
//         MediaControl.stop,
//         MediaControl.fastForward,
//       ],
//       systemActions: const {
//         MediaAction.seek,
//         MediaAction.seekForward,
//         MediaAction.seekBackward,
//       },
//       androidCompactActionIndices: const [0, 1, 3],
//       processingState: const {
//         ProcessingState.idle: AudioProcessingState.idle,
//         ProcessingState.loading: AudioProcessingState.loading,
//         ProcessingState.buffering: AudioProcessingState.buffering,
//         ProcessingState.ready: AudioProcessingState.ready,
//         ProcessingState.completed: AudioProcessingState.completed,
//       }[_player.processingState]!,
//       playing: _player.playing,
//       updatePosition: _player.position,
//       bufferedPosition: _player.bufferedPosition,
//       speed: _player.speed,
//       queueIndex: event.currentIndex,
//     );
//   }
//
//   // 미디어 아이템 업데이트
//   void _updateMediaItem(SequenceState? sequenceState) {
//     final item = sequenceState?.currentSource?.tag as MediaItem?;
//     if (item == null) return;
//
//     mediaItem.add(item);
//   }
//
//   @override
//   Future<void> onTaskRemoved() async {
//     // 앱이 종료될 때 오디오 정리
//     await _player.dispose();
//     await super.stop();
//   }
//
//   // 리소스 정리
//   void dispose() {
//     _player.dispose();
//   }
// }
//
// class BackgroundAudioWidget extends StatefulWidget {
//   final MusicModel musicModel;
//
//   const BackgroundAudioWidget({super.key, required this.musicModel});
//
//   @override
//   State<BackgroundAudioWidget> createState() => _BackgroundAudioWidgetState();
// }
//
// class _BackgroundAudioWidgetState extends State<BackgroundAudioWidget> {
//   AudioPlayerHandler? _audioHandler;
//   bool _isInitialized = false;
//   bool _hasError = false;
//   String? _errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     // _initAudioService();
//     SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
//       statusBarColor: Colors.black,
//     ));
//   }
//
//   // Future<void> _initAudioService() async {
//   //   try {
//   //     _audioHandler = await AudioService.init(
//   //       builder: () => AudioPlayerHandler(),
//   //       config: const AudioServiceConfig(
//   //         androidNotificationChannelId: 'com.devkim.honeyz_fan_app.audio',
//   //         androidNotificationChannelName: 'Honeyz Music Player',
//   //         androidNotificationOngoing: true,
//   //         androidShowNotificationBadge: true,
//   //         androidNotificationClickStartsActivity: true,
//   //         androidNotificationIcon: 'mipmap/honeyz_fanapp_icon',
//   //       ),
//   //     );
//   //
//   //     await _loadAndPlayMusic();
//   //
//   //     if (mounted) {
//   //       setState(() {
//   //         _isInitialized = true;
//   //       });
//   //     }
//   //   } catch (e) {
//   //     print('AudioService 초기화 오류: $e');
//   //     if (mounted) {
//   //       setState(() {
//   //         _hasError = true;
//   //         _errorMessage = 'AudioService 초기화 실패: $e';
//   //       });
//   //     }
//   //   }
//   // }
//
//   Future<void> _loadAndPlayMusic() async {
//     if (_audioHandler == null) return;
//
//     try {
//       String? audioURL = await extractAudioUrl(widget.musicModel.musicURL!);
//
//       if (audioURL == null) {
//         throw Exception('오디오 URL을 가져올 수 없습니다.');
//       }
//
//       final mediaItem = MediaItem(
//         id: audioURL,
//         title: widget.musicModel.title ?? 'Unknown Title',
//         artist: widget.musicModel.name ?? 'Unknown Artist',
//         artUri: widget.musicModel.thumbnail != null
//             ? Uri.parse(widget.musicModel.thumbnail!)
//             : null,
//         duration: null, // 실제 재생 시 자동으로 설정됨
//       );
//
//       await _audioHandler!.addQueueItem(mediaItem);
//     } catch (e) {
//       print("오디오 로딩 오류: $e");
//       if (mounted) {
//         setState(() {
//           _hasError = true;
//           _errorMessage = '음악 로딩 실패: $e';
//         });
//       }
//     }
//   }
//
//   Future<String?> extractAudioUrl(String videoUrl) async {
//     try {
//       var youtube = YoutubeExplode();
//
//       // URL에서 비디오 ID 추출
//       String videoId;
//       if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')) {
//         videoId = VideoId.parseVideoId(videoUrl) ?? '';
//       } else {
//         videoId = videoUrl; // 이미 비디오 ID인 경우
//       }
//
//       if (videoId.isEmpty) {
//         throw Exception('유효하지 않은 YouTube URL입니다.');
//       }
//
//       var streamManifest = await youtube.videos.streamsClient.getManifest(videoId);
//       var audioOnlyStreams = streamManifest.audioOnly;
//
//       if (audioOnlyStreams.isEmpty) {
//         throw Exception('오디오 스트림을 찾을 수 없습니다.');
//       }
//
//       var audioStream = audioOnlyStreams.withHighestBitrate();
//       youtube.close(); // 리소스 정리
//
//       return audioStream.url.toString();
//     } catch (e) {
//       print('YouTube URL 추출 오류: $e');
//       return null;
//     }
//   }
//
//   @override
//   void dispose() {
//     _audioHandler?.dispose();
//     AudioService.stop();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFff5e88),
//       body: SafeArea(
//         child: Center(
//           child: _hasError
//               ? _buildErrorWidget()
//               : !_isInitialized || _audioHandler == null
//               ? const CircularProgressIndicator()
//               : _buildMusicPlayer(),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildErrorWidget() {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         const Icon(
//           Icons.error_outline,
//           size: 64,
//           color: Colors.white,
//         ),
//         const SizedBox(height: 16),
//         Text(
//           '오류가 발생했습니다',
//           style: FontStyleSheet.musicTitle.copyWith(color: Colors.white),
//         ),
//         const SizedBox(height: 8),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 32),
//           child: Text(
//             _errorMessage ?? '알 수 없는 오류',
//             style: FontStyleSheet.musicArtistName.copyWith(color: Colors.white70),
//             textAlign: TextAlign.center,
//           ),
//         ),
//         const SizedBox(height: 24),
//         ElevatedButton(
//           onPressed: () {
//             setState(() {
//               _hasError = false;
//               _errorMessage = null;
//               _isInitialized = false;
//             });
//             // _initAudioService();
//           },
//           child: const Text('다시 시도'),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildMusicPlayer() {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         // 앨범 아트
//         Container(
//           height: 350,
//           width: 350,
//           decoration: BoxDecoration(
//             border: Border.all(width: 5.0, color: Colors.black),
//             borderRadius: BorderRadius.circular(7.0),
//           ),
//           child: widget.musicModel.thumbnail != null
//               ? Image.network(
//             widget.musicModel.thumbnail!,
//             fit: BoxFit.cover,
//             errorBuilder: (context, error, stackTrace) {
//               return Container(
//                 color: Colors.grey[300],
//                 child: const Icon(
//                   Icons.music_note,
//                   size: 80,
//                   color: Colors.grey,
//                 ),
//               );
//             },
//             loadingBuilder: (context, child, loadingProgress) {
//               if (loadingProgress == null) return child;
//               return Container(
//                 color: Colors.grey[300],
//                 child: const Center(
//                   child: CircularProgressIndicator(),
//                 ),
//               );
//             },
//           )
//               : Container(
//             color: Colors.grey[300],
//             child: const Icon(
//               Icons.music_note,
//               size: 80,
//               color: Colors.grey,
//             ),
//           ),
//         ),
//         const SizedBox(height: 20.0),
//
//         // 제목과 아티스트
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: Column(
//             children: [
//               Text(
//                 widget.musicModel.title ?? 'Unknown Title',
//                 style: FontStyleSheet.musicTitle.copyWith(color: Colors.white),
//                 textAlign: TextAlign.center,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 widget.musicModel.name ?? 'Unknown Artist',
//                 style: FontStyleSheet.musicArtistName.copyWith(color: Colors.white70),
//                 textAlign: TextAlign.center,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 32),
//
//         // 진행률 바
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: StreamBuilder<PlaybackState>(
//             stream: _audioHandler!.playbackState,
//             builder: (context, snapshot) {
//               final playbackState = snapshot.data;
//               final position = playbackState?.updatePosition ?? Duration.zero;
//               final bufferedPosition = playbackState?.bufferedPosition ?? Duration.zero;
//
//               return StreamBuilder<MediaItem?>(
//                 stream: _audioHandler!.mediaItem,
//                 builder: (context, mediaSnapshot) {
//                   final duration = mediaSnapshot.data?.duration ?? Duration.zero;
//
//                   return SeekBar(
//                     duration: duration,
//                     position: position,
//                     bufferedPosition: bufferedPosition,
//                     onChangeEnd: (newPosition) {
//                       _audioHandler!.seek(newPosition);
//                     },
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//
//         const SizedBox(height: 24),
//
//         // 컨트롤 버튼
//         BackgroundControlButtons(audioHandler: _audioHandler!),
//       ],
//     );
//   }
// }
//
// class BackgroundControlButtons extends StatelessWidget {
//   final AudioPlayerHandler audioHandler;
//
//   const BackgroundControlButtons({Key? key, required this.audioHandler}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<PlaybackState>(
//       stream: audioHandler.playbackState,
//       builder: (context, snapshot) {
//         final playbackState = snapshot.data;
//         final processingState = playbackState?.processingState ?? AudioProcessingState.idle;
//         final playing = playbackState?.playing ?? false;
//
//         return Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             // 볼륨 버튼
//             IconButton(
//               icon: const Icon(Icons.volume_up, color: Colors.white),
//               onPressed: () {
//                 // 볼륨 조절 다이얼로그 표시
//                 _showVolumeDialog(context);
//               },
//             ),
//
//             // 재생/일시정지 버튼
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.2),
//                 shape: BoxShape.circle,
//               ),
//               child: _buildPlayPauseButton(processingState, playing),
//             ),
//
//             // 속도 조절 버튼
//             StreamBuilder<PlaybackState>(
//               stream: audioHandler.playbackState,
//               builder: (context, snapshot) {
//                 final speed = snapshot.data?.speed ?? 1.0;
//                 return IconButton(
//                   icon: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       "${speed.toStringAsFixed(1)}x",
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                   onPressed: () {
//                     _showSpeedDialog(context, speed);
//                   },
//                 );
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Widget _buildPlayPauseButton(AudioProcessingState processingState, bool playing) {
//     if (processingState == AudioProcessingState.loading ||
//         processingState == AudioProcessingState.buffering) {
//       return Container(
//         margin: const EdgeInsets.all(8.0),
//         width: 64.0,
//         height: 64.0,
//         child: const CircularProgressIndicator(color: Colors.white),
//       );
//     } else if (!playing) {
//       return IconButton(
//         icon: const Icon(Icons.play_arrow, color: Colors.white),
//         iconSize: 64.0,
//         onPressed: audioHandler.play,
//       );
//     } else if (processingState != AudioProcessingState.completed) {
//       return IconButton(
//         icon: const Icon(Icons.pause, color: Colors.white),
//         iconSize: 64.0,
//         onPressed: audioHandler.pause,
//       );
//     } else {
//       return IconButton(
//         icon: const Icon(Icons.replay, color: Colors.white),
//         iconSize: 64.0,
//         onPressed: () => audioHandler.seek(Duration.zero),
//       );
//     }
//   }
//
//   void _showVolumeDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('볼륨'),
//         content: const Text('시스템 볼륨을 사용해주세요.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('확인'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showSpeedDialog(BuildContext context, double currentSpeed) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('재생 속도'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
//             return ListTile(
//               title: Text('${speed}x'),
//               leading: Radio<double>(
//                 value: speed,
//                 groupValue: currentSpeed,
//                 onChanged: (value) {
//                   if (value != null) {
//                     audioHandler.setSpeed(value);
//                     Navigator.pop(context);
//                   }
//                 },
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
// }

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
    var streamManifest = await youtube.videos.streamsClient.getManifest(videoUrl);
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
                child: StreamBuilder<PlaybackState>(
                  stream: _audioHandler!.playbackState,
                  builder: (context, snapshot) {
                    final playbackState = snapshot.data;
                    final position = playbackState?.updatePosition ?? Duration.zero;
                    final bufferedPosition = playbackState?.bufferedPosition ?? Duration.zero;

                    return StreamBuilder<MediaItem?>(
                      stream: _audioHandler!.mediaItem,
                      builder: (context, mediaSnapshot) {
                        final duration = mediaSnapshot.data?.duration ?? Duration.zero;

                        return SeekBar(
                          duration: duration,
                          position: position,
                          bufferedPosition: bufferedPosition,
                          onChangeEnd: (newPosition) {
                            _audioHandler!.seek(newPosition);
                          },
                        );
                      },
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

  const BackgroundControlButtons({Key? key, required this.audioHandler}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, snapshot) {
        final playbackState = snapshot.data;
        final processingState = playbackState?.processingState ?? AudioProcessingState.idle;
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