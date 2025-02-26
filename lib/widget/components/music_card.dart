import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyz_fan_app/font_style_sheet.dart';
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
      child: Container(
        height: MediaQuery.of(context).size.height * 0.45,
        width: MediaQuery.of(context).size.width * 0.8,
        decoration: BoxDecoration(
            color: Color(0x0fff5e88).withOpacity(1.0),
            border: Border.all(color: Colors.black, width: 5.0),
            borderRadius: BorderRadius.all(
              Radius.circular(10.0),
            )),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: MediaQuery.of(context).size.width * 0.6,
              width: MediaQuery.of(context).size.width * 0.6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(10.0),
                ),
                image: DecorationImage(
                  fit: BoxFit.fill,
                  image: ExtendedNetworkImageProvider(musicModel.thumbnail!,
                      cache: true),
                ),
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                children: [
                  Text(
                    musicModel.title!,
                    style: FontStyleSheet.musicTitle,
                  ),
                  Text(
                    musicModel.name!,
                    style: FontStyleSheet.musicArtistName,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
