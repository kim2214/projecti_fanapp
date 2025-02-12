import 'package:flutter/material.dart';
import 'package:honeyz_fan_app/widget/main_page.dart';

class ScreenBaseWidget extends StatefulWidget {
  ScreenBaseWidget({super.key});

  @override
  State<ScreenBaseWidget> createState() => _ScreenBaseWidgetState();
}

class _ScreenBaseWidgetState extends State<ScreenBaseWidget>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late TabController _tabController; // TabController 추가

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(tabListener);
  }

  void tabListener() {
    setState(() {
      _index = _tabController.index;
    });
  }

  final List<Widget> _screens = [
    MainPageWidget(),
    Text('두번쨰'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        onTap: (int index) {
          _tabController.animateTo(index);
        },
        currentIndex: _index,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: '음악',
          ),
        ],
      ),
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        leading: BackButton(),
        backgroundColor: Colors.white,
      ),
      body: Center(child: _screens[_index]),
    );
  }
}
