import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

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

class _AudioWidgetState extends State<AudioWidget> {
  // String imgUrl =
  //     'https://firebasestorage.googleapis.com/v0/b/new-ml-6c02d.appspot.com/o/lessonAssets%2Fcs3%2Fch7%2Fls4%2Fearth.jpeg?alt=media&token=b9ce6139-5e08-495d-b74f-9dfce09e86e2';
  // String url =
  //     'https://files.freemusicarchive.org//storage-freemusicarchive-org//tracks//CAsMyXsiK0RkmsBG2K75J4wdewYDJElKJCe1tSQM.mp3';

  // Declare AudioPlayer variable
  late AudioPlayer player;
  bool isPlaying = false;
  double volume = 0.5;
  bool isVolumeDisabled = false;

  // String? musicTitle = '';
  // String? imgUrl;

  @override
  void initState() {
    super.initState();
    // _initialize();
  }

  Future<String?> extractAudioUrl(String videoUrl) async {
    var youtube = YoutubeExplode();
    // video = await youtube.videos.get(videoUrl);

    var streamManifest =
        await youtube.videos.streamsClient.getManifest(videoUrl);

    var audioOnlyStreams = streamManifest.audioOnly;

    var audioStream = audioOnlyStreams.withHighestBitrate();

    return audioStream.url.toString();
  }

  Future<String> getVideoTitle(String videoUrl) async {
    try {
      var youtube = YoutubeExplode();
      var video = await youtube.videos.get(videoUrl);

      // Get the video title
      var title = video.title;

      // Close the YoutubeExplode client
      youtube.close();

      return title;
    } catch (e) {
      print('Error: $e');
      return 'Error retrieving video title';
    }
  }

  // Future<String> getVideoImage(String videoUrl) async {
  //   try {
  //     var youtube = YoutubeExplode();
  //     var video = await youtube.videos.get(videoUrl);
  //
  //     // Get the video title
  //     var imageUrl = video.thumbnails.maxResUrl;
  //
  //     // Close the YoutubeExplode client
  //     youtube.close();
  //
  //     return imageUrl;
  //   } catch (e) {
  //     print('Error: $e');
  //     return 'Error retrieving video title';
  //   }
  // }

  Future<bool> _initialize() async {
    // Instantiate AudioPlayer class
    player = AudioPlayer();

    String? audioURL = await extractAudioUrl(widget.musicURL!);

    // musicTitle =
    //     await getVideoTitle('https://www.youtube.com/watch?v=XY4mPKSe1zE');
    //
    // imgUrl = await getVideoImage('https://www.youtube.com/watch?v=XY4mPKSe1zE');

    // Set the audio url
    await player.setUrl(audioURL!);

    // Set the initial volume
    await player.setVolume(volume);
    // setState(() {});
    return true;
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  void _disableVolume() async {
    // Set volume to 0
    await player.setVolume(0);
    setState(() {
      if (volume > 0) {
        isVolumeDisabled = true;
      }
    });
  }

  void _activateVolume() async {
    // Set volume to previous value before it was 0
    await player.setVolume(volume);
    setState(() {
      isVolumeDisabled = false;
    });
  }

  IconData _getVolumeIcon() {
    return (player.volume == 0) ? Icons.volume_off : Icons.volume_up_rounded;
  }

  void _playAudio() async {
    setState(() {
      isPlaying = true;
    });

    // Play the audio
    await player.play();
  }

  void _pauseAudio() async {
    setState(() {
      isPlaying = false;
    });

    // Pause the audio
    await player.pause();
  }

  IconData _getPlayPauseIcon() {
    return (isPlaying) ? Icons.pause : Icons.play_arrow;
  }

  // Listen for current audio play position,
  // Listen for buffer position,
  // Listen for max audio length
  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          player.positionStream,
          player.bufferedPositionStream,
          player.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: 0.0,
          leading: BackButton(
            onPressed: () {
              player.dispose();
              context.pop();
            },
          ),
          backgroundColor: Colors.white,
        ),
        body: FutureBuilder(
            future: _initialize(),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            switch (isPlaying) {
                              case true:
                                return _pauseAudio();
                              default:
                                return _playAudio();
                            }
                          },
                          icon: Icon(_getPlayPauseIcon(),
                              size: 50, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<PositionData>(
                      stream: _positionDataStream,
                      builder: (context, snapshot) {
                        final positionData = snapshot.data;
                        Duration remaining = (positionData?.duration != null &&
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
                                onChangeEnd: player.seek,
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            switch (isVolumeDisabled) {
                              case true:
                                return _activateVolume();
                              default:
                                return _disableVolume();
                            }
                          },
                          icon: Icon(_getVolumeIcon(),
                              size: 30, color: Colors.white),
                        ),
                        Expanded(
                          child: Slider(
                            value: player.volume,
                            max: 1,
                            min: 0,
                            onChanged: (value) async {
                              setState(() {
                                volume = value;
                              });
                              await player.setVolume(value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
            }));
  }
}

// The code below can be found in
// just_audio github repository
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
  late SliderThemeData _sliderThemeData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _sliderThemeData = SliderTheme.of(context).copyWith(
      trackHeight: 2.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SliderTheme(
          data: _sliderThemeData.copyWith(
            thumbShape: HiddenThumbComponentShape(),
            activeTrackColor: Colors.blue.shade100,
            inactiveTrackColor: Colors.grey.shade300,
          ),
          child: ExcludeSemantics(
            child: Slider(
              min: 0.0,
              max: widget.duration.inMilliseconds.toDouble(),
              value: min(widget.bufferedPosition.inMilliseconds.toDouble(),
                  widget.duration.inMilliseconds.toDouble()),
              onChanged: (value) {
                setState(() {
                  _dragValue = value;
                });
                if (widget.onChanged != null) {
                  widget.onChanged!(Duration(milliseconds: value.round()));
                }
              },
              onChangeEnd: (value) {
                if (widget.onChangeEnd != null) {
                  widget.onChangeEnd!(Duration(milliseconds: value.round()));
                }
                _dragValue = null;
              },
            ),
          ),
        ),
        SliderTheme(
          data: _sliderThemeData.copyWith(
            inactiveTrackColor: Colors.transparent,
          ),
          child: Slider(
            min: 0.0,
            max: widget.duration.inMilliseconds.toDouble(),
            value: min(_dragValue ?? widget.position.inMilliseconds.toDouble(),
                widget.duration.inMilliseconds.toDouble()),
            onChanged: (value) {
              setState(() {
                _dragValue = value;
              });
              if (widget.onChanged != null) {
                widget.onChanged!(Duration(milliseconds: value.round()));
              }
            },
            onChangeEnd: (value) {
              if (widget.onChangeEnd != null) {
                widget.onChangeEnd!(Duration(milliseconds: value.round()));
              }
              _dragValue = null;
            },
          ),
        ),
      ],
    );
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
