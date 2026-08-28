import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:projecti_fan_app/controllers/favorites_controller.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/model/live_check_model.dart';
import 'package:projecti_fan_app/model/live_session_model.dart';
import 'package:projecti_fan_app/model/member.dart';
import 'package:projecti_fan_app/model/streamer_model.dart';
import 'package:projecti_fan_app/controllers/youtube_controller.dart';
import 'package:projecti_fan_app/model/youtube_video_model.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:projecti_fan_app/widget/components/youtube_video_card.dart';
import 'package:projecti_fan_app/utils/external_link.dart';
import 'package:projecti_fan_app/widget/components/tap_semantics.dart';

class StreamerDetail extends StatefulWidget {
  final StreamerModel pjiMember;
  final String group;
  final String memberKey;

  const StreamerDetail({
    super.key,
    required this.pjiMember,
    required this.group,
    required this.memberKey,
  });

  @override
  State<StreamerDetail> createState() => _StreamerDetailState();
}

class _StreamerDetailState extends State<StreamerDetail> {
  final GlobalController _global = Get.find<GlobalController>();
  final FavoritesController _favorites = Get.find<FavoritesController>();

  Member? _member;
  int _memberIndex = -1;
  Future<List<YouTubeVideoModel>>? _videosFuture;
  Future<List<LiveSessionModel>>? _sessionsFuture;

  bool get _isHoneyz => widget.group == 'honeyz';

  @override
  void initState() {
    super.initState();
    final members = _global.membersOf(widget.group);
    _memberIndex = members.indexWhere((m) => m.key == widget.memberKey);
    if (_memberIndex >= 0) {
      _member = members[_memberIndex];
      // 컨트롤러의 멤버별 캐시를 경유한다 — 프로필을 열 때마다 RSS 재조회 방지.
      _videosFuture = Get.find<YouTubeController>().videosFor(_member!);
      _sessionsFuture = _global.fetchRecentSessions(widget.memberKey);
    }
  }

  Future<void> _openChzzkLive(String broadcastId) async {
    final uri = Uri.parse(Member.liveUrlOf(broadcastId));
    await openExternalUrl(uri);
  }

