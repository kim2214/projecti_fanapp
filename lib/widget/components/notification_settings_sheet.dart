import 'dart:async';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/controllers/notification_controller.dart';
import 'package:projecti_fan_app/model/group.dart';
import 'package:projecti_fan_app/model/live_notification_mode.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';

/// 알림 설정 시트를 연다 (기본 화면 앱바의 종 아이콘).
void showNotificationSettingsSheet(BuildContext context) {
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
    builder: (_) => const NotificationSettingsSheet(),
  );
}

/// 라이브·스케줄 알림 설정과, 알림이 오지 않는 원인(서버 중단·기기 권한·절전)
/// 안내를 담은 시트 내용.
class NotificationSettingsSheet extends StatefulWidget {
  const NotificationSettingsSheet({super.key});

  @override
  State<NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<NotificationSettingsSheet> {
  final GlobalController _globalController = Get.find<GlobalController>();
  final NotificationController _notificationController =
      Get.find<NotificationController>();

  /// 시스템 설정에서 알림을 켜고 돌아오면 권한 안내가 바로 사라지게 한다.
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    unawaited(_notificationController.refreshPermissionStatus());
    _lifecycleListener = AppLifecycleListener(
        onResume: _notificationController.refreshPermissionStatus);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Obx(() {
          // 서버가 멈춘 동안에는 "켜면 알림이 온다"고 약속하지 않는다.
          final down = _globalController.pushServiceDown.value;
          // 기기에서 알림이 꺼져 있으면 아래 스위치를 켜도 알림이 뜨지 않는다.
          final denied = _notificationController.permissionDenied.value;
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
              if (denied) ...[
                _buildPermissionDeniedBanner(),
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
                    child: SegmentedButton<LiveNotificationMode>(
                      segments: [
                        for (final mode in LiveNotificationMode.values)
                          ButtonSegment(value: mode, label: Text(mode.label)),
                      ],
                      selected: {_notificationController.liveMode.value},
                      onSelectionChanged: (selection) =>
                          _notificationController.setLiveMode(selection.first),
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
                down ? '스케줄·생일 알림도 함께 중단된 상태입니다.' : '멤버 스케줄 등록과 생일 소식을 알려드립니다.',
                style: TextStyle(fontSize: 13, color: context.textFaint),
              ),
              const SizedBox(height: 12),
              Obx(() => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.honeyz,
                    title: Text('허니즈 스케줄 알림',
                        style: TextStyle(color: context.textMain)),
                    value:
                        _notificationController.scheduleEnabled[Group.honeyz] ??
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
                    value:
                        _notificationController.scheduleEnabled[Group.acaxia] ??
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

  /// 기기에서 이 앱의 알림이 꺼져 있을 때 시트 상단에 띄우는 안내.
  /// 원인이 앱 설정이 아니므로 시스템 알림 설정으로 바로 보낸다.
  Widget _buildPermissionDeniedBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.birthday.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.birthday.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_off_rounded,
                  size: 18, color: AppColors.birthday),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '기기에서 알림이 꺼져 있어요',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textMain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '이 앱의 알림이 허용되지 않아, 아래 설정을 켜도 알림이 표시되지 않습니다.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: context.textSub,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => AppSettings.openAppSettings(
                  type: AppSettingsType.notification),
              icon: const Icon(Icons.settings_rounded, size: 18),
              label: const Text('알림 설정 열기'),
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
}
