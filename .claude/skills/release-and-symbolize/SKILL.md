---
name: release-and-symbolize
description: 릴리스(AOT) 빌드를 만들고 Crashlytics용 Dart 심볼을 보존/복원한다. "릴리스 빌드", "appbundle/apk 빌드", "Play Store 업로드", "크래시 스택 복원", "symbolize", "난독화된 스택트레이스" 요청 시 사용.
---

# 릴리스 빌드 & Crashlytics 심볼 복원

릴리스(AOT) 빌드는 Dart 스택트레이스의 함수명을 제거하므로, Crashlytics에는
메모리 오프셋만 올라온다. `--split-debug-info`로 만든 심볼 파일이 있어야
`flutter symbolize`로 원래 스택을 복원할 수 있다. **Crashlytics는 Dart 심볼을
자동 해석하지 못한다.**

## 절대 규칙

- 릴리스 빌드는 **반드시 `scripts/build_release.sh`로만** 만든다. `flutter build
  appbundle`을 직접 실행하면 심볼이 남지 않아 그 버전의 크래시를 영영 복원할 수 없다.
- 빌드 후 `release-symbols/<version>/` 폴더를 **릴리스마다 클라우드/아티팩트에
  백업**한다. 이 폴더는 gitignore되어 커밋되지 않으며, 잃어버리면 복구 불가.
- `<version>`은 `pubspec.yaml`의 `version:` 값(예: `2.2.0+11`)과 동일하다.

## 빌드

```bash
scripts/build_release.sh            # appbundle (Play Store, 기본)
scripts/build_release.sh apk        # apk
```

버전을 올려야 하면 먼저 `pubspec.yaml`의 `version: X.Y.Z+build`를 수정한다
(`X.Y.Z`=versionName, `build`=versionCode). Play Store 재업로드 시 build 번호는
반드시 증가해야 한다.

## 크래시 스택 복원

1. Crashlytics 콘솔의 스택트레이스를 텍스트 파일(예: `stack.txt`)로 저장한다.
2. 해당 버전의 심볼 폴더(`release-symbols/<version>/`)가 있는지 확인한다.
3. 복원:

```bash
scripts/symbolize.sh <version> stack.txt          # 예: 2.2.0+11 (arm64 기본)
scripts/symbolize.sh <version> stack.txt arm      # 32비트 기기면 arch 지정 (arm / x64)
```

심볼 파일을 못 찾으면 그 버전의 `release-symbols/` 폴더가 백업에서 복원됐는지 확인한다.

## 체크리스트

- [ ] `pubspec.yaml` version(특히 `+build`) 증가 확인
- [ ] `scripts/build_release.sh`로 빌드 (직접 flutter build 금지)
- [ ] `release-symbols/<version>/` 백업 완료
