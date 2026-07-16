---
name: chzzk-live-polling
description: 치지직(CHZZK) 비공식 폴링 API로 멤버 라이브 상태를 가져오는 구조·주기·에러 처리·라이프사이클을 다룬다(클라 포그라운드 + 서버 폴링/라이브 푸시). "라이브 상태", "치지직 폴링", "방송 중 여부", "시청자 수", "통합 LIVE", "라이브 알림/푸시", "폴링 주기/타임아웃", "chzzk API 응답 변경" 관련 작업 시 사용.
---

# 치지직(CHZZK) 라이브 폴링

멤버별 실시간 방송 상태는 **치지직 비공식 polling 엔드포인트**를 호출해 얻는다.
폴링 경로가 **두 곳**이며 로직·에러 정책을 공유한다:

- **클라 포그라운드 폴링** — `lib/controllers/global_controller.dart`.
  화면에 보이는 라이브 현황 갱신용(2분 주기, 포그라운드만).
- **서버 폴링** — `functions/index.js`의 `pollLiveStatus`(1분 주기 스케줄러).
  백그라운드 라이브 감지 → 방송 시작 푸시. 아래 "서버 폴링" 절 참고.

## 엔드포인트

```
GET https://api.chzzk.naver.com/polling/v2/channels/{broadcastId}/live-status
```

- `{broadcastId}` = `Member.chzzkBroadcastId` (dart 카탈로그 정의, [[add-member]] 참고).
- 응답의 `content` 객체를 `LiveCheckModel.fromJson`으로 파싱한다
  (`liveTitle`, `status`, `concurrentUserCount`, `liveCategoryValue`, `openDate`).
- `status == 'OPEN'`이면 방송 중(`LiveCheckModel.isLive`).
- **주의: 비공식·인증 불필요 엔드포인트다.** 응답 형식이 예고 없이 바뀌면
  무증상 실패할 수 있어, 아래처럼 방어적으로 처리한다.

라이브 시청 URL은 별도 규칙: `https://chzzk.naver.com/live/{broadcastId}`
(카드 탭 시 `url_launcher`로 이동. `live_page.dart` 등 여러 곳에 중복되어 있으니
URL 형식 변경 시 함께 수정).

## 폴링 주기·타임아웃 (`GlobalController` 상수)

- `_liveRefreshInterval = 2분` — 포그라운드에서 `Timer.periodic`으로 갱신.
- `_requestTimeout = 8초` — 멈춘 요청이 다음 폴링과 겹쳐 쌓이는 것을 방지.
  이 두 값은 서로 맞물려 있으니(타임아웃 < 주기) 함께 조정한다.

## 라이프사이클 (배터리·네트워크 절약)

`AppLifecycleListener`로 제어한다. **백그라운드에서 폴링을 돌리지 않는 것이 의도**다.

- `onResume`: 즉시 1회 갱신 + 주기 폴링 재개 (`refreshAllLiveStatus` → `_startLiveRefreshTimer`).
- `onPause`: 주기 폴링 중단 (`_stopLiveRefreshTimer`).
- `onClose`: 타이머·리스너 정리.

## 조회 함수 계층

- `_fetchLiveStatus(broadcastId)` — 단일 멤버 조회. 실패 시 `null` 반환.
- `_refreshGroupLiveStatus(group)` — 그룹 전체를 `Future.wait`로 병렬 조회 후 캐시 교체.
- `refreshLiveStatus()` — 현재 선택 그룹만.
- `refreshAllLiveStatus()` — 허니즈+아카시아 동시 (통합 LIVE 화면용).
- `liveCheck({forceRefresh})` — 캐시 우선, 비었거나 강제 시 갱신.

### 인덱스 정렬 불변식 (깨뜨리지 말 것)

라이브 상태 리스트는 **`membersOf(group)` 카탈로그와 순서·길이가 1:1**로 맞아야
한다. UI가 인덱스로 멤버↔상태를 매칭하기 때문이다.

