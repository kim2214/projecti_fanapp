// YouTubeController의 멤버 선택 폴백/채널 URL 파생 로직 단위 테스트.
// GlobalController를 생성자로 주입해 Get 레지스트리·네트워크 없이 검증한다.
// (loadVideos 등 네트워크 경로는 호출하지 않는다.)

import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/controllers/youtube_controller.dart';

void main() {
  YouTubeController controllerForGroup(String group) {
    final global = GlobalController();
    global.selectedGroup.value = group;
    return YouTubeController(globalController: global);
  }

  group('effectiveSelectedMemberKey', () {
    test('선택 미설정이면 그룹의 첫 번째 멤버', () {
      final c = controllerForGroup('honeyz');
      expect(c.effectiveSelectedMemberKey, 'honeychurros');
    });

    test('현재 그룹에 없는 키가 선택돼 있으면 첫 번째 멤버로 폴백', () {
      final c = controllerForGroup('honeyz');
      c.selectedMemberKey.value = 'nonexistent';
      expect(c.effectiveSelectedMemberKey, 'honeychurros');
    });

    test('유효한 키가 선택돼 있으면 그 키를 유지', () {
      final c = controllerForGroup('honeyz');
      c.selectedMemberKey.value = 'damyui';
      expect(c.effectiveSelectedMemberKey, 'damyui');
    });
  });

  group('currentChannelUrl', () {
    test('선택된 멤버의 채널 영상 URL을 만든다', () {
      final c = controllerForGroup('honeyz');
      // 허니츄러스 채널 ID 기반
      expect(
        c.currentChannelUrl,
        'https://www.youtube.com/channel/UCkQFRBUPh5mcF1kca4f_DvQ/videos',
      );
    });

    test('acaxia 그룹의 첫 멤버 채널 URL', () {
      final c = controllerForGroup('acaxia');
      // 포포포포 채널 ID 기반
      expect(
        c.currentChannelUrl,
        'https://www.youtube.com/channel/UCXE5gQZ5WIbtT6FJtG2g5ag/videos',
      );
    });
  });
}
