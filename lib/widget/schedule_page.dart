import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/widget/components/tap_semantics.dart';

class SchedulePageWidget extends StatefulWidget {
  const SchedulePageWidget({super.key});

  @override
  State<SchedulePageWidget> createState() => _SchedulePageWidgetState();
}

class _SchedulePageWidgetState extends State<SchedulePageWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final globalController = Get.find<GlobalController>();

    return Obx(() {
      final isHoneyz = globalController.selectedGroup.value == 'honeyz';
      final themeColor = AppColors.group(isHoneyz);
      final themeColorDark = AppColors.groupDark(isHoneyz);
      final group = globalController.selectedGroup.value;
      final members = globalController.membersOf(group);
      // 카탈로그가 순서·구성의 단일 소스이고, URL은 같은 순서로 펼쳐져 온다.
      // 지연 빌더(SliverChildBuilderDelegate) 안에서 읽으면 Obx가 스케줄 갱신을
      // 감지하지 못하므로, 여기서 미리 읽어 의존성을 등록한다.
      final scheduleUrls = globalController.scheduleImageUrlsOf(group);
      // 키가 없으면 아직 요청 전(스플래시가 곧 시작한다) — 로딩으로 본다.
      final status =
          globalController.scheduleStatus[group] ?? LoadStatus.loading;
      // 스케줄이 하나라도 있으면 상태와 무관하게 목록을 보여준다 (새로고침 중 등).
      final hasAny = scheduleUrls.any((url) => url.isNotEmpty);

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              themeColor.withAlpha(30),
              context.bg,
              themeColor.withAlpha(15),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: RefreshIndicator(
          color: themeColorDark,
          onRefresh: () => _onRefresh(globalController, isHoneyz),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 헤더
              SliverToBoxAdapter(
                child: _buildHeader(
                    isHoneyz, themeColor, themeColorDark, members.length),
              ),
              // 불러오는 중·실패는 "스케줄 등록 전" 카드 대신 상태를 그대로 알린다.
              if (!hasAny && status != LoadStatus.loaded)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: status == LoadStatus.failed
                      // 글자용 톤 — acaxiaDark는 흰 배경 대비가 낮다(group_page와 동일).
                      ? _buildLoadFailed(globalController,
                          isHoneyz ? AppColors.honeyzDark : context.acaxiaInk)
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 100),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: themeColorDark,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                )
              else
                // 멤버 스케줄 리스트
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // 스케줄 문서가 없는 멤버는 빈 URL → "스케줄 등록 전"으로 표시된다.
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ScheduleCard(
                            imageURL: scheduleUrls[index],
                            memberName: members[index].name,
                            themeColor: themeColor,
                            themeColorDark: themeColorDark,
                          ),
                        );
                      },
                      childCount: members.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  /// 당겨서 새로고침 - 스케줄을 다시 불러옴
  Future<void> _onRefresh(
      GlobalController globalController, bool isHoneyz) async {
    await globalController.loadScheduleFireStore(forceRefresh: true);
  }

  /// 스케줄 조회에 실패했고 보여줄 캐시도 없을 때 (오프라인 등).
  Widget _buildLoadFailed(GlobalController globalController, Color inkColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 40, color: inkColor.withAlpha(150)),
          const SizedBox(height: 12),
          Text(
            '스케줄을 불러오지 못했어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '네트워크 연결을 확인한 뒤 다시 시도해 주세요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: context.textFaint),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () =>
                globalController.loadScheduleFireStore(forceRefresh: true),
            icon: Icon(Icons.refresh_rounded, color: inkColor),
            label: Text(
              '다시 시도',
              style: TextStyle(color: inkColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      bool isHoneyz, Color themeColor, Color themeColorDark, int memberCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 그룹 정보
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
                        'WEEKLY SCHEDULE',
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
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: context.textMain,
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
              color: context.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppColors.softShadow,
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textMain,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 1,
                  height: 16,
                  color: context.divider,
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: themeColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '주간 스케줄',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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

  @override
  bool get wantKeepAlive => true;
}

class ScheduleCard extends StatelessWidget {
  final String imageURL;
  final String memberName;
  final Color themeColor;
  final Color themeColorDark;

  const ScheduleCard({
    super.key,
    required this.imageURL,
    required this.memberName,
    required this.themeColor,
    required this.themeColorDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasSchedule = imageURL.isNotEmpty;
    // 헤더 그라데이션(브랜드색) 위 글자색 — 라일락 위 흰 글자는 대비 1.5:1.
    final onHeader = AppColors.onBrand(themeColor);

    return TapSemantics(
        child: GestureDetector(
      onTap: hasSchedule
          ? () {
              // URL을 쿼리 파라미터에 끼워넣지 않는다 — 다운로드 URL의 '?'/'&'가
              // 파싱을 깨뜨려 상세 화면에서만 이미지가 실패한다.
              context.push('/scheduleDetail',
                  extra: (imageURL: imageURL, name: memberName));
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: themeColor.withAlpha(25),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 멤버 이름 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    themeColor,
                    themeColorDark,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        memberName.isNotEmpty ? memberName[0] : '?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: onHeader,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memberName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: onHeader,
                          ),
                        ),
                        Text(
                          hasSchedule ? '스케줄 등록됨' : '스케줄 등록 전',
                          style: TextStyle(
                            fontSize: 11,
                            color: onHeader.withAlpha(180),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasSchedule)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.open_in_full_rounded,
                        size: 18,
                        color: onHeader,
                      ),
                    ),
                ],
              ),
            ),
            // 스케줄 이미지
            hasSchedule
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: Container(
                      color: themeColor.withAlpha(10),
                      constraints: const BoxConstraints(
                        minHeight: 200,
                        maxHeight: 400,
                      ),
                      child: ExtendedImage.network(
                        imageURL,
                        fit: BoxFit.contain,
                        cache: true,
                        loadStateChanged: (ExtendedImageState state) {
                          switch (state.extendedImageLoadState) {
                            case LoadState.loading:
                              return Container(
                                height: 200,
                                color: themeColor.withAlpha(15),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: themeColor,
                                  ),
                                ),
                              );
                            case LoadState.failed:
                              return Container(
                                height: 200,
                                color: themeColor.withAlpha(15),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported_rounded,
                                      size: 40,
                                      color: themeColor.withAlpha(150),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '이미지를 불러올 수 없습니다',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: context.textFaint,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            case LoadState.completed:
                              return null;
                          }
                        },
                      ),
                    ),
                  )
                : Container(
                    height: 150,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: themeColor.withAlpha(15),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 36,
                          color: themeColor.withAlpha(150),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '이번 주 스케줄이\n아직 등록되지 않았어요',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: context.textFaint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '스케줄이 올라오면 여기에 표시됩니다',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.textFaint,
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