- `_fetchLiveStatus`가 `null`을 반환해도 `_refreshGroupLiveStatus`가
  `LiveCheckModel(status: 'CLOSE')` 기본값으로 채워 **인덱스가 밀리지 않게** 한다.
- `liveMembersAcrossGroups`는 폴링 전 리스트가 비어 있을 수 있어
  `min(members, statuses)` 길이까지만 안전하게 순회한다.

## 에러 처리 정책 (노이즈 vs 계약 변경 구분)

`_fetchLiveStatus`는 두 종류를 다르게 다룬다:

- **일시적 오류**(`TimeoutException`/`SocketException`/`http.ClientException`) →
  로그만, Crashlytics 기록 **안 함** (노이즈).
- **HTTP 비정상 응답 / 파싱 예외** → `FirebaseCrashlytics.recordError(fatal:
  false)`로 기록. 이건 **엔드포인트 계약이 바뀐 신호**이므로 반드시 남긴다.

chzzk API가 바뀌어 라이브가 안 뜬다는 리포트가 오면 이 Crashlytics 로그
(`reason: 'chzzk ... 형식 변경 가능성'`)부터 확인한다.

## 통합 LIVE 정렬

`liveMembersAcrossGroups`: 양쪽 그룹에서 `isLive`인 멤버만 모아 **시청자 수
내림차순**(null=0, 뒤로) 정렬. 최애 우선 노출은 화면단(live_page)에서 처리.

## 서버 폴링 & 라이브 방송 시작 푸시

`functions/index.js`의 `pollLiveStatus`(Cloud Scheduler, 1분, `asia-northeast3`,
`maxInstances: 1`)가 백그라운드 라이브 감지를 담당한다. 멤버 정보는
`MEMBER_CATALOG`에 있으며 dart 카탈로그와 동기화 필수([[add-member]]).

- **상태 저장**: 집계 문서 `live_status/current`(멤버별 `status`/`liveTitle`/
  `concurrentUserCount`/`openDate`/`lastNotifiedOpenDate`)에 **주기당 읽기1·쓰기1**.
- **전이 감지**: 직전 `CLOSE`(또는 미기록) → `OPEN`일 때만 알림. **`openDate`를
  방송 식별자**로 써서 상태가 흔들려도(플랩) 같은 방송엔 1회만 발송.
- **실패 시 직전 상태 유지** → 거짓 CLOSE→OPEN 알림 방지 (에러 정책은 클라와 동일).
- **발송**: 멤버별 토픽 `live_<memberKey>`, 채널 `live_channel`,
  `data: {type:'live', broadcastId, memberKey}`.

### 클라이언트 수신 (`notification_controller.dart`)

- `live_channel` 채널 생성(스케줄과 분리).
- 구독은 **최애 목록을 따라간다** — `FavoritesController`가 로드/토글 시
  `syncLiveSubscriptions(keys)`를 호출, 영속 집합과 diff해 `live_<key>` 추가/해제.
- 알림 탭 → `chzzk.naver.com/live/{broadcastId}` 이동 (포그라운드 로컬 알림은
  payload, 백그라운드/종료는 `onMessageOpenedApp`/`getInitialMessage`).

### 밴/차단 완화

단일 egress IP 집중이 주 리스크. 주기 60초 이상 유지, 브라우저 UA 지정,
429/403 시 백오프, 지속 실패 시 로그 알림. 서버가 막혀도 **클라 포그라운드
폴링이 폴백**으로 남는다.

## 검증

폴링/파싱 로직 수정 후 [[flutter-check]]로 테스트. 순수 파생 로직(정렬·필터·
인덱스 페어링)은 `test/global_controller_test.dart`가 Firebase/네트워크 없이
RxList에 값을 주입해 검증하므로, 여기 기대값도 함께 맞춘다.