  /// 이 멤버의 현재 라이브 상태 (없으면 null)
  LiveCheckModel? get _liveStatus {
    final statuses =
        _isHoneyz ? _global.honeyzLiveStatus : _global.acaxiaLiveStatus;
    return statuses[widget.memberKey];
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = AppColors.group(_isHoneyz);
    final themeColorDark = AppColors.groupDark(_isHoneyz);

    return Scaffold(
      backgroundColor: context.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildAppBar(context, themeColor)),
          SliverToBoxAdapter(
            child: _buildProfileSection(context, themeColor, themeColorDark),
          ),
          // 실시간 LIVE 상태 (방송 중일 때만)
          SliverToBoxAdapter(
            child: _buildLiveSection(context, themeColor),
          ),
          // 지난 방송 (기록이 있을 때만)
          SliverToBoxAdapter(
            child: _buildHistorySection(context, themeColor),
          ),
          // SNS 링크
          SliverToBoxAdapter(
            child: _buildSocialSection(context, themeColor, themeColorDark),
          ),
          // 최신 YouTube 영상
          SliverToBoxAdapter(
            child: _buildVideosSection(context, themeColor),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Color themeColor) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
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
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: themeColor,
                      size: 22,
                    ),
                  ),
                )),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '멤버 프로필',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textMain,
                ),
              ),
            ),
            // 최애 토글
            _buildFavoriteButton(themeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(Color themeColor) {
    if (widget.memberKey.isEmpty) return const SizedBox.shrink();
    return Obx(() {
      final isFav = _favorites.isFavorite(widget.group, widget.memberKey);
      return TapSemantics(
          label: isFav ? '최애 해제' : '최애 지정',
          child: GestureDetector(
            onTap: () => _favorites.toggle(widget.group, widget.memberKey),
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
              child: Icon(
                isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isFav ? AppColors.favorite : context.textFaint,
                size: 24,
              ),
            ),
          ));
    });
  }

  Widget _buildProfileSection(
      BuildContext context, Color themeColor, Color themeColorDark) {
    final birthdayLabel = widget.pjiMember.birthdayLabel;
    final days = widget.pjiMember.daysUntilBirthday;

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
                Member.profileAssetPathOf(widget.group, widget.memberKey),
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
                    _isHoneyz ? 'HONEYZ' : 'ACAXIA',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.pjiMember.name ?? '',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: context.textMain,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_isHoneyz ? "허니즈" : "아카시아"} 소속',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.textSub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // 생일 D-day 칩 (설정된 경우만)
                if (birthdayLabel != null && days != null) ...[
                  const SizedBox(height: 14),
                  _buildBirthdayChip(birthdayLabel, days),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthdayChip(String label, int days) {
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

  // ---------------- 실시간 LIVE ----------------

  Widget _buildLiveSection(BuildContext context, Color themeColor) {
    return Obx(() {
      final status = _liveStatus;
      if (status == null || !status.isLive) return const SizedBox.shrink();

      return TapSemantics(
          child: GestureDetector(
        onTap: () {
          if (_member != null) _openChzzkLive(_member!.chzzkBroadcastId);
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.live.withAlpha(70), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.live.withAlpha(25),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.live,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 6, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '치지직에서 보기',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.textFaint,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 11, color: context.textFaint),
                ],
              ),
              if (status.liveTitle?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(
                  status.liveTitle!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.textMain,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (status.viewerCountText.isNotEmpty) ...[
                    Icon(Icons.visibility_rounded,
                        size: 14, color: context.textFaint),
                    const SizedBox(width: 4),
                    Text(
                      status.viewerCountText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.textSub,
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  if (status.uptime.isNotEmpty) ...[
                    Icon(Icons.schedule_rounded,
                        size: 14, color: context.textFaint),
                    const SizedBox(width: 4),
                    Text(
                      status.uptime,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.textSub,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ));
    });
  }

  // ---------------- 지난 방송 ----------------

  /// 서버가 기록한 최근 방송 세션 목록. 데이터가 없거나(신규 배포 직후·미방송
  /// 멤버) 조회에 실패하면 섹션 자체를 숨긴다 — 보조 정보라 에러를 띄우지 않는다.
  Widget _buildHistorySection(BuildContext context, Color themeColor) {
    if (_sessionsFuture == null) return const SizedBox.shrink();

    return FutureBuilder<List<LiveSessionModel>>(
      future: _sessionsFuture,
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? [];
        if (sessions.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, size: 20, color: themeColor),
                    const SizedBox(width: 8),
                    Text(
                      '지난 방송',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textMain,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < sessions.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: context.textFaint.withAlpha(40),
                        ),
                      _buildSessionRow(context, sessions[i], themeColor),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionRow(
      BuildContext context, LiveSessionModel session, Color themeColor) {
    // "3시간 12분 · 최고 1,384명 · Just Chatting" — 없는 값은 항목째 생략.
    final details = [
      session.durationLabel,
      session.peakViewerText,
      session.liveCategoryValue ?? '',
    ].where((s) => s.isNotEmpty).join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              session.dateLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: themeColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.liveTitle ?? '(제목 없음)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textMain,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    details,
                    style: TextStyle(fontSize: 12, color: context.textFaint),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SNS ----------------

  Widget _buildSocialSection(
      BuildContext context, Color themeColor, Color themeColorDark) {
    final socialLinks = [
      SocialLink(
        name: '치지직',
        icon: 'assets/icons/chzzk_icon.png',
        url: widget.pjiMember.chzzk,
        color: const Color(0xFF00FFA3),
        description: '라이브 방송 시청',
      ),
      SocialLink(
        name: 'YouTube',
        icon: 'assets/icons/youtube_icon.png',
        url: widget.pjiMember.youtube,
        color: const Color(0xFFFF0000),
        description: '영상 콘텐츠',
      ),
      SocialLink(
        name: 'X (Twitter)',
        icon: 'assets/icons/x_icon.png',
        url: widget.pjiMember.twitter,
        color: const Color(0xFF000000),
        description: '소식 및 업데이트',
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Row(
              children: [
                Icon(Icons.link_rounded, size: 20, color: themeColor),
                const SizedBox(width: 8),
                Text(
                  'SNS & 채널',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textMain,
                  ),
                ),
              ],
            ),
          ),
          ...socialLinks
              .map((link) => _buildSocialCard(context, link, themeColor)),
        ],
      ),
    );
  }

  Widget _buildSocialCard(
      BuildContext context, SocialLink link, Color themeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: link.url != null && link.url!.isNotEmpty
              ? () async {
                  final uri = Uri.parse(link.url!);
                  await openExternalUrl(uri);
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: link.color.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(link.icon, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        link.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: themeColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: themeColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- 최신 YouTube 영상 ----------------

  Widget _buildVideosSection(BuildContext context, Color themeColor) {
    if (_videosFuture == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Row(
              children: [
                const Icon(Icons.play_circle_fill_rounded,
                    size: 20, color: Color(0xFFFF0000)),
                const SizedBox(width: 8),
                Text(
                  '최신 영상',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textMain,
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<List<YouTubeVideoModel>>(
            future: _videosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF0000),
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              final videos = snapshot.data ?? [];
              if (snapshot.hasError || videos.isEmpty) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Text(
                    '최신 영상을 불러올 수 없습니다',
                    style: TextStyle(fontSize: 13, color: context.textFaint),
                  ),
                );
              }
              final top = videos.take(3).toList();
              return Column(
                children: [
                  for (int i = 0; i < top.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: YouTubeVideoCard(video: top[i], index: i),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class SocialLink {
  final String name;
  final String icon;
  final String? url;
  final Color color;
  final String description;

  const SocialLink({
    required this.name,
    required this.icon,
    required this.url,
    required this.color,
    required this.description,
  });
}
