import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:http/http.dart' as http;
import 'package:projecti_fan_app/model/live_check_model.dart';

/// 계약 변경 의심 오류를 기록하는 함수 (기본: Crashlytics non-fatal).
typedef ChzzkErrorReporter = void Function(
    Object error, StackTrace? stack, String reason);

/// 치지직 비공식 polling 엔드포인트로 멤버 라이브 상태를 조회한다.
///
/// GetX·Firestore에 의존하지 않는다 — HTTP 클라이언트와 오류 기록을 주입받아,
/// 테스트(MockClient)나 Crashlytics가 보장되지 않는 백그라운드 isolate(홈 위젯
/// 직접 폴링)에서도 같은 파싱·에러 정책으로 쓸 수 있다.
class ChzzkService {
  ChzzkService({
    http.Client? client,
    ChzzkErrorReporter? reportError,
    this.timeout = defaultTimeout,
  })  : _client = client ?? http.Client(),
        _reportError = reportError ?? _reportToCrashlytics;

  /// 앱(포그라운드)용 공유 인스턴스. 클라이언트를 재사용해 2분마다 10개씩
  /// 나가는 요청이 매번 새 연결을 맺지 않게 한다.
  static final ChzzkService instance = ChzzkService();

  /// 요청 타임아웃. 멈춘 요청이 다음 폴링(2분)과 겹쳐 쌓이지 않도록 폴링
  /// 주기보다 충분히 짧게 둔다.
  static const Duration defaultTimeout = Duration(seconds: 8);

  final http.Client _client;
  final ChzzkErrorReporter _reportError;
  final Duration timeout;

  /// 일회성 인스턴스(백그라운드 갱신 등)의 연결을 닫는다. 공유 인스턴스는
  /// 앱 수명 동안 재사용하므로 닫지 않는다.
  void close() => _client.close();

  /// content가 null로 온 채널 (인스턴스당 채널별 한 번만 기록).
  final Set<String> _nullContentReported = {};

  static void _reportToCrashlytics(
      Object error, StackTrace? stack, String reason) {
    unawaited(FirebaseCrashlytics.instance
        .recordError(error, stack, reason: reason, fatal: false));
  }

  static Uri liveStatusUri(String broadcastId) => Uri.parse(
      'https://api.chzzk.naver.com/polling/v2/channels/$broadcastId/live-status');

  /// 단일 채널의 라이브 상태. null은 **조회 실패**만 뜻한다 — 정상 응답의
  /// 비방송(content null 포함)은 CLOSE 모델로 돌려준다.
  ///
  /// 에러 정책: 일시적 연결 오류(타임아웃·소켓·클라이언트 예외)는 노이즈라
  /// 기록하지 않고, HTTP 비정상 응답·파싱 실패는 엔드포인트 계약 변경 신호라
  /// 기록한다. 200인데 content가 null이면(채널 정지·삭제 가능성) 별도 사유로
  /// 채널당 한 번만 기록한다 — 파싱 실패와 섞여 쌓이면 진짜 신호가 묻힌다.
  Future<LiveCheckModel?> fetchLiveStatus(String broadcastId) async {
    try {
      final response =
          await _client.get(liveStatusUri(broadcastId)).timeout(timeout);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes));
        final content = data['content'];
        if (content == null) {
          if (_nullContentReported.add(broadcastId)) {
            _reportError('chzzk live-status content null: $broadcastId', null,
                'chzzk 라이브 상태 content 없음 (채널 정지·삭제 가능성)');
          }
          return LiveCheckModel(status: 'CLOSE', liveTitle: null);
        }
        return LiveCheckModel.fromJson(content as Map<String, dynamic>);
      }
      developer.log(
        'chzzk 라이브 상태 조회 실패 (HTTP ${response.statusCode}): $broadcastId',
        name: 'ChzzkService',
      );
      _reportError('chzzk live-status HTTP ${response.statusCode}', null,
          'chzzk 라이브 상태 엔드포인트 비정상 응답');
    } catch (e, st) {
      developer.log(
        'chzzk 라이브 상태 조회 예외: $broadcastId',
        name: 'ChzzkService',
        error: e,
        stackTrace: st,
      );
      final isTransient = e is TimeoutException ||
          e is SocketException ||
          e is http.ClientException;
      if (!isTransient) {
        _reportError(e, st, 'chzzk 라이브 상태 응답 파싱 실패 (형식 변경 가능성)');
      }
    }
    return null;
  }
}
