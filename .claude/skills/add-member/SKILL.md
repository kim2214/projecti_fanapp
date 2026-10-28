---
name: add-member
description: 멤버 또는 그룹을 추가/수정/삭제할 때 흩어진 동기화 지점을 빠짐없이 갱신한다. "멤버 추가", "새 멤버", "멤버 이름/채널 변경", "그룹 추가", "치지직/유튜브 채널 ID 수정" 요청 시 사용.
---

# 멤버 / 그룹 동기화

멤버 한 명의 정보가 **여러 파일에 흩어져** 있어, 한 곳만 고치면 조용히 깨진다.
(예: dart 카탈로그에만 추가하면 푸시 알림에서 멤버 이름이 안 나온다.)

## 멤버 추가/수정 시 반드시 함께 고칠 곳

1. **`lib/controllers/global_controller.dart`** — `honeyzMembers` / `acaxiaMembers`
   정적 카탈로그. `Member(key, name, group, chzzkBroadcastId, youtubeChannelId)`
   (`group`은 `Group` enum — functions 쪽 `group` 문자열은 `Group.id`와 일치).
   - `key`: Firestore 문서 키이자 shared_preferences 최애 저장 키 (변경 시 기존 최애 데이터 무효화 주의)
   - `chzzkBroadcastId`: 치지직 채널 ID (라이브 폴링용)
   - `youtubeChannelId`: `UC...` 형식 (RSS 피드용)
2. **`functions/index.js`** — `MEMBER_CATALOG` 배열 (`key`/`name`/`group`/
   `broadcastId`). 스케줄 푸시(`MEMBER_NAMES`는 여기서 파생)와 서버 라이브
   폴링([[chzzk-live-polling]])이 함께 쓴다. dart 카탈로그의 key/name/group/
   `chzzkBroadcastId`와 **정확히 일치**해야 한다. 수정 후 재배포 필요:
   `firebase deploy --only functions`.
3. **Firestore 데이터** — 멤버 프로필 문서(`honeyz/{key}` 또는 `acaxia/{key}`)와
   스케줄 문서(`schedule/{key}` 또는 `schedule_acaxia/{key}`). 콘솔/Admin SDK로
   추가. 자세한 스키마는 [[firestore-data]] 참고.
4. **에셋** — 프로필 이미지가 필요하면 `assets/honeyz/` 등에 추가하고
   `pubspec.yaml`의 assets 목록 확인.

## 그룹 자체를 추가할 때 (위 항목 + 아래)

- **`firestore.rules`** — 새 그룹의 프로필/스케줄 컬렉션 경로에 `allow read: if
  true; allow write: if false;` 규칙 추가. 규칙 없는 경로는 기본 차단된다.
  수정 후 배포: `firebase deploy --only firestore:rules`.
- **`functions/index.js`** — `GROUP_LABELS` 맵과 스케줄 쓰기 트리거 대상 추가.
- **`lib/model/group.dart`** — `Group` enum에 값 추가(`id`·`label`·`labelEn`·
  `scheduleCollection`). `id`는 기기 저장값·Firestore 컬렉션·FCM 토픽·에셋 폴더에
  쓰이므로 정한 뒤 바꾸지 않는다. 추가하면 `switch`로 분기하는 곳이 컴파일
  오류로 드러난다 — `GlobalController`의 `membersOf`·`streamersOf`·`liveStatusOf`·
  `_scheduleCacheOf`(캐시 RxMap도 그룹별로 추가), `AppColors.group`/`groupDark`·
  `context.groupInk`, `schedule_detail`의 글자색.
- 컴파일러가 못 잡는 곳: 그룹 선택 화면 카드·상단바 그룹 토글·알림 설정 시트의
  그룹별 스위치(`screen_base_widget.dart`, `group_select_widget.dart`)는 그룹을
  하나씩 나열한다 — 새 그룹 항목을 직접 추가.
- 로고 에셋 `assets/<id>_logo.png`, 멤버 에셋 폴더 `assets/<id>/`.

## 검증

수정 후 반드시 [[flutter-check]]로 정적분석/테스트를 돌린다. 멤버 수가 바뀌면
`test/global_controller_test.dart`, `test/youtube_controller_test.dart`의 멤버
수·첫 멤버 key 기대값도 함께 갱신해야 한다.
