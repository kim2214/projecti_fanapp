import 'dart:async';

import 'package:flutter/material.dart';
import 'package:projecti_fan_app/model/group.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/widget/components/tap_semantics.dart';

class GroupSelectWidget extends StatefulWidget {
  const GroupSelectWidget({super.key});

  @override
  State<GroupSelectWidget> createState() => _GroupSelectWidgetState();
}

class _GroupSelectWidgetState extends State<GroupSelectWidget> {
  final globalController = Get.find<GlobalController>();

  // 로딩 상태
  /// 처리 중인 그룹 (없으면 null)
  Group? _loadingGroup;

  Future<void> _selectGroup(Group group) async {
    // 한 그룹을 처리하는 동안 다른 카드 탭도 무시한다 — 연타하면 두 호출이
    // 모두 끝까지 돌아 /baseScreen이 두 겹으로 push됐다.
    if (_loadingGroup != null) return;
    setState(() => _loadingGroup = group);
    try {
      await globalController.selectGroup(group);

      // 스케줄을 미리 받아두되, 결과로 진입을 막지는 않는다. 멤버·라이브·영상은
      // 스케줄과 무관하게 동작하며, 조회에 실패하면 GlobalController가 안내
      // 스낵바를 띄운다. (예전엔 빈 결과면 아무 반응 없이 멈춰 오프라인에서
      //  앱에 아예 들어갈 수 없었다.)
      await globalController.loadScheduleFireStore();
      if (!mounted) return;
      unawaited(context.push('/baseScreen'));
    } finally {
      if (mounted) {
        setState(() => _loadingGroup = null);
      }
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
              AppColors.honeyz.withAlpha(30),
              context.bg,
              AppColors.acaxia.withAlpha(30),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          // 멤버 데이터는 그룹 선택 뒤 각 화면이 불러온다 — 여기서 미리 받을
          // 필요가 없다 (첫 실행엔 그룹이 없어 어차피 빈 결과였다).
          child: _buildContent(),
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
                    group: Group.honeyz,
                    description: '달콤한 매력의 버츄얼 아이돌',
                  ),
                ),
                const SizedBox(height: 20),
                // 아카시아 카드
                Expanded(
                  child: _buildGroupCard(
                    group: Group.acaxia,
                    description: '신비로운 매력의 버츄얼 아이돌',
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
              color: context.textFaint,
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
        //     color: context.textMain,
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
        //         color: AppColors.honeyz,
        //       ),
        //       const SizedBox(width: 8),
        //       const Text(
        //         'SCHEDULE',
        //         style: TextStyle(
        //           fontSize: 14,
        //           fontWeight: FontWeight.w700,
        //           letterSpacing: 2,
        //           color: context.textMain,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),

        const SizedBox(height: 16),
        Text(
          '그룹 선택',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: context.textMain,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard({
    required Group group,
    required String description,
  }) {
    final name = group.label;
    final subtitle = group.labelEn;
    final color = AppColors.group(group);
    final logoAsset = group.logoAsset;
    final isLoading = _loadingGroup == group;
    // 라일락 위 흰 글자는 대비 1.5:1이라 거의 안 읽힌다.
    final foreground = AppColors.onBrand(color);
    return TapSemantics(
        child: GestureDetector(
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
            const Positioned(
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
                  // 텍스트 정보 — 작은 화면·큰 글꼴에서 카드 높이를 넘으면
                  // 넘치는 대신 통째로 줄여 그린다.
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
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
                              color: foreground.withAlpha(180),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: foreground,
                              letterSpacing: -0.5,
                            ),
                          ),
                          // const SizedBox(height: 8),
                          // Text(
                          //   description,
                          //   style: TextStyle(
                          //     fontSize: 13,
                          //     color: Colors.white.withAlpha(200),
                          //     fontWeight: FontWeight.w500,
                          //   ),
                          // ),
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
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: foreground,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: foreground,
                                  ),
                                const SizedBox(width: 6),
                                Text(
                                  isLoading ? '로딩 중...' : '스케줄 보기',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: foreground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
