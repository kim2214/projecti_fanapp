import 'package:flutter/material.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:projecti_fan_app/controllers/favorites_controller.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/model/member.dart';
import 'package:projecti_fan_app/widget/components/live_member_card.dart';
import 'package:projecti_fan_app/utils/external_link.dart';
import 'package:projecti_fan_app/widget/components/tap_semantics.dart';

/// 통합 LIVE 현황 화면.
/// 그룹(허니즈/아카시아) 전환 없이 지금 방송 중인 모든 멤버를 한 화면에 보여준다.
class LivePageWidget extends StatefulWidget {
  const LivePageWidget({super.key});

  @override
  State<LivePageWidget> createState() => _LivePageWidgetState();
}

class _LivePageWidgetState extends State<LivePageWidget> {
  final GlobalController _globalController = Get.find<GlobalController>();
  final FavoritesController _favorites = Get.find<FavoritesController>();

  // 첫 진입 시 초기 폴링 진행 여부
  final RxBool _initialLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _initialLoading.close();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _globalController.refreshAllLiveStatus();
    // 폴링(최대 8초) 중 뒤로가기로 dispose되면 닫힌 Rx에 값을 넣게 된다.
    if (mounted) _initialLoading.value = false;
  }

  Future<void> _onRefresh() async {
    await _globalController.refreshAllLiveStatus();
  }

  Future<void> _openChzzkLive(String broadcastId) async {
    final uri = Uri.parse(Member.liveUrlOf(broadcastId));
    await openExternalUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.live.withAlpha(20),
              context.bg,
              AppColors.acaxia.withAlpha(20),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: Obx(() {
                  // 시청자순 정렬된 통합 목록을 받아 최애 멤버를 맨 위로 재배치
                  final base = _globalController.liveMembersAcrossGroups;
                  final liveMembers = [
                    ...base.where(
                        (e) => _favorites.isFavorite(e.group, e.memberKey)),
                    ...base.where(
                        (e) => !_favorites.isFavorite(e.group, e.memberKey)),
                  ];

                  // 첫 폴링 중이고 아직 데이터가 없으면 로딩 표시
                  if (_initialLoading.value && liveMembers.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.live,
                        strokeWidth: 3,
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.live,
                    onRefresh: _onRefresh,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildSummary(liveMembers.length),
                        ),
                        if (liveMembers.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final entry = liveMembers[index];
                                  return LiveMemberCard(
                                    entry: entry,
                                    isFavorite: _favorites.isFavorite(
                                        entry.group, entry.memberKey),
                                    onTap: () =>
                                        _openChzzkLive(entry.broadcastId),
                                  );
                                },
                                childCount: liveMembers.length,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 뒤로가기
          TapSemantics(
              label: '뒤로가기',
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.live,
                    size: 22,
                  ),
                ),
              )),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '통합 LIVE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textMain,
                  ),
                ),
                Text(
                  '지금 방송 중인 모든 멤버',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // LIVE 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.live.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.podcasts_rounded, size: 14, color: AppColors.live),
                SizedBox(width: 6),
                Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.live,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Row(
        children: [
          Icon(
            count > 0 ? Icons.fiber_manual_record : Icons.nightlight_round,
            size: 16,
            color: count > 0 ? AppColors.live : context.textFaint,
          ),
          const SizedBox(width: 8),
          Text(
            count > 0 ? '지금 $count명 방송 중' : '방송 중인 멤버 없음',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: context.textMain,
            ),
          ),
          const Spacer(),
          Text(
            '당겨서 새로고침',
            style: TextStyle(
              fontSize: 11,
              color: context.textFaint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.nightlight_round,
            size: 48,
            color: AppColors.honeyz.withAlpha(120),
          ),
          const SizedBox(height: 14),
          Text(
            '지금은 방송 중인 멤버가 없어요',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: context.textFaint,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '방송이 시작되면 여기에 표시됩니다',
            style: TextStyle(
              fontSize: 12,
              color: context.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}
