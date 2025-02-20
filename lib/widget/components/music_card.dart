import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyz_fan_app/model/music_model.dart';

class MusicCard extends StatelessWidget {
  final MusicModel musicModel;

  const MusicCard({
    super.key,
    required this.musicModel,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push('/audioPage', extra: musicModel);
      },
      child: Row(
        children: [
          ExtendedImage.network(
            height: 50,
            width: 50,
            clipBehavior: Clip.hardEdge,
            musicModel.thumbnail!,
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
                Text(musicModel.title!),
                Text(musicModel.name!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
