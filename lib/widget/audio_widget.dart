import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'audio_common.dart';

class AudioWidget extends StatefulWidget {
  final String? musicURL;
  final String? musicTitle;
  final String? imgUrl;

  const AudioWidget({
    super.key,
    required this.musicURL,
    required this.musicTitle,
    required this.imgUrl,
  });

  @override
  State<AudioWidget> createState() => _AudioWidgetState();
}

class _AudioWidgetState extends State<AudioWidget> with WidgetsBindingObserver {
  final _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    ambiguate(WidgetsBinding.instance)!.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
    // _init();
  }

  Future<bool> _init() async {
    // Inform the operating system of our app's audio attributes etc.
    // We pick a reasonable default for an app that plays speech.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    // Listen to errors during playback.
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });
    // Try to load audio from a source and catch any errors.
    try {
      String? audioURL = await extractAudioUrl(widget.musicURL!);

      // Set the audio url
      await _player.setUrl(audioURL!);

      // Set the initial volume
      await _player.setVolume(0.5);
    } on PlayerException catch (e) {
      print("Error loading audio source: $e");
    }
    return true;
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
    ambiguate(WidgetsBinding.instance)!.removeObserver(this);
    // Release decoders and buffers back to the operating system making them
    // available for other apps to use.
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Release the player's resources when not in use. We use "stop" so that
      // if the app resumes later, it will still remember what position to
      // resume from.
      _player.stop();
    }
  }

  /// Collects the data useful for displaying in a seek bar, using a handy
  /// feature of rx_dart to combine the 3 streams of interest into one.
  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          _player.positionStream,
          _player.bufferedPositionStream,
          _player.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display seek bar. Using StreamBuilder, this widget rebuilds
            // each time the position, buffered position or duration changes.
            FutureBuilder(
              future: _init(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData == false) {
                  return Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        backgroundColor: Color(0x0fff5e88).withOpacity(0.8),
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(fontSize: 15),
                    ),
                  );
                } else {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.musicTitle!),
                      SizedBox(
                        height: 200,
                        width: 300,
                        child: Image.network(widget.imgUrl ?? ''),
                      ),

                      const SizedBox(height: 16),
                      StreamBuilder<PositionData>(
                        stream: _positionDataStream,
                        builder: (context, snapshot) {
                          final positionData = snapshot.data;
                          Duration remaining = (positionData?.duration !=
                                      null &&
                                  positionData?.position != null)
                              ? positionData!.duration - positionData.position
                              : Duration.zero;
                          return Row(
                            children: [
                              Expanded(
                                child: SeekBar(
                                  duration:
                                      positionData?.duration ?? Duration.zero,
                                  position:
                                      positionData?.position ?? Duration.zero,
                                  bufferedPosition:
                                      positionData?.bufferedPosition ??
                                          Duration.zero,
                                  onChangeEnd: _player.seek,
                                ),
                              ),
                              Text(
                                RegExp(r'((^0*[1-9]d*:)?d{2}:d{2}).d+$')
                                        .firstMatch("$remaining")
                                        ?.group(1) ??
                                    '$remaining',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: Colors.white),
                              ),
                            ],
                          );
                        },
                      ),

                      // Display play/pause button and volume/speed sliders.
                      ControlButtons(_player),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays the play/pause button and volume/speed sliders.
class ControlButtons extends StatelessWidget {
  final AudioPlayer player;

  const ControlButtons(this.player, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Opens volume slider dialog
        IconButton(
          icon: const Icon(Icons.volume_up),
          onPressed: () {
            showSliderDialog(
              context: context,
              title: "Adjust volume",
              divisions: 10,
              min: 0.0,
              max: 1.0,
              value: player.volume,
              stream: player.volumeStream,
              onChanged: player.setVolume,
            );
          },
        ),

        /// This StreamBuilder rebuilds whenever the player state changes, which
        /// includes the playing/paused state and also the
        /// loading/buffering/ready state. Depending on the state we show the
        /// appropriate button or loading indicator.
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return Container(
                margin: const EdgeInsets.all(8.0),
                width: 64.0,
                height: 64.0,
                child: const CircularProgressIndicator(),
              );
            } else if (playing != true) {
              return IconButton(
                icon: const Icon(Icons.play_arrow),
                iconSize: 64.0,
                onPressed: player.play,
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                icon: const Icon(Icons.pause),
                iconSize: 64.0,
                onPressed: player.pause,
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.replay),
                iconSize: 64.0,
                onPressed: () => player.seek(Duration.zero),
              );
            }
          },
        ),
        // Opens speed slider dialog
        StreamBuilder<double>(
          stream: player.speedStream,
          builder: (context, snapshot) => IconButton(
            icon: Text("${snapshot.data?.toStringAsFixed(1)}x",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              showSliderDialog(
                context: context,
                title: "Adjust speed",
                divisions: 10,
                min: 0.5,
                max: 1.5,
                value: player.speed,
                stream: player.speedStream,
                onChanged: player.setSpeed,
              );
            },
          ),
        ),
      ],
    );
  }
}
