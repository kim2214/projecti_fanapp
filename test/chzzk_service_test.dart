// ChzzkService 파싱·에러 정책 단위 테스트. MockClient로 응답을 흉내 내고,
// 오류 기록은 Crashlytics 대신 리스트에 모아 "무엇을 기록하는가"를 검증한다.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:projecti_fan_app/services/chzzk_service.dart';

void main() {
  late List<String> reported;

  ChzzkService serviceWith(
    Future<http.Response> Function(http.Request) handler, {
    Duration timeout = ChzzkService.defaultTimeout,
  }) {
    return ChzzkService(
      client: MockClient(handler),
      reportError: (error, stack, reason) => reported.add(reason),
      timeout: timeout,
    );
  }

  http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  setUp(() => reported = []);

  group('ChzzkService.fetchLiveStatus', () {
    test('정상 응답이면 content를 파싱하고 아무것도 기록하지 않는다', () async {
      final service = serviceWith((request) async {
        expect(request.url, ChzzkService.liveStatusUri('abc'));
        return jsonResponse({
          'content': {
            'status': 'OPEN',
            'liveTitle': '한글 제목',
            'concurrentUserCount': 123,
          },
        });
      });

      final status = await service.fetchLiveStatus('abc');
      expect(status!.isLive, isTrue);
      expect(status.liveTitle, '한글 제목'); // bodyBytes를 UTF-8로 디코딩
      expect(status.concurrentUserCount, 123);
      expect(reported, isEmpty);
    });

    test('content가 null이면 CLOSE(실패 아님) + 채널당 한 번만 기록', () async {
      final service = serviceWith((_) async => jsonResponse({'content': null}));

      final first = await service.fetchLiveStatus('abc');
      final second = await service.fetchLiveStatus('abc');
      await service.fetchLiveStatus('other');

      expect(first, isNotNull);
      expect(first!.isLive, isFalse);
      expect(second!.isLive, isFalse);
      // 'abc' 1회 + 'other' 1회
      expect(reported.length, 2);
      expect(reported.first, contains('content 없음'));
    });

    test('HTTP 비정상 응답은 실패(null) + 계약 변경으로 기록', () async {
      final service = serviceWith((_) async => http.Response('', 500));

      expect(await service.fetchLiveStatus('abc'), isNull);
      expect(reported, [contains('비정상 응답')]);
    });

    test('형식이 바뀐 응답(파싱 실패)은 실패(null) + 기록', () async {
      final service = serviceWith((_) async => http.Response('<html>', 200));

      expect(await service.fetchLiveStatus('abc'), isNull);
      expect(reported, [contains('파싱 실패')]);
    });

    test('일시적 연결 오류는 실패(null)지만 기록하지 않는다 (노이즈)', () async {
      for (final error in <Object>[
        const SocketException('offline'),
        http.ClientException('reset'),
      ]) {
        final service = serviceWith((_) async => throw error);
        expect(await service.fetchLiveStatus('abc'), isNull);
      }
      expect(reported, isEmpty);
    });

    test('타임아웃은 실패(null)지만 기록하지 않는다', () async {
      final never = Completer<http.Response>();
      final service = serviceWith((_) => never.future,
          timeout: const Duration(milliseconds: 10));

      expect(await service.fetchLiveStatus('abc'), isNull);
      expect(reported, isEmpty);
    });
  });
}
