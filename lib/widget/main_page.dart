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
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        mainAxisSpacing: 20,
        crossAxisSpacing: 0,
      ),
      itemCount: 6,
      itemBuilder: (BuildContext context, int index) {
        return StreamerCard();
      },
    );
  }
}
