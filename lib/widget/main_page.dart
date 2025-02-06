import 'package:flutter/material.dart';
import 'package:honeyz_fan_app/widget/components/streamer_card.dart';

class MainPageWidget extends StatefulWidget {
  const MainPageWidget({super.key});

  @override
  State<MainPageWidget> createState() => _MainPageWidgetState();
}

class _MainPageWidgetState extends State<MainPageWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      padding: EdgeInsets.all(5.0),
      itemBuilder: (context, index) {
        return Container(
            margin: EdgeInsets.symmetric(vertical: 20.0),
            decoration: BoxDecoration(border: Border.all(color: Colors.black)),
            child: StreamerCard());
      },
    );
  }
}
