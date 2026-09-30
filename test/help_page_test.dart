// 도움말 화면 렌더링 — FAQ 펼침, 앱 버전 표시, 오픈소스 라이선스 진입.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:projecti_fan_app/widget/help_page.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Project I Fan App',
      packageName: 'com.devkim.honeyz_fan_app',
      version: '2.6.2',
      buildNumber: '19',
      buildSignature: '',
    );
  });

  testWidgets('FAQ 질문이 모두 보이고, 누르면 답이 펼쳐진다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HelpPage()));
    await tester.pumpAndSettle();

    for (final (q, _) in HelpPage.faqs) {
      expect(find.text(q), findsOneWidget);
    }
    final (question, answer) = HelpPage.faqs.first;
    expect(find.text(answer), findsNothing);
    await tester.tap(find.text(question));
    await tester.pumpAndSettle();
    expect(find.text(answer), findsOneWidget);
  });

  testWidgets('앱 버전과 비공식 고지를 표시한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HelpPage()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(HelpPage.disclaimer), 200);
    expect(find.text('Project I Fan App 2.6.2 (19)'), findsOneWidget);
  });

  testWidgets('오픈소스 라이선스를 누르면 라이선스 화면이 열린다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HelpPage()));
    await tester.pumpAndSettle();
    // ListView는 지연 생성 — 먼저 스크롤로 만들고, 화면 안으로 끌어온다.
    await tester.scrollUntilVisible(find.text('오픈소스 라이선스'), 200);
    await tester.ensureVisible(find.text('오픈소스 라이선스'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('오픈소스 라이선스'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });
}
