import 'package:flutter/material.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/model/streamer_model.dart';
import 'package:projecti_fan_app/widget/components/tap_semantics.dart';

class GroupSelectWidget extends StatefulWidget {
  const GroupSelectWidget({super.key});

  @override
  State<GroupSelectWidget> createState() => _GroupSelectWidgetState();
}

class _GroupSelectWidgetState extends State<GroupSelectWidget>
    with TickerProviderStateMixin {
  final globalController = Get.find<GlobalController>();

  // 그룹별 테마 컬러

  // 로딩 상태
  bool _isLoadingHoneyz = false;
  bool _isLoadingAcaxia = false;

  // build에서 만들면 setState(그룹 카드 로딩 표시)마다 새 Future가 생겨
  // 화면이 스피너로 되돌아가고 불필요한 재조회가 난다 — 한 번만 만든다.
  late final Future<Map<String, StreamerModel>> _streamersFuture =
      globalController.loadStreamerFireStore();

  Future<void> _selectGroup(String group) async {
    setState(() {
      _isLoadingHoneyz = group == 'honeyz';
      _isLoadingAcaxia = group == 'acaxia';
    });
    await globalController.selectGroup(group);

    // 스케줄을 미리 받아두되, 결과로 진입을 막지는 않는다. 멤버·라이브·영상은
    // 스케줄과 무관하게 동작하며, 조회에 실패하면 GlobalController가 안내
    // 스낵바를 띄운다. (예전엔 빈 결과면 아무 반응 없이 멈춰 오프라인에서
    //  앱에 아예 들어갈 수 없었다.)
    await globalController.loadScheduleFireStore();
    if (!mounted) return;

    setState(() {
      _isLoadingHoneyz = false;
      _isLoadingAcaxia = false;
    });
    context.push('/baseScreen');
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
          child: FutureBuilder(
            future: _streamersFuture,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              // hasError를 먼저 본다 — 에러일 때도 hasData는 false라, 순서가
              // 뒤바뀌면 아래 오류 화면에 영영 도달하지 못하고 스피너에 갇힌다.
              if (snapshot.hasError) {
                return _buildLoadError(context);
              }
              if (snapshot.hasData == false) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.honeyz,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '데이터를 불러오는 중...',
                        style: TextStyle(
                          color: context.textSub,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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

  Widget _buildLoadError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: context.textFaint,
          ),
          const SizedBox(height: 16),
          Text(
            '오류가 발생했습니다',
            style: TextStyle(
              fontSize: 16,
              color: context.textSub,
            ),
          ),
        ],
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
                    color: AppColors.honeyz,
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
                    color: AppColors.acaxia,
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
    required String group,
    required String name,
    required String subtitle,
    required String description,
    required Color color,
    required String logoAsset,
    required bool isLoading,
  }) {
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
    ));
  }
}
