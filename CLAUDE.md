# CLAUDE.md

Project I(프로젝트아이) 비공식 팬앱 — Flutter + GetX + Firebase.
자세한 소개·기술스택은 `README.md` 참고.

## 프로젝트 특화 Skills

작업 유형이 아래에 해당하면 **먼저 해당 skill을 호출**한다 (`.claude/skills/`).

| Skill | 언제 사용 |
|---|---|
| `chzzk-live-polling` | 치지직 폴링 API 구조·주기·에러 처리·라이프사이클. 라이브 상태/시청자 수/통합 LIVE, chzzk 응답 형식 변경 디버깅 |
| `add-member` | 멤버·그룹 추가/수정/삭제. 카탈로그·Cloud Function·firestore.rules·데이터에 흩어진 동기화 지점 처리 |
| `firestore-data` | Firestore 컬렉션 스키마·읽기전용 규칙·데이터 갱신·스케줄 푸시 알림 흐름 |
| `flutter-check` | Dart 코드 수정 후 / 커밋·PR 전. CI와 동일한 `flutter analyze` + `flutter test` |
| `release-and-symbolize` | 릴리스 빌드(appbundle/apk)·Play Store 업로드·Crashlytics 크래시 스택 복원(symbolize) |
| `karpathy-guidelines` | 코드 작성·리뷰·리팩터링 시 일반 원칙 (과설계 방지, 최소 변경) |

## 커밋 규칙

- 커밋 메시지는 **`YY.MM.DD - 내용`** 형식으로 작성한다 (예: `26.07.16 - 라이브 폴링 타임아웃 조정`).
- 날짜는 커밋 시점의 실제 날짜를 쓴다.
- **Claude co-author/기여자 트레일러를 넣지 않는다** (`Co-Authored-By: Claude ...`, `Generated with Claude Code` 등 모두 제거).

## 핵심 규칙 (skill에 상세)

- 릴리스 빌드는 **반드시 `scripts/build_release.sh`**로만. 심볼(`release-symbols/<version>/`) 백업 필수 → `release-and-symbolize`.
- 멤버 정보는 여러 파일에 흩어져 있음. 한 곳만 고치면 조용히 깨짐 → `add-member`.
- Firestore는 **클라이언트 읽기 전용**. 새 컬렉션은 `firestore.rules`에 명시 허용 → `firestore-data`.
- 치지직은 **비공식 API** — 응답 형식 변경 대비 에러 처리 정책 준수 → `chzzk-live-polling`.
- 커밋·PR 전 `flutter analyze` + `flutter test` (CI: Flutter 3.35.3) → `flutter-check`.
- 음악 기능은 저작권 이슈로 제거됨. 다시 연결하지 않는다.
