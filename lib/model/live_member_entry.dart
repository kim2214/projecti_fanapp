import 'package:projecti_fan_app/model/live_check_model.dart';

/// 통합 LIVE 화면에서 그룹 구분 없이 방송 중인 멤버를 표시하기 위한 집계 모델.
/// 카드 위젯이 추가 조회 없이 바로 그릴 수 있도록 필요한 정보를 한데 묶는다.
class LiveMemberEntry {
  /// 소속 그룹 ('honeyz' | 'acaxia')
  final String group;

  /// 표시용 멤버 이름 (예: '오화요')
  final String memberName;

  /// 완성된 프로필 에셋 경로 (예: 'assets/honeyz/ohwayo_profile.png')
  final String assetPath;

  /// 치지직 방송 ID (외부 링크 생성용)
  final String broadcastId;

  /// 라이브 상태 (제목/시청자수/업타임 등 계산 getter 포함)
  final LiveCheckModel status;

  const LiveMemberEntry({
    required this.group,
    required this.memberName,
    required this.assetPath,
    required this.broadcastId,
    required this.status,
  });

  bool get isHoneyz => group == 'honeyz';
}
