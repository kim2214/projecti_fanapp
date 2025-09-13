import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyz_fan_app/font_style_sheet.dart';
import 'package:honeyz_fan_app/model/streamer_model.dart';
import 'package:url_launcher/url_launcher.dart';

class StreamerDetail extends StatelessWidget {
  final StreamerModel honeyz;

  const StreamerDetail({super.key, required this.honeyz});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        leading: BackButton(
          onPressed: () {
            context.pop();
          },
        ),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          children: [
            Image.asset('assets/honeyz/${honeyz.profileName}_profile.png'),
            SizedBox(
              height: 40,
            ),
            Text(
              "허니즈 소속 ${honeyz.name!} 입니다.",
              style: FontStyleSheet.title,
            ),
            SizedBox(
              height: 40.0,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    child: Image.asset(
                      "assets/icons/chzzk_icon.png",
                      height: 100,
                      width: 100,
                    ),
                    onTap: () async {
                      Uri chzzkUrl = Uri.parse(honeyz.chzzk!);
                      await launchUrl(chzzkUrl);
                      // if (await canLaunchUrl(chzzkUrl)) {
                      //   await launchUrl(chzzkUrl);
                      // } else {
                      //   throw 'Could not launch $chzzkUrl';
                      // }
                    },
                  ),
                  InkWell(
                    child: Image.asset(
                      "assets/icons/youtube_icon.png",
                      height: 100,
                      width: 100,
                    ),
                    onTap: () async {
                      Uri youtubeUrl = Uri.parse(honeyz.youtube!);
                      await launchUrl(youtubeUrl);
                      // if (await canLaunchUrl(youtubeUrl)) {
                      //   await launchUrl(youtubeUrl);
                      // } else {
                      //   throw 'Could not launch $youtubeUrl';
                      // }
                    },
                  ),
                  InkWell(
                    child: Image.asset(
                      "assets/icons/x_icon.png",
                      height: 100,
                      width: 100,
                    ),
                    onTap: () async {
                      Uri xUrl = Uri.parse(honeyz.twitter!);
                      await launchUrl(xUrl);
                      // if (await canLaunchUrl(xUrl)) {
                      //   await launchUrl(xUrl);
                      // } else {
                      //   throw 'Could not launch $xUrl';
                      // }
                    },
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
