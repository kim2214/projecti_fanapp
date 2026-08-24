---
name: firestore-data
description: Firestore 컬렉션 구조·읽기전용 보안 규칙·데이터 갱신 방법과 스케줄 푸시 알림 흐름을 다룬다. "Firestore 스키마", "데이터 업데이트", "보안 규칙", "스케줄 이미지 변경", "푸시 알림", "Cloud Function" 관련 작업 시 사용.
---

# Firestore 데이터 & 보안 규칙

## 원칙: 클라이언트는 읽기 전용

팬앱은 Firestore를 **읽기 전용**으로만 쓴다. 쓰기는 Firebase 콘솔 또는
Admin SDK(Cloud Functions)로만 하며, `firestore.rules`는 클라이언트 쓰기를
전면 차단(`allow write: if false`)한다. Admin SDK는 규칙을 우회한다.

## 컬렉션 구조

| 컬렉션 | 문서 키 | 용도 |
|---|---|---|
| `honeyz/{key}` | 멤버 key | 허니즈 멤버 프로필 (생일, SNS 등) |
| `acaxia/{key}` | 멤버 key | 아카시아 멤버 프로필 |
| `schedule/{key}` | 멤버 key | 허니즈 주간 스케줄 (`schedule_image` 필드) |
| `schedule_acaxia/{key}` | 멤버 key | 아카시아 주간 스케줄 |
| `live_status/current` | 고정 문서 | 서버 폴링 라이브 집계 ([[chzzk-live-polling]]) |
| `live_history/{key}/sessions/{id}` | openDate 숫자 | 지난 방송 세션 (제목·카테고리·openDate·peak 시청자·endedAt). 서버가 방송 종료 시 기록, 클라 멤버 프로필 "지난 방송"이 endedAt 내림차순으로 읽음 (`LiveSessionModel`) |

- `{key}`는 dart 카탈로그(`global_controller.dart`)의 `Member.key`와 동일
  (예: `honeychurros`, `popopopo`). 멤버 추가는 [[add-member]] 참고.
- 프로필 필드는 `StreamerModel`, 스케줄은 `ScheduleModel`(`lib/model/`)에 매핑된다.
- 그 외 모든 경로는 기본 차단. **새 컬렉션은 `firestore.rules`에 명시적으로
  허용**해야 앱에서 읽을 수 있다.

## 규칙 변경 후 배포

```bash
firebase deploy --only firestore:rules
```

## 스케줄 푸시 알림 흐름

`functions/index.js`의 `onDocumentWritten` 트리거가 스케줄 문서 쓰기를 감지한다.

- `schedule_image` 필드가 **새로 들어오거나 바뀐 경우에만** 해당 그룹 토픽으로
  푸시를 보낸다 (다른 필드 변경/삭제는 무시).
- 알림 문구는 `MEMBER_NAMES`(key→이름), `GROUP_LABELS`(그룹→라벨) 맵을 쓴다 —
  dart 카탈로그와 동기화 필수.
- 함수 수정 후 배포:

```bash
firebase deploy --only functions
```

## 데이터 갱신

스케줄 이미지 교체 등 데이터 변경은 Firebase 콘솔에서 해당 문서의 필드를
수정한다. `schedule_image`를 바꾸면 위 트리거로 푸시가 자동 발송되므로,
푸시를 원치 않는 소규모 수정 시 유의한다.
