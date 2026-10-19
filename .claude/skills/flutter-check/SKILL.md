---
name: flutter-check
description: 코드 변경 후 정적분석·테스트를 돌려 회귀를 막는다(CI 없음 — 이게 유일한 검증 관문). Dart/Flutter 코드나 functions를 수정한 뒤, 커밋 전, "분석 돌려줘", "테스트 실행" 요청 시 사용.
---

# 정적분석 & 테스트 (커밋 전 로컬 검증)

이 프로젝트는 **CI를 쓰지 않는다** (1인 개발·master 직접 푸시라 26.10.19 GitHub
Actions 제거). 커밋·푸시 전에 아래를 로컬에서 돌리는 것이 유일한 회귀 방지책이다.

## 실행

```bash
flutter pub get       # 의존성 변경/최초 1회
flutter analyze       # 정적 분석 (lint 포함) — 0건 유지
flutter test          # 단위 테스트
TZ=UTC flutter test   # 시간대 의존 버그 확인 (날짜·openDate 관련 변경 시)
```

functions(`functions/`)를 고쳤다면 Node 쪽도 따로 돌린다 (Flutter 검사가 못 잡는다):

```bash
(cd functions && npm run lint && npm test)
```

- 기준 버전: **Flutter 3.44.8 stable** (릴리스 빌드 환경). 버전이 다르면 분석
  결과가 어긋날 수 있으니 `flutter --version`으로 확인.
- lint 설정은 `analysis_options.yaml` — `prefer_const_*` 룰이 켜져 있어
  const 누락도 경고로 잡힌다. analyze 경고는 0으로 유지한다.

## 테스트 작성 규칙 (이 프로젝트 관례)

테스트는 **Firebase/네트워크/GetX 레지스트리 없이 도는 순수 로직만** 검증한다
(`test/` 기존 파일 참고).

- `GlobalController`는 `_fireStore`가 `late final`이라 **Firestore 호출 전까지
  초기화되지 않는다** → 그냥 `GlobalController()`로 생성해 RxList에 값을 주입하고
  getter(필터/정렬/페어링)만 검증한다.
- `YouTubeController`는 `GlobalController`·`YouTubeService`를 생성자로 주입해
  테스트한다. `loadVideos` 경로는 `implements YouTubeService`인 가짜 서비스
  (`test/youtube_controller_test.dart`의 Completer 기반)로 검증한다 — 캐시 복원
  await 때문에 요청은 `pumpEventQueue()` 뒤에 나간다.
- 모델(`LiveCheckModel` 등)의 파생 getter는 결정적이므로 직접 검증한다.
  `DateTime.now()`를 쓰는 getter는 `@visibleForTesting ...From(now)` seam으로 검증한다.
- `NotificationController`는 토픽 구독/해제 함수를 생성자로 주입해 재조정
  (`syncLiveSubscriptions`) 경로를 FCM 없이 검증한다 (`test/notification_controller_test.dart`).
- **시간대 독립**: 치지직 openDate(KST)와 비교하는 시각은 `DateTime.utc`로 준다.
  개발 기기가 KST라 KST에서만 통과하는 테스트가 생기기 쉽다 —
  `TZ=UTC flutter test`로도 돌려 본다.

## 주의: Firebase 설정 파일

`lib/default_firebase_options.dart`는 실제 키를 담고 있어 gitignore된다.
커밋하지 않는다 (analyze/test는 로컬의 이 파일로 돈다).
