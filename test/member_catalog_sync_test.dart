// 멤버 카탈로그 동기화 가드.
//
// 멤버 메타데이터(key/name/group/broadcastId)는 두 곳에 손으로 복제돼 있다:
//   - Dart: GlobalController.honeyzMembers / acaxiaMembers (앱)
//   - JS  : functions/index.js 의 MEMBER_CATALOG (Cloud Function 푸시)
// 한쪽만 고치면 푸시가 조용히 엉뚱한 멤버로 가거나 누락된다(add-member skill 참고).
// 이 테스트는 functions/index.js를 파싱해 Dart 카탈로그와 대조하고, 드리프트가
// 있으면 CI를 실패시켜 "조용한 깨짐"을 컴파일 타임 수준으로 끌어올린다.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:projecti_fan_app/controllers/global_controller.dart';
import 'package:projecti_fan_app/model/member.dart';

/// functions/index.js의 MEMBER_CATALOG에서 파싱한 한 항목.
class _JsMember {
  const _JsMember({
    required this.key,
    required this.name,
    required this.group,
    required this.broadcastId,
  });

  final String key;
  final String name;
  final String group;
  final String broadcastId;
}

/// functions/index.js에서 `const MEMBER_CATALOG = [ ... ];` 블록을 뽑아
/// 각 `{ key, name, group, broadcastId }` 항목을 파싱한다.
List<_JsMember> _parseJsCatalog(String source) {
  final blockMatch =
      RegExp(r'const\s+MEMBER_CATALOG\s*=\s*\[(.*?)\];', dotAll: true)
          .firstMatch(source);
  if (blockMatch == null) {
    fail('functions/index.js에서 MEMBER_CATALOG 배열을 찾지 못했습니다. '
        '변수명/형식이 바뀌었다면 이 파서를 함께 갱신하세요.');
  }

  final block = blockMatch.group(1)!;
  final objectPattern = RegExp(r'\{(.*?)\}', dotAll: true);
  final fieldPattern = RegExp(r'(\w+)\s*:\s*"([^"]*)"');

  final members = <_JsMember>[];
  for (final obj in objectPattern.allMatches(block)) {
    final fields = <String, String>{};
    for (final f in fieldPattern.allMatches(obj.group(1)!)) {
      fields[f.group(1)!] = f.group(2)!;
    }
    // key가 없는 항목은 카탈로그 객체가 아니므로 건너뛴다.
    if (!fields.containsKey('key')) continue;
    members.add(_JsMember(
      key: fields['key']!,
      name: fields['name'] ?? '',
      group: fields['group'] ?? '',
      broadcastId: fields['broadcastId'] ?? '',
    ));
  }
  return members;
}

void main() {
  group('멤버 카탈로그 동기화 (Dart ↔ functions/index.js)', () {
    final dartMembers = <Member>[
      ...GlobalController.honeyzMembers,
      ...GlobalController.acaxiaMembers,
    ];

    late final List<_JsMember> jsMembers;

    setUpAll(() {
      final file = File('functions/index.js');
      expect(file.existsSync(), isTrue,
          reason: 'functions/index.js 를 찾을 수 없습니다 (테스트는 패키지 루트에서 실행).');
      jsMembers = _parseJsCatalog(file.readAsStringSync());
    });

    test('파서가 최소 1개 이상을 뽑는다 (파서 고장 = 거짓 통과 방지)', () {
      expect(jsMembers, isNotEmpty,
          reason: 'MEMBER_CATALOG 파싱 결과가 비어 있습니다. index.js 형식 변경 가능성.');
    });

    test('양쪽 카탈로그의 멤버 key 집합이 정확히 일치한다', () {
      final dartKeys = dartMembers.map((m) => m.key).toSet();
      final jsKeys = jsMembers.map((m) => m.key).toSet();

      expect(jsKeys.difference(dartKeys), isEmpty,
          reason:
              'functions/index.js에만 있는 멤버 key: ${jsKeys.difference(dartKeys)}');
      expect(dartKeys.difference(jsKeys), isEmpty,
          reason: 'Dart 카탈로그에만 있는 멤버 key: ${dartKeys.difference(jsKeys)}');
    });

    test('멤버 수가 동일하다 (중복 key 없음)', () {
      expect(jsMembers.length, dartMembers.length,
          reason: 'Dart ${dartMembers.length}명 vs JS ${jsMembers.length}명 — '
              '중복 key이거나 한쪽에 항목이 빠졌습니다.');
    });

    test('key별로 name·group·broadcastId가 완전히 일치한다', () {
      final jsByKey = {for (final m in jsMembers) m.key: m};

      for (final dart in dartMembers) {
        final js = jsByKey[dart.key];
        // key 집합 검증은 위 테스트가 담당하므로, 여기선 매칭되는 것만 필드 비교.
        if (js == null) continue;

        expect(js.name, dart.name,
            reason:
                '[${dart.key}] name 불일치: Dart "${dart.name}" vs JS "${js.name}"');
        expect(js.group, dart.group,
            reason:
                '[${dart.key}] group 불일치: Dart "${dart.group}" vs JS "${js.group}"');
        expect(js.broadcastId, dart.chzzkBroadcastId,
            reason: '[${dart.key}] broadcastId 불일치: '
                'Dart "${dart.chzzkBroadcastId}" vs JS "${js.broadcastId}"');
      }
    });
  });
}
