#!/usr/bin/env bash
#
# 릴리스 빌드 + Dart 심볼 보존.
#
# 릴리스(AOT) 빌드에서는 Dart 스택트레이스의 함수명이 제거되어, Crashlytics에
# 올라온 크래시가 메모리 오프셋만 보인다. --split-debug-info 로 생성한 심볼 파일이
# 있어야 `flutter symbolize` 로 원래 스택을 복원할 수 있다.
#
# 따라서 이 스크립트로 빌드하고, 출력된 심볼 폴더를 "릴리스마다 반드시 보관"한다.
# (보관하지 않으면 그 버전에서 올라온 크래시는 영영 복원할 수 없다.)
#
# 사용법:
#   scripts/build_release.sh            # appbundle (Play Store용, 기본)
#   scripts/build_release.sh apk        # apk
#
set -euo pipefail

cd "$(dirname "$0")/.."

TARGET="${1:-appbundle}"

# pubspec의 version(예: 2.2.0+11)을 폴더명으로 사용해 릴리스별로 심볼을 구분 보관.
# build/ 밖에 두어 `flutter clean`에도 심볼이 지워지지 않게 한다.
VERSION="$(grep '^version:' pubspec.yaml | awk '{print $2}')"
SYMBOLS_DIR="release-symbols/${VERSION}"
mkdir -p "$SYMBOLS_DIR"

echo "▶ 릴리스 빌드: target=${TARGET}, version=${VERSION}"
echo "▶ 심볼 출력: ${SYMBOLS_DIR}"

flutter build "$TARGET" --release \
  --obfuscate \
  --split-debug-info="$SYMBOLS_DIR"

echo ""
echo "✅ 빌드 완료."
echo "⚠ 심볼 폴더를 릴리스별로 백업하세요(예: 클라우드/릴리스 아티팩트): ${SYMBOLS_DIR}"
echo "   git에는 커밋되지 않으며, 잃어버리면 해당 버전 크래시는 복원 불가."
echo "   (Crashlytics 크래시 복원: scripts/symbolize.sh ${VERSION} <stack.txt>)"
