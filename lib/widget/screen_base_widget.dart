import 'package:flutter/material.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/controllers/theme_controller.dart';
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
  final ThemeController _themeController = Get.find<ThemeController>();

  // 그룹별 테마 컬러

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

    // 스케줄 데이터만 로드 (멤버/라이브체크는 GroupPageWidget에서 처리)
    await _globalController.loadScheduleFireStore();

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
      final themeColor = isHoneyz ? AppColors.honeyz : AppColors.acaxia;
      final themeColorDark = isHoneyz ? AppColors.honeyzDark : AppColors.acaxiaDark;

      return Scaffold(
        backgroundColor: context.bg,
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
      backgroundColor: context.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: context.textMain,
        ),
        onPressed: () => context.pop(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
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
          Flexible(
            child: Text(
              isHoneyz ? '허니즈' : '아카시아',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textMain,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      titleSpacing: 0,
      actions: [
        // 테마 모드 토글 (system → light → dark)
        _buildThemeToggle(),
        // 그룹 전환 버튼
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _buildGroupSwitcher(isHoneyz, themeColor),
        ),
      ],
    );
  }

  Widget _buildThemeToggle() {
    return Obx(
      () => IconButton(
        icon: Icon(_themeController.icon, color: context.textSub),
        tooltip: '테마 변경',
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
        onPressed: _themeController.cycle,
      ),
    );
  }

  Widget _buildGroupSwitcher(bool isHoneyz, Color themeColor) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGroupToggle(
            isSelected: isHoneyz,
            label: '허니즈',
            color: AppColors.honeyz,
            onTap: () => _switchGroup('honeyz'),
          ),
          _buildGroupToggle(
            isSelected: !isHoneyz,
            label: '아카시아',
            color: AppColors.acaxia,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : context.textSub,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(Color themeColor, Color themeColorDark) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
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
              color: isSelected ? themeColorDark : context.textFaint,
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
