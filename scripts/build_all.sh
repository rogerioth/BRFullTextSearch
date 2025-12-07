#!/usr/bin/env bash
set -euo pipefail

# Builds every shipped artifact (libraries/frameworks) across the supported platforms.
# Depends on an already-installed Pods workspace (run `pod install` first).

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-${ROOT_DIR}/DerivedData}"
WORKSPACE="BRFullTextSearch.xcworkspace"
CONFIGURATION="${CONFIGURATION:-Release}"

declare -a STEP_NAMES=()
declare -a STEP_DURATIONS=()

# Clean previous build artifacts to force a fresh build.
rm -rf "${DERIVED_DATA_PATH}" "${ROOT_DIR}/Framework/Release" "${ROOT_DIR}/Framework/Debug" "${ROOT_DIR}/Artifacts"

record_step() {
  local name="$1"
  shift
  local start_ts end_ts
  start_ts="$(date +%s)"
  "$@"
  end_ts="$(date +%s)"
  STEP_NAMES+=("${name}")
  STEP_DURATIONS+=("$((end_ts - start_ts))")
}

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

run_aggregate() {
  local scheme="$1"
  local label="$2"

  echo "==> Building ${label}"
  if command -v xcpretty >/dev/null 2>&1; then
    xcodebuild \
      -workspace "${WORKSPACE}" \
      -scheme "${scheme}" \
      -configuration "${CONFIGURATION}" \
      -derivedDataPath "${DERIVED_DATA_PATH}" \
      build \
      | xcpretty --color || exit "${PIPESTATUS[0]}"
  else
    xcodebuild \
      -workspace "${WORKSPACE}" \
      -scheme "${scheme}" \
      -configuration "${CONFIGURATION}" \
      -derivedDataPath "${DERIVED_DATA_PATH}" \
      build
  fi
}

record_step "iOS (simulator)" run_build "BRFullTextSearch" "generic/platform=iOS Simulator" "iOS (simulator)"
record_step "Mac Catalyst" run_build "BRFullTextSearch" "platform=macOS,variant=Mac Catalyst" "Mac Catalyst"
record_step "macOS" run_build "BRFullTextSearchMacOS" "generic/platform=macOS" "macOS"
# Aggregate target that packages the iOS static framework bundle into Framework/Release.
record_step "iOS static framework packager" run_aggregate "BRFullTextSearch.framework" "iOS static framework packager"
# Combine all built slices (iOS device/sim, macOS, Mac Catalyst) into a single XCFramework.
record_step "XCFramework packaging" "${ROOT_DIR}/scripts/package_xcframework.sh"

echo
echo "==> Build report"

for i in "${!STEP_NAMES[@]}"; do
  printf " - %-28s %3ss\n" "${STEP_NAMES[$i]}" "${STEP_DURATIONS[$i]}"
done

FRAMEWORK_DIR="${ROOT_DIR}/Framework/Release"
IOS_DEVICE_FW="${FRAMEWORK_DIR}/device/BRFullTextSearch.framework"
IOS_SIM_FW="${FRAMEWORK_DIR}/simulator/BRFullTextSearch.framework"
MACOS_FW="${DERIVED_DATA_PATH}/Build/Products/Release/BRFullTextSearch.framework"
CATALYST_FW="${FRAMEWORK_DIR}/catalyst/BRFullTextSearch.framework"
XCFRAMEWORK="${FRAMEWORK_DIR}/BRFullTextSearch.xcframework"
DIST_DIR="${ROOT_DIR}/Artifacts"
DIST_XCFRAMEWORK="${DIST_DIR}/BRFullTextSearch.xcframework"

# Copy the packaged XCFramework to a git-tracked location for SwiftPM consumption.
mkdir -p "${DIST_DIR}"
rm -rf "${DIST_XCFRAMEWORK}"
rsync -a "${XCFRAMEWORK}" "${DIST_DIR}/"

artifact_row() {
  local label="$1"
  local path="$2"
  local size="missing"
  if [ -e "${path}" ]; then
    size="$(du -sh "${path}" | cut -f1)"
  fi
  printf " - %-28s %10s  %s\n" "${label}" "${size}" "${path}"
}

echo
echo "Artifacts included in XCFramework:"
artifact_row "iOS (device)" "${IOS_DEVICE_FW}"
artifact_row "iOS (simulator)" "${IOS_SIM_FW}"
artifact_row "macOS" "${MACOS_FW}"
artifact_row "Mac Catalyst" "${CATALYST_FW}"
echo
artifact_row "XCFramework" "${XCFRAMEWORK}"
artifact_row "XCFramework (dist)" "${DIST_XCFRAMEWORK}"
