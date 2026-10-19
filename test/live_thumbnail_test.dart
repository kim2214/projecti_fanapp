// LiveThumbnail: 로드 실패 시 16:9 칸째 접히는지 검증.
// flutter_test의 HTTP는 모든 요청에 400을 돌려주므로 네트워크 없이 실패 경로를 탄다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/widget/components/live_thumbnail.dart';

void main() {
  testWidgets('URL이 없으면 아무 자리도 차지하지 않는다', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LiveThumbnail(url: null))));
    expect(find.byType(AspectRatio), findsNothing);
  });

  testWidgets('로드에 실패하면 16:9 칸과 여백을 접는다', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          LiveThumbnail(url: 'https://example.invalid/thumb.jpg'),
        ]),
      ),
    ));
    expect(find.byType(AspectRatio), findsOneWidget);

    // 실제 이미지 요청(실패)이 끝나도록 비동기 처리를 돌린 뒤 프레임을 넘긴다.
    await tester.runAsync(() => Future<void>.delayed(
        const Duration(milliseconds: 100)));
    await tester.pump();
    await tester.pump();

    expect(find.byType(AspectRatio), findsNothing);
    expect(tester.getSize(find.byType(LiveThumbnail)).height, 0);
  });
}
