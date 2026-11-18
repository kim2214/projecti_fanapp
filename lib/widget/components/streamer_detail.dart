import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/controllers/youtube_controller.dart';
import 'package:projecti_fan_app/model/follower_point_model.dart';
import 'package:projecti_fan_app/model/group.dart';
import 'package:projecti_fan_app/model/live_check_model.dart';
import 'package:projecti_fan_app/model/live_session_model.dart';
import 'package:projecti_fan_app/model/member.dart';
import 'package:projecti_fan_app/model/streamer_model.dart';
import 'package:projecti_fan_app/model/youtube_video_model.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:projecti_fan_app/widget/components/streamer_detail/detail_header.dart';
import 'package:projecti_fan_app/widget/components/streamer_detail/follower_section.dart';
import 'package:projecti_fan_app/widget/components/streamer_detail/history_section.dart';
import 'package:projecti_fan_app/widget/components/streamer_detail/live_card.dart';
import 'package:projecti_fan_app/widget/components/streamer_detail/profile_card.dart';
import 'package:projecti_fan_app/widget/components/streamer_detail/social_section.dart';
import 'package:projecti_fan_app/widget/components/streamer_detail/videos_section.dart';

/// 멤버 프로필. 프로필 데이터(이름·생일·SNS)는 [group]/[memberKey]로
/// [GlobalController]의 캐시에서 읽는다 — 경로가 쿼리만으로 완결되고, 화면
/// 사이에 모델을 넘기지 않아도 된다. 캐시가 없으면 빈 프로필로 그린다.
///
/// 각 섹션은 `streamer_detail/`의 전용 위젯으로 분리돼 있고, 이 화면은 멤버
/// 조회·보조 데이터 Future 로드·섹션 배치만 맡는다.
class StreamerDetail extends StatefulWidget {
  final Group group;
  final String memberKey;

  const StreamerDetail({
    super.key,
    required this.group,
    required this.memberKey,
  });

  @override
  State<StreamerDetail> createState() => _StreamerDetailState();
}

class _StreamerDetailState extends State<StreamerDetail> {
  final GlobalController _global = Get.find<GlobalController>();

  Member? _member;
  Future<List<YouTubeVideoModel>>? _videosFuture;
  Future<List<LiveSessionModel>>? _sessionsFuture;
  Future<List<FollowerPointModel>>? _followersFuture;

  StreamerModel get _streamer =>
      _global.streamerOf(widget.group, widget.memberKey) ??
      StreamerModel.empty();

  /// 이 멤버의 현재 라이브 상태 (없으면 null)
  LiveCheckModel? get _liveStatus =>
      _global.liveStatusOf(widget.group)[widget.memberKey];

  @override
  void initState() {
    super.initState();
    final members = _global.membersOf(widget.group);
    final index = members.indexWhere((m) => m.key == widget.memberKey);
    if (index >= 0) {
      _member = members[index];
      // 컨트롤러의 멤버별 캐시를 경유한다 — 프로필을 열 때마다 RSS 재조회 방지.
      _videosFuture = _loadVideos(_member!);
      // 목록은 5개만 보이지만 시청자 추이 차트는 10회를 쓴다 — 한 번에 조회.
      _sessionsFuture = _global.fetchRecentSessions(widget.memberKey, limit: 10);
      _followersFuture = _global.fetchFollowerHistory(widget.memberKey);
    }
  }

  Future<List<YouTubeVideoModel>> _loadVideos(Member member) =>
      Get.find<YouTubeController>().videosFor(member);

  void _retryVideos() {
    final member = _member;
    if (member == null) return;
    // 화살표 함수로 쓰면 대입식의 값(Future)을 돌려줘 setState가 assert로 거부한다.
    setState(() {
      _videosFuture = _loadVideos(member);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      // 다른 상세 화면처럼 상단바를 고정하고 전체를 SafeArea로 감싼다 — 예전엔
      // 상단바가 함께 스크롤돼, 올라간 본문이 상태 표시줄 아이콘과 겹쳤다.
      body: SafeArea(
        child: Column(
          children: [
            StreamerDetailAppBar(
                group: widget.group, memberKey: widget.memberKey),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // 프로필·SNS는 스트리머 캐시를 읽으므로 Obx — 데이터가 오기 전에 열어도
                  // (홈 "내 최애" 타일은 로드 전에 누를 수 있다) 도착하면 채워진다.
                  SliverToBoxAdapter(
                    child: Obx(() => StreamerProfileCard(
                          group: widget.group,
                          memberKey: widget.memberKey,
                          streamer: _streamer,
                          fallbackName: _member?.name,
                        )),
                  ),
                  // 실시간 LIVE 상태 (방송 중일 때만)
                  SliverToBoxAdapter(
                    child: Obx(() => StreamerLiveCard(
                          status: _liveStatus,
                          broadcastId: _member?.chzzkBroadcastId,
                        )),
                  ),
                  // 팔로워 추이 (기록이 있을 때만)
                  SliverToBoxAdapter(
                    child: StreamerFollowerSection(
                        group: widget.group, future: _followersFuture),
                  ),
                  // 지난 방송 (기록이 있을 때만)
                  SliverToBoxAdapter(
                    child: StreamerHistorySection(
                      group: widget.group,
                      future: _sessionsFuture,
                      broadcastId: _member?.chzzkBroadcastId,
                    ),
                  ),
                  // SNS 링크
                  SliverToBoxAdapter(
                    child: Obx(() => StreamerSocialSection(
                          group: widget.group,
                          streamer: _streamer,
                        )),
                  ),
                  // 최신 YouTube 영상
                  SliverToBoxAdapter(
                    child: StreamerVideosSection(
                      group: widget.group,
                      memberKey: widget.memberKey,
                      future: _videosFuture,
                      onRetry: _retryVideos,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 50)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
