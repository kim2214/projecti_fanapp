import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/model/birthday_entry.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:projecti_fan_app/widget/home/home_section_title.dart';

/// 홈 "다가오는 생일" — 데이터가 없으면 통째로 생략.
class HomeBirthdaySection extends StatelessWidget {
  final Color themeColor;
  final Color themeColorDark;

  const HomeBirthdaySection(
      {super.key, required this.themeColor, required this.themeColorDark});

  GlobalController get _globalController => Get.find<GlobalController>();

  @override
  Widget build(BuildContext context) =>
      Obx(() => _buildBirthdaySection(context, themeColor, themeColorDark));

  Widget _buildBirthdaySection(
      BuildContext context, Color themeColor, Color themeColorDark) {
    final group = _globalController.currentGroup;
    final birthdays = _globalController.upcomingBirthdays(group);

    // 생일 데이터가 없으면 섹션 통째로 생략
    if (birthdays.isEmpty) return const SizedBox.shrink();

    final items = birthdays.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionTitle(
          icon: Icons.cake_rounded,
          title: '다가오는 생일',
          color: AppColors.birthday,
          // 홈 카드는 가까운 3명까지만 — 나머지가 있을 때만 전체보기를 붙인다.
          trailing: birthdays.length > items.length
              ? HomeMoreLink('전체보기',
                  onTap: () =>
                      _showAllBirthdays(context, birthdays, themeColorDark))
              : null,
        ),
        SizedBox(
          height: homeRowHeight(context, 92),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            itemBuilder: (context, i) => _buildBirthdayCard(
                context, items[i], themeColor, themeColorDark),
          ),
        ),
      ],
    );
  }

  Widget _buildBirthdayCard(BuildContext context, BirthdayEntry entry,
      Color themeColor, Color themeColorDark) {
    return Container(
      width: 230,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: entry.isToday
              ? AppColors.birthday.withAlpha(160)
              : themeColor.withAlpha(50),
          width: entry.isToday ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (entry.isToday ? AppColors.birthday : themeColor).withAlpha(25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: themeColor.withAlpha(30),
            backgroundImage: AssetImage(entry.assetPath),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.memberName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  entry.dateLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.textSub,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildDdayChip(context, entry, themeColorDark),
        ],
      ),
    );
  }

  /// 그룹 전체 멤버의 생일을 가까운 순으로 보여주는 시트.
  void _showAllBirthdays(
      BuildContext context, List<BirthdayEntry> entries, Color themeColorDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cake_rounded,
                          size: 22, color: AppColors.birthday),
                      const SizedBox(width: 8),
                      Text(
                        '멤버 생일',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textMain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: entries.length,
                      itemBuilder: (_, i) {
                        final entry = entries[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: themeColorDark.withAlpha(30),
                                backgroundImage: AssetImage(entry.assetPath),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.memberName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: context.textMain,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      entry.dateLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.textSub,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildDdayChip(context, entry, themeColorDark),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDdayChip(
      BuildContext context, BirthdayEntry entry, Color themeColorDark) {
    final bg =
        entry.isToday ? AppColors.birthday : themeColorDark.withAlpha(30);
    final fg = entry.isToday ? Colors.white : themeColorDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        entry.isToday ? '오늘 🎂' : 'D-${entry.daysUntil}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}
