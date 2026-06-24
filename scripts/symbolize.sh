#!/usr/bin/env bash
#
# Crashlytics에 올라온 난독화된 Dart 스택트레이스를 사람이 읽을 수 있게 복원한다.
#
# 사용법:
#   scripts/symbolize.sh <version> <stacktrace.txt> [arch]
#
#   <version>        build_release.sh 빌드 시의 pubspec version (예: 2.2.0+11)
#   <stacktrace.txt> Crashlytics 콘솔에서 복사한 스택트레이스를 저장한 파일
#   [arch]           심볼 아키텍처 (기본 arm64. 필요 시 arm / x64)
#
# 예) scripts/symbolize.sh 2.2.0+11 crash.txt
#
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${1:?version 인자가 필요합니다 (예: 2.2.0+11)}"
INPUT="${2:?스택트레이스 파일 경로가 필요합니다}"
ARCH="${3:-arm64}"

SYMBOL_FILE="release-symbols/${VERSION}/app.android-${ARCH}.symbols"

if [[ ! -f "$SYMBOL_FILE" ]]; then
  echo "심볼 파일을 찾을 수 없습니다: ${SYMBOL_FILE}" >&2
  echo "해당 버전의 심볼 폴더(release-symbols/${VERSION})를 보관해 두었는지 확인하세요." >&2
  exit 1
fi

flutter symbolize -i "$INPUT" -d "$SYMBOL_FILE"
