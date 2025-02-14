import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyz_fan_app/model/honeyz_model.dart';

class StreamerDetail extends StatelessWidget {
  final HoneyzModel honeyz;

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
            Image.asset('assets/${honeyz.profileName}_profile.png'),
            SizedBox(
              height: 40,
            ),
            Text(
              "허니즈 소속 ${honeyz.name!} 입니다.",
              style: TextStyle(fontSize: 17.0),
            ),
            SizedBox(
              height: 40.0,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    "assets/icons/chzzk_icon.png",
                    height: 100,
                    width: 100,
                  ),
                  Image.asset(
                    "assets/icons/youtube_icon.png",
                    height: 100,
                    width: 100,
                  ),
                  Image.asset(
                    "assets/icons/x_icon.png",
                    height: 100,
                    width: 100,
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
