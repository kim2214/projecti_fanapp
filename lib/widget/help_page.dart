import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:projecti_fan_app/theme/app_colors.dart';
import 'package:projecti_fan_app/utils/external_link.dart';
import 'package:projecti_fan_app/widget/components/tap_semantics.dart';

/// 도움말·문의·앱 정보. 홈 대시보드 맨 아래 링크로 진입한다.
///
/// 문의는 별도 연락처 없이 Play 스토어 페이지(리뷰·개발자 연락처)로 보낸다.
class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.devkim.honeyz_fan_app';
  static const String appName = 'Project I Fan App';
  static const String disclaimer = '팬이 만든 비공식 앱이며, 프로젝트아이 공식과는 무관합니다.';

  /// 자주 묻는 질문 (질문, 답). 앱 동작이 바뀌면 여기도 함께 고친다.
  static const List<(String, String)> faqs = [
    (
      '방송 정보는 얼마나 자주 바뀌나요?',
      '서버가 1분마다(새벽 4시~10시는 3분마다) 치지직 방송 상태를 확인합니다. '
          '앱을 열어 두면 2분마다, 그리고 화면을 아래로 당기면 바로 새로고침돼요.',
    ),
    (
      '방송 알림이 안 와요.',
      '상단 종(🔔) 버튼의 알림 설정에서 라이브 알림 범위를 확인해 주세요. '
          '기본값 "최애만"은 별(⭐)로 지정한 멤버의 방송만 알려드립니다. '
          '휴대폰 설정에서 이 앱의 알림이 꺼져 있거나, 삼성 등 일부 기기의 절전 '
          '기능이 앱을 제한하면 알림이 늦거나 오지 않을 수 있어요.',
    ),
    (
      '최애 멤버는 어떻게 지정하나요?',
      '멤버 탭의 멤버 카드나 프로필에서 별(⭐)을 누르면 됩니다. 최애 멤버는 통합 LIVE '
          '화면 맨 위에 보이고, 알림 범위가 "최애만"일 때 방송 알림을 받습니다.',
    ),
    (
      '홈 화면 위젯은 어떻게 추가하나요?',
      '(Android) 홈 화면 빈 곳을 길게 누르고 위젯에서 이 앱을 골라 추가하세요. '
          '방송 중인 멤버를 시청자 수 순서로 보여주며, 방송이 시작·종료되면 바로 '
          '갱신됩니다.',
    ),
    (
      '스케줄은 언제 올라오나요?',
      '멤버가 공개한 주간 스케줄을 앱 운영자가 직접 등록합니다. 공개 직후에는 '
          '등록이 조금 늦을 수 있어요. 스케줄 알림을 켜 두면 등록될 때 알려드립니다.',
    ),
    (
      '정보는 어디에서 가져오나요?',
      '방송 상태·방송 기록·팔로워 수는 치지직, 최신 영상은 YouTube 공식 피드에서 '
          '가져옵니다. 표시 시점에 따라 실제와 약간 차이가 있을 수 있어요.',
    ),
  ];

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  /// "2.6.2 (19)". 읽기 전·실패 시 빈 문자열 (버전 줄만 비운다).
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    } catch (_) {
      // 버전 표시는 보조 정보 — 실패해도 화면은 그대로 쓴다.
    }
  }

  void _openLicenses() {
    showLicensePage(
      context: context,
      applicationName: HelpPage.appName,
      applicationVersion: _version,
      applicationLegalese: HelpPage.disclaimer,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                children: [
                  _buildSectionTitle('자주 묻는 질문'),
                  _buildCard(
                    child: Column(
                      children: [
                        for (final (q, a) in HelpPage.faqs) _buildFaq(q, a),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('문의·앱 정보'),
                  _buildCard(
                    child: Column(
                      children: [
                        _buildLinkTile(
                          icon: Icons.rate_review_outlined,
                          title: '문의·의견 보내기',
                          subtitle: 'Play 스토어 리뷰나 개발자 연락처로 남겨 주세요',
                          onTap: () =>
                              openExternalUrl(Uri.parse(HelpPage.playStoreUrl)),
                        ),
                        Divider(height: 1, color: context.divider),
                        _buildLinkTile(
                          icon: Icons.description_outlined,
                          title: '오픈소스 라이선스',
                          onTap: _openLicenses,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _version.isEmpty
                              ? HelpPage.appName
                              : '${HelpPage.appName} $_version',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.textSub,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          HelpPage.disclaimer,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textFaint,
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

  Widget _buildAppBar() {
    return Padding(
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
                    color: context.textMain,
                    size: 22,
                  ),
                ),
              )),
          const SizedBox(width: 16),
          Text(
            '도움말',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: context.textMain,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    // 배경색은 Material이 칠한다 — 색 있는 DecoratedBox 위에서는 ListTile·
    // ExpansionTile의 탭 잉크가 가려진다. 그림자만 바깥 Container가 맡는다.
    return Container(
      decoration: BoxDecoration(
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
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }

  Widget _buildFaq(String question, String answer) {
    return Theme(
      // ExpansionTile 기본 구분선 제거
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.centerLeft,
        iconColor: context.textSub,
        collapsedIconColor: context.textFaint,
        title: Text(
          question,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.textMain,
          ),
        ),
        children: [
          Text(
            answer,
            style: TextStyle(fontSize: 13, height: 1.5, color: context.textSub),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: context.textSub),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.textMain,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(subtitle,
              style: TextStyle(fontSize: 12, color: context.textFaint)),
      trailing: Icon(Icons.chevron_right_rounded, color: context.textFaint),
      onTap: onTap,
    );
  }
}
