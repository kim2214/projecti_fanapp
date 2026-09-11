import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/model/member.dart';

void main() {
  const member = Member(
    key: 'ohwayo',
    name: '오화요',
    group: 'honeyz',
    chzzkBroadcastId: 'abc123',
    youtubeChannelId: 'UCx',
  );

  test('liveUrl은 치지직 라이브 시청 페이지', () {
    expect(member.liveUrl, 'https://chzzk.naver.com/live/abc123');
  });

  test('replayUrl은 치지직 채널 다시보기 목록 페이지', () {
    expect(member.replayUrl, 'https://chzzk.naver.com/abc123/videos');
    expect(Member.replayUrlOf('abc123'), member.replayUrl);
  });
}
