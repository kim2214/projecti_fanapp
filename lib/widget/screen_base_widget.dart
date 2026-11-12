import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:projecti_fan_app/model/group.dart';
import 'package:projecti_fan_app/model/notification_target.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/controllers/notification_controller.dart';
import 'package:projecti_fan_app/controllers/theme_controller.dart';
import 'package:projecti_fan_app/controllers/youtube_controller.dart';
import 'package:projecti_fan_app/widget/group_page.dart';
import 'package:projecti_fan_app/widget/home_dashboard_page.dart';
import 'package:projecti_fan_app/widget/youtube_page.dart';
import 'package:projecti_fan_app/widget/schedule_page.dart';
import 'package:projecti_fan_app/widget/components/tap_semantics.dart';

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
  final NotificationController _notificationController =
      Get.find<NotificationController>();

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
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _switchGroup(Group group) async {
    await _globalController.selectGroup(group);

    // 스케줄 데이터만 로드한다. 멤버·라이브 상태는 홈 대시보드의
    // ever(selectedGroup)가, 그룹 영상은 YouTubeController가 각각 재로드한다.
    await _globalController.loadScheduleFireStore();

    // 홈 페이지로 이동
    if (_currentIndex != 0) {
      _onNavTap(0);
    }
  }

  /// 스케줄·생일 알림 탭 대기열 구독. 앱이 살아 있을 때 들어오는 탭을 받는다.
  late final Worker _notificationTapWorker;

  @override
  void initState() {
    super.initState();
    _notificationTapWorker = ever(_notificationController.pendingTarget,
        (_) => _openNotificationTarget());
    // 콜드 스타트: 스플래시 동안 이미 들어와 기다리던 탭. PageView가 붙은 뒤 처리한다.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _openNotificationTarget());
  }

  /// 알림이 가리키는 그룹으로 바꾸고 스케줄 탭(스케줄 알림)이나 멤버 프로필
  /// (생일 알림), 멤버를 고른 YouTube 탭(프로필의 영상 더보기)을 연다.
  Future<void> _openNotificationTarget() async {
    final target = _notificationController.pendingTarget.value;
    if (target == null || !mounted) return;
    _notificationController.pendingTarget.value = null;

    // 상세 화면·시트가 위에 떠 있으면 기본 화면까지 닫는다.
    final baseRoute = ModalRoute.of(context);
    if (baseRoute != null && !baseRoute.isCurrent) {
      Navigator.of(context).popUntil((route) => route == baseRoute);
    }

    final groupChanged = _globalController.currentGroup != target.group;
    if (groupChanged) await _globalController.selectGroup(target.group);
    if (!mounted) return;

    switch (target.type) {
      case NotificationTargetType.schedule:
        // 방금 올라온 스케줄이 보이도록 캐시가 있어도 다시 읽는다.
        unawaited(_globalController.loadScheduleFireStore(forceRefresh: true));
        _onNavTap(1);
      case NotificationTargetType.birthday:
        if (groupChanged) {
          unawaited(_globalController.loadScheduleFireStore());
        }
        _onNavTap(0);
        final key = target.memberKey;
        final known = key != null &&
            _globalController.membersOf(target.group).any((m) => m.key == key);
        if (known) {
          unawaited(context
              .push('/streamerDetail?group=${target.group.id}&key=$key'));
        }
      case NotificationTargetType.videos:
        if (groupChanged) {
          unawaited(_globalController.loadScheduleFireStore());
        }
        final key = target.memberKey;
        if (key != null) {
          unawaited(Get.find<YouTubeController>().selectMember(key));
        }
        _onNavTap(3);
    }
  }

  @override
  void dispose() {
    _notificationTapWorker.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final group = _globalController.currentGroup;
      final themeColor = AppColors.group(group);
      // 글자·아이콘용 톤 — acaxiaDark는 흰 배경 대비 1.8:1이라 쓰지 않는다(group_page와 동일).
      final themeColorDark = context.groupInk(group);

      // 시스템 뒤로가기: 홈이 아닌 탭에서는 먼저 홈 탭으로 돌아가고, 홈에서만
      // 화면을 닫는다(그룹 선택으로). 앱바 ← 버튼은 context.pop()이라 이 판단을
      // 거치지 않고 지금처럼 바로 그룹 선택으로 간다.
      return PopScope(
        canPop: _currentIndex == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onNavTap(0);
        },
        child: Scaffold(
          backgroundColor: context.bg,
          appBar: _buildAppBar(group, themeColor, themeColorDark),
          body: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: _pages,
          ),
          bottomNavigationBar: _buildBottomNav(themeColor, themeColorDark),
        ),
      );
    });
  }

  PreferredSizeWidget _buildAppBar(
      Group group, Color themeColor, Color themeColorDark) {
    return AppBar(
      backgroundColor: context.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: IconButton(
        tooltip: '그룹 선택으로',
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
                  group.logoAsset,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 큰 글꼴에선 오른쪽 버튼들에 밀려 "허…"로 잘렸다 — 자르는 대신 줄여서
          // 이름 전체를 보여준다.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                group.label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textMain,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
      titleSpacing: 0,
      actions: [
        // 알림 설정
        _buildNotificationButton(),
        // 테마 모드 토글 (system → light → dark)
        _buildThemeToggle(),
        // 그룹 전환 버튼
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _buildGroupSwitcher(group, themeColor),
        ),
      ],
    );
  }

  Widget _buildNotificationButton() {
    return IconButton(
      icon: Icon(Icons.notifications_outlined, color: context.textSub),
      tooltip: '알림 설정',
      // 높이는 터치 기준 48dp, 폭은 44dp — 앱바가 좁아 48로 넓히면 그룹명이 잘린다.
      constraints: _appBarIconConstraints,
      onPressed: _showNotificationSettings,
    );
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      // 기본 시트는 화면 높이의 9/16에서 잘린다 — 화면 크기 '크게'·큰 글꼴에선
      // 맨 아래 "배터리 설정 열기"가 넘쳐 눌리지 않았다. 내용만큼 올리고,
      // 그래도 넘치면 스크롤한다.
      isScrollControlled: true,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Obx(() {
              // 서버가 멈춘 동안에는 "켜면 알림이 온다"고 약속하지 않는다.
              final down = _globalController.pushServiceDown.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications_rounded,
                          size: 22, color: context.textMain),
                      const SizedBox(width: 8),
                      Text(
                        '알림 설정',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textMain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (down) ...[
                    _buildServiceDownBanner(),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    '라이브 알림',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    down
                        ? '알림을 받을 범위입니다. 지금은 발송이 중단돼 알림이 오지 않습니다.'
                        : '방송 시작 알림을 받을 범위입니다. 최애만 = 별(⭐)로 지정한 멤버.',
                    style: TextStyle(fontSize: 13, color: context.textFaint),
                  ),
                  const SizedBox(height: 10),
                  Obx(() => SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'all', label: Text('전체 멤버')),
                            ButtonSegment(
                                value: 'favorites', label: Text('최애만')),
                            ButtonSegment(value: 'off', label: Text('끄기')),
                          ],
                          selected: {_notificationController.liveMode.value},
                          onSelectionChanged: (selection) =>
                              _notificationController
                                  .setLiveMode(selection.first),
                        ),
                      )),
                  const SizedBox(height: 20),
                  Text(
                    '스케줄 알림',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: context.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    down
                        ? '스케줄·생일 알림도 함께 중단된 상태입니다.'
                        : '멤버 스케줄 등록과 생일 소식을 알려드립니다.',
                    style: TextStyle(fontSize: 13, color: context.textFaint),
                  ),
                  const SizedBox(height: 12),
                  Obx(() => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.honeyz,
                        title: Text('허니즈 스케줄 알림',
                            style: TextStyle(color: context.textMain)),
                        value: _notificationController
                                .scheduleEnabled[Group.honeyz] ??
                            true,
                        onChanged: (v) => _notificationController
                            .setScheduleEnabled(Group.honeyz, v),
                      )),
                  Obx(() => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        // 라일락 브랜드색은 켜짐이 꺼짐처럼 흐리게 보인다.
                        activeThumbColor: context.acaxiaInk,
                        title: Text('아카시아 스케줄 알림',
                            style: TextStyle(color: context.textMain)),
                        value: _notificationController
                                .scheduleEnabled[Group.acaxia] ??
                            true,
                        onChanged: (v) => _notificationController
                            .setScheduleEnabled(Group.acaxia, v),
                      )),
                  const SizedBox(height: 8),
                  down ? _buildServiceDownHelp() : _buildBatteryHelp(),
                ],
              );
            }),
          )),
        );
      },
    );
  }

  /// 푸시 발송이 멈춘 동안 시트 상단에 띄우는 안내.
  /// 토글이 "성공"해도 알림은 오지 않으므로, 켜기 전에 먼저 알려준다.
  Widget _buildServiceDownBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.birthday.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.birthday.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 18, color: AppColors.birthday),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '알림이 발송되지 않고 있어요',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '알림을 보내는 서버가 멈춰 있어, 아래 설정을 켜도 알림이 오지 않습니다. '
                  '방송 중인 멤버는 앱을 열면 바로 확인할 수 있어요.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: context.textSub,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 발송이 멈춘 동안의 "알림이 안 오나요?" — 원인이 기기가 아니므로 배터리
  /// 설정으로 보내지 않는다 (바꿔도 알림은 오지 않아 기기 문제로 오해하게 된다).
  Widget _buildServiceDownHelp() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.textFaint.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded,
                  size: 18, color: context.textSub),
              const SizedBox(width: 6),
              Text(
                '알림이 안 오나요?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '기기 설정 문제가 아닙니다. 알림을 보내는 서버가 멈춰 있어, '
            '복구되기 전까지는 설정을 바꿔도 알림이 오지 않습니다.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: context.textFaint,
            ),
          ),
        ],
      ),
    );
  }

  /// 알림이 안 오는 경우(주로 삼성 등 절전 정책) 배터리 설정으로 안내한다.
  Widget _buildBatteryHelp() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.textFaint.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded,
                  size: 18, color: context.textSub),
              const SizedBox(width: 6),
              Text(
                '알림이 안 오나요?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '앱을 완전히 종료하면 일부 기기(삼성 등)의 절전 기능이 알림을 막을 수 있어요. '
            '아래에서 배터리 사용을 "제한 없음"으로 바꾸면 종료 상태에서도 알림을 받을 수 있습니다.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: context.textFaint,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  AppSettings.openAppSettings(type: AppSettingsType.settings),
              icon: const Icon(Icons.battery_saver_rounded, size: 18),
              label: const Text('배터리 설정 열기'),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.textMain,
                side: BorderSide(color: context.textFaint.withAlpha(80)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle() {
    return Obx(
      () => IconButton(
        icon: Icon(_themeController.icon, color: context.textSub),
        tooltip: '테마 변경',
        constraints: _appBarIconConstraints,
        onPressed: _themeController.cycle,
      ),
    );
  }

  Widget _buildGroupSwitcher(Group group, Color themeColor) {
    // 각 토글의 터치 영역은 위아래 투명 여백으로 48dp를 넘기고, 회색 배경은
    // 토글 바로 바깥(4dp)까지만 그린다 — 보이는 모양은 그대로, 누르기만 쉬워진다.
    // 라벨은 앱바 공간이 좁아 글꼴 배율을 1.3배까지만 따른다.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: _groupToggleTapInset - 4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGroupToggle(
                  isSelected: group == Group.honeyz,
                  label: Group.honeyz.label,
                  color: AppColors.honeyz,
                  onTap: () => _switchGroup(Group.honeyz),
                ),
                _buildGroupToggle(
                  isSelected: group == Group.acaxia,
                  label: Group.acaxia.label,
                  color: AppColors.acaxia,
                  onTap: () => _switchGroup(Group.acaxia),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const BoxConstraints _appBarIconConstraints =
      BoxConstraints(minWidth: 44, minHeight: 48);

  /// 그룹 토글의 보이는 알약 위아래에 더하는 투명 터치 여백.
  static const double _groupToggleTapInset = 11;

  Widget _buildGroupToggle({
    required bool isSelected,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TapSemantics(
        selected: isSelected,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: _groupToggleTapInset),
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
                  color:
                      isSelected ? AppColors.onBrand(color) : context.textSub,
                ),
              ),
            ),
          ),
        ));
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

              // Flexible — 큰 글꼴에서 선택 탭 라벨이 길어져도 Row가 넘치지 않게
              // 남는 폭만큼만 쓰고 라벨을 말줄임한다. 라벨이 붙는 선택 탭만 몫을
              // 두 배로 준다 — 똑같이 나누면 화면 크기 '크게'에서 "YouTube"가
              // "Yo…"로, 큰 글꼴에선 "스케줄"·"멤버"가 아예 사라졌다.
              return Flexible(
                flex: isSelected ? 2 : 1,
                child: _buildNavItem(
                  item: item,
                  isSelected: isSelected,
                  themeColor: themeColor,
                  themeColorDark: themeColorDark,
                  onTap: () => _onNavTap(index),
                ),
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
    // GestureDetector는 시맨틱이 없어 스크린리더가 탭으로 읽지 못한다.
    // 미선택 탭은 아이콘뿐이라 label도 여기서 제공한다 (자식 시맨틱은 중복 방지 제외).
    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
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
                Flexible(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: themeColorDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
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
