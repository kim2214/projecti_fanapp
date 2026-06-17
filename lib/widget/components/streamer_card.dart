import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:projecti_fan_app/controllers/favorites_controller.dart';
import 'package:projecti_fan_app/model/streamer_model.dart';
import 'package:projecti_fan_app/model/live_check_model.dart';

class StreamerCard extends StatelessWidget {
  final int index;
  final StreamerModel streamer;
  final LiveCheckModel status;
  final String assetName;
  final String memberName;
  final Color themeColor;
  final Color themeColorDark;
  final bool isHoneyz;

  const StreamerCard({
    super.key,
    required this.index,
    required this.streamer,
    required this.status,
    required this.assetName,
    required this.memberName,
    required this.themeColor,
    required this.themeColorDark,
    required this.isHoneyz,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = status.status == 'OPEN';
    final birthdayDays = streamer.daysUntilBirthday;
    final showBirthday = birthdayDays != null && birthdayDays <= 7;

    return GestureDetector(
      onTap: () {
        context.push('/streamerDetail', extra: streamer);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isLive
                  ? Colors.green.withAlpha(40)
                  : themeColor.withAlpha(25),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          border: isLive ? Border.all(color: Colors.green, width: 2.5) : null,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 프로필 이미지
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            themeColor.withAlpha(30),
                            themeColor.withAlpha(60),
                          ],
                        ),
                      ),
                      child: Image.asset(
                        isHoneyz
                            ? 'assets/honeyz/${assetName}_profile.png'
                            : 'assets/acaxia/${assetName}_profile.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                // 이름 및 정보
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              memberName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A3A4A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isLive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'LIVE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isHoneyz ? '허니즈' : '아카시아',
                        style: TextStyle(
                          fontSize: 12,
                          color: themeColorDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // 라이브 중일 때 방송 제목 오버레이
            if (isLive &&
                status.liveTitle != null &&
                status.liveTitle!.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 65,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(180),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.liveTitle!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            // 최애(즐겨찾기) 토글 버튼
            Positioned(
              top: 8,
              right: 8,
              child: _buildFavoriteButton(),
            ),
            // 생일 임박 배지 (7일 이내)
            if (showBirthday)
              Positioned(
                top: 8,
                left: 8,
                child: _buildBirthdayBadge(birthdayDays),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    final favorites = Get.find<FavoritesController>();
    final group = isHoneyz ? 'honeyz' : 'acaxia';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => favorites.toggle(group, assetName),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withAlpha(220),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Obx(() {
          final isFav = favorites.isFavorite(group, assetName);
          return Icon(
            isFav ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 20,
            color: isFav ? const Color(0xFFFFB300) : Colors.grey[400],
          );
        }),
      ),
    );
  }

  Widget _buildBirthdayBadge(int days) {
    final isToday = days == 0;
    const amber = Color(0xFFFFA000);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: amber,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cake_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            isToday ? '오늘' : 'D-$days',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
