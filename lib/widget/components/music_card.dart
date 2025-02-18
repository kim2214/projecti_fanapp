import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

class MusicCard extends StatelessWidget {
  final String name;
  final String title;
  final String musicURL;
  final String thumbnail;

  const MusicCard({
    super.key,
    required this.name,
    required this.title,
    required this.musicURL,
    required this.thumbnail,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // onTap: () {
      //   context.push('/streamerDetail', extra: streamer);
      // },
      child: Row(
        children: [
          ExtendedImage.network(
            height: 50,
            width: 50,
            clipBehavior: Clip.hardEdge,
            thumbnail,
            fit: BoxFit.fill,
            mode: ExtendedImageMode.gesture,
            cache: true,
          ),
          SizedBox(
            width: 20.0,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(name),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
