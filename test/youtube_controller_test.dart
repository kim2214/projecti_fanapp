// YouTubeController의 멤버 선택 폴백/채널 URL 파생 로직 단위 테스트.
// GlobalController·YouTubeService를 생성자로 주입해 Get 레지스트리·네트워크 없이 검증한다.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/controllers/youtube_controller.dart';
import 'package:projecti_fan_app/model/youtube_video_model.dart';
import 'package:projecti_fan_app/services/youtube_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 채널별 응답을 테스트가 직접 완료시키는 가짜 서비스.
class _FakeYouTubeService implements YouTubeService {
  final Map<String, Completer<List<YouTubeVideoModel>>> pending = {};

  @override
  Future<List<YouTubeVideoModel>> getChannelVideos({
    required String channelId,
    Duration? timeout,
    int retries = 2,
  }) {
    final completer = Completer<List<YouTubeVideoModel>>();
    pending[channelId] = completer;
    return completer.future;
  }
}

List<YouTubeVideoModel> _videos(String prefix) =>
    [YouTubeVideoModel(videoId: '${prefix}_1', title: '$prefix 영상')];

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

  group('loadVideos 멤버 전환', () {
    // honeyz 첫 멤버(허니츄러스)와 다른 멤버(담유이)의 채널 ID
    final firstChannel = GlobalController.honeyzMembers.first.youtubeChannelId;
    final damyui = GlobalController.honeyzMembers
        .firstWhere((m) => m.key == 'damyui');

    late _FakeYouTubeService service;
    late YouTubeController c;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = _FakeYouTubeService();
      final global = GlobalController();
      global.selectedGroup.value = 'honeyz';
      c = YouTubeController(globalController: global, service: service);
    });

    Future<void> loadFirstMember() async {
      final load = c.loadVideos();
      await pumpEventQueue(); // 캐시 복원 대기(await) 뒤에 요청이 나간다
      service.pending[firstChannel]!.complete(_videos('first'));
      await load;
      expect(c.videoList.single.videoId, 'first_1');
    }

    test('캐시 없는 멤버로 바꾸면 이전 멤버 목록을 비우고 로딩을 표시', () async {
      await loadFirstMember();

      final load = c.selectMember(damyui.key);
      await pumpEventQueue();
      expect(c.videoList, isEmpty);
      expect(c.isLoading.value, isTrue);

      service.pending[damyui.youtubeChannelId]!.complete(_videos('damyui'));
      await load;
      expect(c.videoList.single.videoId, 'damyui_1');
      expect(c.isLoading.value, isFalse);
    });

    test('새 멤버 조회가 실패하면 이전 목록 없이 에러 상태', () async {
      await loadFirstMember();

      final load = c.selectMember(damyui.key);
      await pumpEventQueue();
      service.pending[damyui.youtubeChannelId]!
          .completeError(YouTubeServiceException('실패'));
      await load;

      expect(c.videoList, isEmpty);
      expect(c.hasError.value, isTrue);
      expect(c.errorMessage.value, '실패');
    });

    test('늦게 도착한 이전 멤버 응답은 새 멤버의 목록·로딩을 건드리지 않음', () async {
      final firstLoad = c.loadVideos();
      await pumpEventQueue();
      final secondLoad = c.selectMember(damyui.key);
      await pumpEventQueue();

      service.pending[firstChannel]!.complete(_videos('first'));
      await firstLoad;
      expect(c.videoList, isEmpty);
      expect(c.isLoading.value, isTrue);

      service.pending[damyui.youtubeChannelId]!.complete(_videos('damyui'));
      await secondLoad;
      expect(c.videoList.single.videoId, 'damyui_1');
      expect(c.isLoading.value, isFalse);
    });
  });
}
