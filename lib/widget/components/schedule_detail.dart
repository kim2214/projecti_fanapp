import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScheduleDetail extends StatelessWidget {
  final String? imageURL;
  final String? name;

  const ScheduleDetail({super.key, required this.imageURL, required this.name});

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
        body: ExtendedImage.network(
          imageURL!,
          fit: BoxFit.fill,
          mode: ExtendedImageMode.gesture, // 줌/팬 모드 활성화
          initGestureConfigHandler: (state) => GestureConfig(
            minScale: 1.0,
            maxScale: 5.0,
            speed: 1.0,
            initialScale: 1.0,
          ),
          cache: true,
        )
        // Column(
        //   children: [
        //     name == "허니즈" ?
        //     Text('허니즈 시간 스케줄 입니다.') :
        //     Text('$name 님의 스케줄 입니다.'),
        //     Image.network(
        //       imageURL!,
        //       fit: BoxFit.fill,
        //     ),
        //   ],
        // ),
        );
  }
}
