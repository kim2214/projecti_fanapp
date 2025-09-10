import 'package:flutter/material.dart';
import 'package:honeyz_fan_app/widget/honeyz_page.dart';
import 'package:honeyz_fan_app/widget/music_page.dart';
import 'package:honeyz_fan_app/widget/schedule_page.dart';

import 'group_select_widget.dart';

class ScreenBaseWidget extends StatefulWidget {
  ScreenBaseWidget({super.key});

  @override
  State<ScreenBaseWidget> createState() => _ScreenBaseWidgetState();
}

class _ScreenBaseWidgetState extends State<ScreenBaseWidget>
    with SingleTickerProviderStateMixin {
  int _index = 0;

  PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
  }

  final List<Widget> _screens = [
    SchedulePageWidget(),
    HoneyzPageWidget(),
    MusicPageWidget(),
  ];

  void updateScreenIndex(int newIndex) {
    _index = newIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        onTap: (int index) {
          pageController.jumpToPage(index);
        },
        currentIndex: _index,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Honeyz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: '음악',
          ),
        ],
      ),
      // appBar: AppBar(
      //   scrolledUnderElevation: 0.0,
      //   leading: BackButton(),
      //   backgroundColor: Colors.white,
      // ),
      body: SafeArea(
        child: PageView(
          controller: pageController,
          onPageChanged: (index) {
            setState(
              () {
                updateScreenIndex(index);
              },
            );
          },
          children: _screens,
        ),
      ),
    );
  }
}
