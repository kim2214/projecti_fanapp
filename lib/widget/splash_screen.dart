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
      // backgroundColor: Color(0x0f2a2a2a).withOpacity(1.0),
      backgroundColor: Colors.white,
      body: Column(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/fanapp_logo.png',
                  width: 100,
                  height: 100,
                ),
                SizedBox(
                  height: 15.0,
                ),
                Text(
                  '허니즈 팬앱',
                  style: TextStyle(
                      fontSize: 25.0,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  '(HONEYZ FANAPP)',
                  style: TextStyle(fontSize: 17.0, color: Colors.black),
                ),
              ],
            ),
          ),
          Spacer(),
          Align(
            alignment: Alignment.bottomCenter,
            child: Text('Copyright @2025 kimdev0821',
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
