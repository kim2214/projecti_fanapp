# Project I Fan App

버츄얼 아이돌 그룹 **프로젝트아이(Project I)** 의 비공식 팬 어플리케이션입니다.

> 이 앱은 팬이 제작한 비공식 어플리케이션이며, 프로젝트아이 공식과는 무관합니다.

---

## 소개

Project I Fan App은 프로젝트아이 소속 그룹인 **허니즈(Honeyz)** 와 **아카시아(Acaxia)** 의 팬들을 위한 모바일 어플리케이션입니다.
멤버들의 실시간 라이브 방송 현황, 주간 스케줄, 최신 YouTube 영상, SNS 정보를 한 곳에서 확인할 수 있습니다.

앱 실행 시 그룹(허니즈/아카시아)을 선택하며, 앱 상단에서 언제든 그룹을 전환할 수 있습니다.

---

## 주요 기능

### 홈 대시보드

- 지금 방송 중인 멤버, 주간 스케줄 바로가기, 최신 영상을 한 화면에 요약해 보여줍니다.

### 통합 LIVE 현황

- 그룹 전환 없이 **허니즈·아카시아 양쪽**에서 방송 중인 멤버를 한 화면에 모아 봅니다.
- 시청자 수 기준으로 정렬되며, **최애 멤버는 맨 위로 우선 노출**됩니다.
- 방송 제목·카테고리·시청자 수·방송 경과 시간을 표시하고, 카드를 누르면 치지직 방송으로 이동합니다.
- 2분 주기 및 앱 복귀 시 라이브 상태가 자동 갱신됩니다.

### 홈스크린 위젯 (Android)

- 앱을 열지 않고 홈 화면에서 **지금 방송 중인 멤버**(시청자 수 순, 최대 4명 + 추가 인원 표시)를 확인합니다.
- 멤버 줄을 탭하면 치지직 방송으로, 헤더를 탭하면 앱으로 이동합니다. 방송 중인 멤버가 한 명이면 카드 어디를 눌러도 그 방송이 열립니다.
- 앱 실행·라이브 알림 수신 시 즉시 갱신되고, 그 외에는 30분 주기로 서버 집계를 다시 읽습니다 ("N분 전 갱신" 표시).

### 최애 멤버 (즐겨찾기)

- 멤버를 최애로 지정/해제할 수 있으며, 설정은 기기에 저장되어 앱을 재실행해도 유지됩니다.
- 멤버 탭의 별(⭐) 아이콘으로 지정하고, 통합 LIVE 화면에서 우선 노출·강조됩니다.

### 스케줄

- 각 멤버의 주간 방송 스케줄(이미지)을 그룹별로 확인할 수 있습니다.
- 이미지를 탭하면 확대/축소 보기를 지원합니다.

### 멤버 정보

- 각 멤버의 프로필과 실시간 라이브 방송 여부를 확인할 수 있습니다.
- SNS 바로가기(X/Twitter, YouTube)와 치지직(Chzzk) 라이브 채널 바로가기를 제공합니다.

### YouTube 최신 영상

- 멤버별 최신 YouTube 영상을 확인할 수 있습니다. (공식 RSS 피드 기반, API 키 불필요)

---

## 기술 스택

| 분류               | 기술                              |
|------------------|---------------------------------|
| Language         | Dart                            |
| Framework        | Flutter                         |
| State Management | GetX                            |
| Routing          | go_router                       |
| Backend          | Firebase (Cloud Firestore)      |
| Networking       | http, dio                       |
| Local Storage    | shared_preferences              |
| Image            | extended_image                  |

---

## 데이터 소스

| 데이터            | 소스                                                    |
|-----------------|-------------------------------------------------------|
| 멤버 정보·스케줄    | Firebase Cloud Firestore                              |
| 실시간 LIVE 상태   | 치지직(CHZZK) 폴링 API                                  |
| 최신 영상         | YouTube 공식 RSS 피드 (`feeds/videos.xml`, API 키 불필요) |
| 최애 멤버         | 기기 로컬 저장 (shared_preferences)                      |

---

## 아키텍처 개요

- **상태 관리**: GetX(`GetxController` + `Obx`)를 사용하며, 컨트롤러는 `bindings.dart`에서 `lazyPut`으로 주입됩니다.
- **화면 전환**: `go_router`로 스플래시 → 그룹 선택 → 메인(하단 탭)으로 흐릅니다. 통합 LIVE 화면은 홈에서 진입합니다.
- **라이브 상태**: `GlobalController`가 치지직 API를 주기적으로 폴링해 양쪽 그룹의 방송 상태를 갱신합니다.

---

## 설치 방법

### 요구 사항

- Flutter SDK 3.0.1 이상
- Dart SDK 3.0.1 이상
- Firebase 프로젝트 설정 (`lib/default_firebase_options.dart`)

### 빌드

```bash
# 의존성 설치
flutter pub get

# 앱 실행
flutter run

# 앱 빌드 (Android)
flutter build apk
```

---

## 릴리스 빌드 & Crashlytics 심볼

릴리스(AOT) 빌드에서는 Dart 스택트레이스의 함수명이 제거되어, Crashlytics에 올라온
크래시가 메모리 오프셋만 보인다. `--split-debug-info`로 만든 심볼 파일이 있어야
`flutter symbolize`로 원래 스택을 복원할 수 있다. (Crashlytics는 Dart 심볼을 자동
해석하지 못한다.)

```bash
# 릴리스 빌드 (심볼을 release-symbols/<version>/ 에 보존)
scripts/build_release.sh            # appbundle (Play Store)
scripts/build_release.sh apk        # apk

# Crashlytics 콘솔의 스택트레이스를 stack.txt로 저장한 뒤 복원
scripts/symbolize.sh <version> stack.txt          # 예: 2.2.0+11
scripts/symbolize.sh <version> stack.txt arm      # 32비트 기기면 arch 지정
```

> ⚠️ `release-symbols/<version>/` 폴더는 **릴리스마다 반드시 백업**한다(클라우드/아티팩트).
> git에 커밋되지 않으며, 잃어버리면 그 버전에서 올라온 크래시는 복원할 수 없다.

---

## 라이선스

이 프로젝트는 개인 프로젝트이며, 프로젝트아이의 공식 어플리케이션이 아닙니다.

---

## 제작자

**kimdev0821**

---

## 면책 조항

- 이 어플리케이션은 프로젝트아이(Project I)의 공식 어플리케이션이 아닙니다.
- 팬이 제작한 비공식 어플리케이션입니다.
- 앱에 사용된 이미지 등의 저작권은 각 권리자에게 있습니다.
