#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-${ROOT_DIR}/DerivedData}"
WORKSPACE="BRFullTextSearch.xcworkspace"
CONFIGURATION="${CONFIGURATION:-Release}"

run_build() {
  local scheme="$1"
  local destination="$2"
  local label="$3"

  echo "==> Building ${label}"
  if command -v xcpretty >/dev/null 2>&1; then
    xcodebuild \
      -workspace "${WORKSPACE}" \
      -scheme "${scheme}" \
      -configuration "${CONFIGURATION}" \
      -destination "${destination}" \
      -derivedDataPath "${DERIVED_DATA_PATH}" \
      build \
      | xcpretty --color || exit "${PIPESTATUS[0]}"
  else
    xcodebuild \
      -workspace "${WORKSPACE}" \
      -scheme "${scheme}" \
      -configuration "${CONFIGURATION}" \
      -destination "${destination}" \
      -derivedDataPath "${DERIVED_DATA_PATH}" \
      build
  fi
}

run_build "BRFullTextSearch" "generic/platform=iOS Simulator" "iOS (simulator)"
run_build "BRFullTextSearch" "platform=macOS,variant=Mac Catalyst" "Mac Catalyst"
run_build "BRFullTextSearch" "generic/platform=visionOS Simulator" "visionOS (simulator)"
run_build "BRFullTextSearchMacOS" "generic/platform=macOS" "macOS"
