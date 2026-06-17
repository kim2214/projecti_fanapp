import 'package:flutter/material.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/model/live_check_model.dart';
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

  // 로딩 상태 관리 (Rx로 변경하여 Obx에서 감지)
  final RxBool _isLoading = true.obs;
  String? _lastLoadedGroup;
  bool _isLoadingInProgress = false;

  // GetX worker
  Worker? _groupChangeWorker;

  @override
  void initState() {
    super.initState();

    // 초기 데이터 로드
    _loadData();

    // 그룹 변경 감지 리스너
    _groupChangeWorker = ever(_globalController.selectedGroup, (group) {
      if (_lastLoadedGroup != group) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _groupChangeWorker?.dispose();
    _isLoading.close();
    super.dispose();
  }

  Future<void> _loadData() async {
    // 이미 로딩 중이면 스킵 (중복 호출 방지)
    if (_isLoadingInProgress) return;

    final currentGroup = _globalController.selectedGroup.value;

    // 이미 같은 그룹 데이터가 로드 완료되었으면 스킵
    if (_lastLoadedGroup == currentGroup && !_isLoading.value) {
      return;
    }

    _isLoadingInProgress = true;
    _isLoading.value = true;

    try {
      // 멤버 데이터와 라이브 체크 데이터를 순차적으로 로드
      await _globalController.loadStreamerFireStore();
      await _globalController.liveCheck();
      _lastLoadedGroup = currentGroup;
    } catch (e) {
      // error handled by loading state
    } finally {
      _isLoadingInProgress = false;
      if (mounted) {
        _isLoading.value = false;
      }
    }
  }

  /// 당겨서 새로고침 - 멤버 정보와 라이브 상태를 다시 불러옴
  Future<void> _onRefresh() async {
    if (_isLoadingInProgress) return;
    _isLoadingInProgress = true;
    try {
      await _globalController.loadStreamerFireStore(forceRefresh: true);
      await _globalController.refreshLiveStatus();
    } catch (e) {
      // error handled by loading state
    } finally {
      _isLoadingInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(() {
      final isHoneyz = _globalController.selectedGroup.value == 'honeyz';
      final themeColor = isHoneyz ? AppColors.honeyz : AppColors.acaxia;
      final themeColorDark = isHoneyz ? AppColors.honeyzDark : AppColors.acaxiaDark;

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
        child: _buildBody(isHoneyz, themeColor, themeColorDark),
      );
    });
  }

  Widget _buildBody(bool isHoneyz, Color themeColor, Color themeColorDark) {
    final members =
        isHoneyz ? _globalController.honeyz : _globalController.acaxia;

    // 로딩 중이거나 멤버 데이터가 없는 경우만 로딩 표시
    if (_isLoading.value || members.isEmpty) {
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
    }

    return _buildContent(isHoneyz, themeColor, themeColorDark);
  }

  Widget _buildContent(bool isHoneyz, Color themeColor, Color themeColorDark) {
    final members =
        isHoneyz ? _globalController.honeyz : _globalController.acaxia;
    final liveStatusList = isHoneyz
        ? _globalController.honeyzliveCheckList
        : _globalController.acaxialiveCheckList;
    final catalog =
        _globalController.membersOf(_globalController.selectedGroup.value);

    // 라이브 체크 데이터가 없을 경우를 위한 기본값
    final defaultLiveStatus = LiveCheckModel(status: 'CLOSE', liveTitle: null);

    return RefreshIndicator(
      color: themeColorDark,
      onRefresh: _onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                  // 인덱스 범위 체크
                  if (index >= members.length || index >= catalog.length) {
                    return const SizedBox.shrink();
                  }
                  // 라이브 상태 데이터가 없으면 기본값 사용
                  final status = index < liveStatusList.length
                      ? liveStatusList[index]
                      : defaultLiveStatus;
                  return StreamerCard(
                    index: index,
                    streamer: members[index],
                    status: status,
                    assetName: catalog[index].assetName,
                    memberName: catalog[index].name,
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
                        color: AppColors.textPrimary,
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
                    color: AppColors.textPrimary,
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
