import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/widget/components/streamer_card.dart';

class GroupPageWidget extends StatefulWidget {
  const GroupPageWidget({super.key});

  @override
  State<GroupPageWidget> createState() => _GroupPageWidgetState();
}

class _GroupPageWidgetState extends State<GroupPageWidget>
    with AutomaticKeepAliveClientMixin {
  final GlobalController _globalController = Get.find<GlobalController>();

  // 그룹별 테마 컬러
  static const Color honeyzColor = Color(0xFFFF5E88);
  static const Color acaxiaColor = Color(0xFFCCD1F9);
  static const Color honeyzColorDark = Color(0xFFE84A75);
  static const Color acaxiaColorDark = Color(0xFFB8BEF0);

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(() {
      final isHoneyz = _globalController.selectedGroup.value == 'honeyz';
      final themeColor = isHoneyz ? honeyzColor : acaxiaColor;
      final themeColorDark = isHoneyz ? honeyzColorDark : acaxiaColorDark;

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              themeColor.withAlpha(30),
              Colors.white,
              themeColor.withAlpha(15),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: FutureBuilder(
          future: _globalController.liveCheck(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData == false) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: themeColor,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '멤버 정보를 불러오는 중...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '오류가 발생했습니다',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return _buildContent(isHoneyz, themeColor, themeColorDark);
            }
          },
        ),
      );
    });
  }

  Widget _buildContent(bool isHoneyz, Color themeColor, Color themeColorDark) {
    final members =
        isHoneyz ? _globalController.honeyz : _globalController.acaxia;
    final liveStatusList = isHoneyz
        ? _globalController.honeyzliveCheckList
        : _globalController.acaxialiveCheckList;
    final assetNames = isHoneyz
        ? _globalController.honeyzAssetName
        : _globalController.acaxiaAssetName;
    final nameList = isHoneyz
        ? _globalController.honeyzNameList
        : _globalController.acaxiaNameList;

    return CustomScrollView(
      slivers: [
        // 헤더
        SliverToBoxAdapter(
          child: _buildHeader(
              isHoneyz, themeColor, themeColorDark, members.length),
        ),
        // 멤버 그리드
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return StreamerCard(
                  index: index,
                  streamer: members[index],
                  status: liveStatusList[index],
                  assetName: assetNames[index],
                  memberName: nameList[index],
                  themeColor: themeColor,
                  themeColorDark: themeColorDark,
                  isHoneyz: isHoneyz,
                );
              },
              childCount: members.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
      bool isHoneyz, Color themeColor, Color themeColorDark, int memberCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 로고
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withAlpha(60),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      isHoneyz
                          ? 'assets/honeyz_logo.png'
                          : 'assets/acaxia_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 텍스트 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: themeColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'MEMBERS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: themeColorDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isHoneyz ? '허니즈' : '아카시아',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A4A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 멤버 수 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_alt_rounded,
                  size: 18,
                  color: themeColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '멤버 $memberCount명',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A3A4A),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 1,
                  height: 16,
                  color: Colors.grey[300],
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.touch_app_rounded,
                  size: 16,
                  color: themeColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '탭하여 상세 정보',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
