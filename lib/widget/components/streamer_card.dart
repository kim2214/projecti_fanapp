import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyz_fan_app/font_style_sheet.dart';
import 'package:honeyz_fan_app/model/honeyz_model.dart';
import 'package:honeyz_fan_app/model/live_check_model.dart';

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
  final LiveCheckModel status;

  const StreamerCard({
    super.key,
    required this.index,
    required this.streamer,
    required this.status,
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
          Text(
            honeyzName[index],
            style: FontStyleSheet.streamerCardItem,
          ),
          Visibility(
            visible: status.status! == 'OPEN',
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  status.liveTitle!,
                  style: FontStyleSheet.streamerCardItem,
                  textAlign: TextAlign.center,
                ),
                Text(
                  "LIVE",
                  style: FontStyleSheet.streamerCardItem.copyWith(
                    color: Colors.lightGreenAccent.withOpacity(1.0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
