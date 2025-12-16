import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';

class GroupSelectWidget extends StatefulWidget {
  const GroupSelectWidget({super.key});

  @override
  State<GroupSelectWidget> createState() => _GroupSelectWidgetState();
}

class _GroupSelectWidgetState extends State<GroupSelectWidget>
    with TickerProviderStateMixin {
  final globalController = Get.find<GlobalController>();

  // 그룹별 테마 컬러
  static const Color honeyzColor = Color(0xFFFF5E88);
  static const Color acaxiaColor = Color(0xFFCCD1F9);

  // 로딩 상태
  bool _isLoadingHoneyz = false;
  bool _isLoadingAcaxia = false;

  Future<void> _selectGroup(String group) async {
    if (group == 'honeyz') {
      setState(() => _isLoadingHoneyz = true);
      globalController.selectedGroup.value = 'honeyz';
      final schedule = await globalController.loadScheduleFireStore(
        sequence: globalController.honeyzSequence,
      );
      if (!mounted) return;
      if (schedule.isNotEmpty) {
        context.push('/baseScreen');
      }
      setState(() => _isLoadingHoneyz = false);
    } else {
      setState(() => _isLoadingAcaxia = true);
      globalController.selectedGroup.value = 'acaxia';
      final schedule = await globalController.loadScheduleFireStore(
        sequence: globalController.acaxiaSequence,
      );
      if (!mounted) return;
      if (schedule.isNotEmpty) {
        context.push('/baseScreen');
      }
      setState(() => _isLoadingAcaxia = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              honeyzColor.withAlpha(30),
              Colors.white,
              acaxiaColor.withAlpha(30),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder(
            future: globalController.loadStreamerFireStore(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData == false) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: honeyzColor,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '데이터를 불러오는 중...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
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
                return _buildContent();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // 헤더
          _buildHeader(),
          const SizedBox(height: 50),
          // 그룹 카드들
          Expanded(
            child: Column(
              children: [
                // 허니즈 카드
                Expanded(
                  child: _buildGroupCard(
                    group: 'honeyz',
                    name: '허니즈',
                    subtitle: 'HONEYZ',
                    description: '달콤한 매력의 버츄얼 아이돌',
                    color: honeyzColor,
                    logoAsset: 'assets/honeyz_logo.png',
                    isLoading: _isLoadingHoneyz,
                  ),
                ),
                const SizedBox(height: 20),
                // 아카시아 카드
                Expanded(
                  child: _buildGroupCard(
                    group: 'acaxia',
                    name: '아카시아',
                    subtitle: 'ACAXIA',
                    description: '신비로운 매력의 버츄얼 아이돌',
                    color: acaxiaColor,
                    logoAsset: 'assets/acaxia_logo.png',
                    isLoading: _isLoadingAcaxia,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // 하단 텍스트
          Text(
            '그룹 선택시 스케줄 확인 및 앱 기능 사용이 가능합니다.',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // const Text(
        //   'SCHEDULE',
        //   style: TextStyle(
        //     fontSize: 14,
        //     fontWeight: FontWeight.w700,
        //     letterSpacing: 2,
        //     color: Color(0xFF1A3A4A),
        //   ),
        // ),
        // Container(
        //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        //   decoration: BoxDecoration(
        //     color: Colors.white,
        //     borderRadius: BorderRadius.circular(20),
        //     boxShadow: [
        //       BoxShadow(
        //         color: Colors.black.withAlpha(10),
        //         blurRadius: 10,
        //         offset: const Offset(0, 2),
        //       ),
        //     ],
        //   ),
        //   child: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Icon(
        //         Icons.calendar_month_rounded,
        //         size: 20,
        //         color: honeyzColor,
        //       ),
        //       const SizedBox(width: 8),
        //       const Text(
        //         'SCHEDULE',
        //         style: TextStyle(
        //           fontSize: 14,
        //           fontWeight: FontWeight.w700,
        //           letterSpacing: 2,
        //           color: Color(0xFF1A3A4A),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),

        const SizedBox(height: 16),
        const Text(
          '그룹 선택',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A3A4A),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard({
    required String group,
    required String name,
    required String subtitle,
    required String description,
    required Color color,
    required String logoAsset,
    required bool isLoading,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : () => _selectGroup(group),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withAlpha(200),
              color,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(80),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // 배경 패턴
            Positioned(
              right: -30,
              bottom: -30,
              child: Opacity(
                opacity: 0.15,
                child: Icon(
                  Icons.music_note_rounded,
                  size: 180,
                  color: Colors.white,
                ),
              ),
            ),
            // 컨텐츠
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // 로고
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          logoAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // 텍스트 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            color: Colors.white.withAlpha(180),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withAlpha(200),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 스케줄 보기 버튼
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(50),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withAlpha(100),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLoading)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              const SizedBox(width: 6),
                              Text(
                                isLoading ? '로딩 중...' : '스케줄 보기',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
