import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

List<String> assetName = [
  "honeychurros",
  "ayauke",
  "damyui",
  "ddddragon",
  "ohwayo",
  "magnae"
];

List<String> honeyzName = [
  "허니츄러스",
  "아야",
  "담유이",
  "디디디용",
  "오화요",
  "망내"
];


class StreamerCard extends StatelessWidget {
  final int index;

  const StreamerCard({
    super.key,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push('/detail');
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
