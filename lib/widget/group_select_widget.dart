import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyz_fan_app/font_style_sheet.dart';

class GroupSelectWidget extends StatelessWidget {
  const GroupSelectWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () {
                    context.push('/baseScreen');
                  },
                  child: Container(
                    height: double.infinity,
                    color: Color(0x0FFF5E88).withOpacity(1.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/honeyz_logo.png',
                          width: 150.0,
                          height: 150.0,
                        ),
                        Text(
                          '허니즈',
                          style:
                              FontStyleSheet.basicText.copyWith(fontSize: 25.0),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  height: double.infinity,
                  color: Color(0x0FCCD1F9).withOpacity(1.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/acaxia_logo.png',
                        width: 150.0,
                        height: 150.0,
                      ),
                      Text(
                        '아카시아',
                        style:
                            FontStyleSheet.basicText.copyWith(fontSize: 25.0),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
