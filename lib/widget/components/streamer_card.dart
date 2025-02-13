import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyz_fan_app/model/honeyz_model.dart';

List<String> assetName = [
  "honeychurros",
  "ayauke",
  "damyui",
  "ddddragon",
  "ohwayo",
  "mangnae"
];

List<String> honeyzName = [
  "허니츄러스",
  "아야",
  "담유이",
  "디디디용",
  "오화요",
  "망내",
];

class StreamerCard extends StatelessWidget {
  final int index;
  final HoneyzModel streamer;

  const StreamerCard({
    super.key,
    required this.index,
    required this.streamer,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push('/streamerDetail', extra: streamer);
      },
      child: Column(
        children: [
          Image.asset('assets/${assetName[index]}_profile.png'),
          SizedBox(
            height: 20,
          ),
          Text(honeyzName[index]),
        ],
      ),
    );
  }
}
