// 공용 안내 위젯 — 보조 문구·"다시 시도" 버튼은 넘겼을 때만 그린다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/widget/components/status_message.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('제목만 주면 보조 문구·버튼 없이 그린다', (tester) async {
    await tester.pumpWidget(wrap(const StatusMessage(
      icon: Icons.nightlight_round,
      iconColor: Colors.grey,
      title: '지금은 방송 중인 멤버가 없어요',
    )));

    expect(find.text('지금은 방송 중인 멤버가 없어요'), findsOneWidget);
    expect(find.text('다시 시도'), findsNothing);
  });

  testWidgets('onRetry를 주면 "다시 시도"가 보이고 누르면 호출된다', (tester) async {
    var retried = 0;
    await tester.pumpWidget(wrap(StatusMessage(
      icon: Icons.wifi_off_rounded,
      iconColor: Colors.grey,
      title: '스케줄을 불러오지 못했어요',
      subtitle: '네트워크 연결을 확인한 뒤 다시 시도해 주세요',
      onRetry: () => retried++,
    )));

    expect(find.text('네트워크 연결을 확인한 뒤 다시 시도해 주세요'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    expect(retried, 1);
  });
}
