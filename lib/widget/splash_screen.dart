import 'package:flutter/material.dart';
import 'package:honeyz_fan_app/widget/screen_base_widget.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScreenBaseWidget(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0x0f2a2a2a).withOpacity(1.0),
      body: Column(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Image.asset(
                //   'assets/splash_image.png',
                //   width: 100,
                //   height: 100,
                // ),
                SizedBox(
                  height: 10.0,
                ),
                Text(
                  '부산 상수도 작업 관리자',
                  style: TextStyle(
                      fontSize: 25.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  '깨끗한 물, 건강한 시민, 책임지는 시스템',
                  style: TextStyle(fontSize: 17.0, color: Colors.white),
                ),
              ],
            ),
          ),
          Spacer(),
          Align(
            alignment: Alignment.bottomCenter,
            child: Text('Copyright @2025 부산 상수도 사업본부 V1.0.0',
                style: TextStyle(fontSize: 14.0, color: Colors.white)),
          ),
          SizedBox(
            height: 15.0,
          )
        ],
      ),
    );
  }
}
