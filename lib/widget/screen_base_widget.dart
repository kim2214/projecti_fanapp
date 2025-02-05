import 'package:flutter/material.dart';

class ScreenBaseWidget extends StatelessWidget {
  final Widget? widget;

  const ScreenBaseWidget({super.key, this.widget});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: widget),
    );
  }
}
