import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/widget/group_page.dart';
import 'package:projecti_fan_app/widget/home_dashboard_page.dart';
import 'package:projecti_fan_app/widget/youtube_page.dart';
import 'package:projecti_fan_app/widget/schedule_page.dart';

class ScreenBaseWidget extends StatefulWidget {
  const ScreenBaseWidget({super.key});

  @override
  State<ScreenBaseWidget> createState() => _ScreenBaseWidgetState();
}

class _ScreenBaseWidgetState extends State<ScreenBaseWidget> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final GlobalController _globalController = Get.find<GlobalController>();

  // 그룹별 테마 컬러
  static const Color honeyzColor = Color(0xFFFF5E88);
  static const Color acaxiaColor = Color(0xFFCCD1F9);
  static const Color honeyzColorDark = Color(0xFFE84A75);
  static const Color acaxiaColorDark = Color(0xFFB8BEF0);

  late final List<Widget> _pages = [
    HomeDashboardWidget(onNavigateToTab: _onNavTap),
    const SchedulePageWidget(),
    const GroupPageWidget(),
    const YouTubePageWidget(),
  ];

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home_rounded, label: '홈'),
    NavItem(icon: Icons.calendar_month_rounded, label: '스케줄'),
    NavItem(icon: Icons.people_alt_rounded, label: '멤버'),
    NavItem(icon: Icons.play_circle_rounded, label: 'YouTube'),
  ];

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _onNavTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _switchGroup(String group) async {
    _globalController.selectedGroup.value = group;
    final sequence = group == 'honeyz'
        ? _globalController.honeyzSequence
        : _globalController.acaxiaSequence;

    // 스케줄 데이터만 로드 (멤버/라이브체크는 GroupPageWidget에서 처리)
    await _globalController.loadScheduleFireStore(sequence: sequence);

    // 홈 페이지로 이동
    if (_currentIndex != 0) {
      _onNavTap(0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isHoneyz = _globalController.selectedGroup.value == 'honeyz';
      final themeColor = isHoneyz ? honeyzColor : acaxiaColor;
      final themeColorDark = isHoneyz ? honeyzColorDark : acaxiaColorDark;

      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(isHoneyz, themeColor, themeColorDark),
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: _pages,
        ),
        bottomNavigationBar: _buildBottomNav(themeColor, themeColorDark),
      );
    });
  }

  PreferredSizeWidget _buildAppBar(
      bool isHoneyz, Color themeColor, Color themeColorDark) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: Color(0xFF1A3A4A),
        ),
        onPressed: () => context.pop(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: themeColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  isHoneyz
                      ? 'assets/honeyz_logo.png'
                      : 'assets/acaxia_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isHoneyz ? '허니즈' : '아카시아',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A3A4A),
            ),
          ),
        ],
      ),
      actions: [
        // 그룹 전환 버튼
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _buildGroupSwitcher(isHoneyz, themeColor),
        ),
      ],
    );
  }

  Widget _buildGroupSwitcher(bool isHoneyz, Color themeColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGroupToggle(
            isSelected: isHoneyz,
            label: '허니즈',
            color: honeyzColor,
            onTap: () => _switchGroup('honeyz'),
          ),
          _buildGroupToggle(
            isSelected: !isHoneyz,
            label: '아카시아',
            color: acaxiaColor,
            onTap: () => _switchGroup('acaxia'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupToggle({
    required bool isSelected,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(Color themeColor, Color themeColorDark) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: themeColor.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = _currentIndex == index;

              return _buildNavItem(
                item: item,
                isSelected: isSelected,
                themeColor: themeColor,
                themeColorDark: themeColorDark,
                onTap: () => _onNavTap(index),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required NavItem item,
    required bool isSelected,
    required Color themeColor,
    required Color themeColorDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? themeColor.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 22,
              color: isSelected ? themeColorDark : Colors.grey[400],
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: themeColorDark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;

  const NavItem({required this.icon, required this.label});
}
