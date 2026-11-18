import 'package:flutter/material.dart';
import 'package:projecti_fan_app/model/group.dart';
import 'package:projecti_fan_app/model/member.dart';
import 'package:projecti_fan_app/model/streamer_model.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';

/// 멤버 프로필 상단 카드 — 대표 이미지·그룹 뱃지·이름·소속·생일 D-day 칩.
/// 프로필 문서가 아직 없으면 카탈로그 이름([fallbackName])으로 먼저 보여준다.
class StreamerProfileCard extends StatelessWidget {
  final Group group;
  final String memberKey;
  final StreamerModel streamer;
  final String? fallbackName;

  const StreamerProfileCard({
    super.key,
    required this.group,
    required this.memberKey,
    required this.streamer,
    this.fallbackName,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = AppColors.group(group);
    final themeColorDark = AppColors.groupDark(group);
    final birthdayLabel = streamer.birthdayLabel;
    final days = streamer.daysUntilBirthday;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: themeColor.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    themeColor.withAlpha(40),
                    themeColor.withAlpha(80),
                  ],
                ),
              ),
              child: Image.asset(
                // 에셋 경로는 카탈로그(group/key)에서 파생한다 — Firestore profileName에
                // 의존하지 않아 필드 누락 시에도 이미지가 깨지지 않는다.
                Member.profileAssetPathOf(group, memberKey),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 그룹 뱃지
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [themeColor, themeColorDark],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    group.labelEn,
                    // 브랜드색 면 위 글자 — 라일락 위 흰 글자는 대비 1.5:1.
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppColors.onBrand(themeColor),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  // 프로필 문서가 아직 없으면 카탈로그 이름으로 먼저 보여준다.
                  streamer.name ?? fallbackName ?? '',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: context.textMain,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${group.label} 소속',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textSub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // 생일 D-day 칩 (설정된 경우만)
                if (birthdayLabel != null && days != null) ...[
                  const SizedBox(height: 14),
                  _BirthdayChip(label: birthdayLabel, days: days),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthdayChip extends StatelessWidget {
  final String label;
  final int days;

  const _BirthdayChip({required this.label, required this.days});

  @override
  Widget build(BuildContext context) {
    final isToday = days == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.birthday.withAlpha(isToday ? 255 : 30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cake_rounded,
            size: 16,
            color: isToday ? Colors.white : AppColors.birthday,
          ),
          const SizedBox(width: 6),
          Text(
            isToday ? '오늘 생일! 🎂' : '$label · D-$days',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isToday ? Colors.white : AppColors.birthday,
            ),
          ),
        ],
      ),
    );
  }
}
