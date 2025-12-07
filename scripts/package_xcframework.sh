#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${ROOT_DIR}/Framework/Release"
HEADERS_DIR="${ROOT_DIR}/Framework/Headers"
RESOURCES_DIR="${ROOT_DIR}/Framework/Resources"

DEVICE_FW="${OUTPUT_DIR}/device/BRFullTextSearch.framework"
SIMULATOR_FW="${OUTPUT_DIR}/simulator/BRFullTextSearch.framework"
MACOS_FW="${ROOT_DIR}/DerivedData/Build/Products/Release/BRFullTextSearch.framework"
CATALYST_LIB="${ROOT_DIR}/DerivedData/Build/Products/Release-maccatalyst/libBRFullTextSearch.a"
CATALYST_FW="${OUTPUT_DIR}/catalyst/BRFullTextSearch.framework"

XCFRAMEWORK_PATH="${OUTPUT_DIR}/BRFullTextSearch.xcframework"

require_path() {
  local path="$1"
  local type="$2" # file or dir
  if [[ "${type}" == "file" && ! -f "${path}" ]]; then
    echo "Missing file: ${path}"
    exit 1
  fi
  if [[ "${type}" == "dir" && ! -d "${path}" ]]; then
    echo "Missing directory: ${path}"
    exit 1
  fi
}

build_framework_from_static_lib() {
  local source_lib="$1"
  local framework_path="$2"

  rm -rf "${framework_path}"
  mkdir -p "${framework_path}/Versions/A"

  cp "${source_lib}" "${framework_path}/Versions/A/BRFullTextSearch"
  cp -r "${HEADERS_DIR}" "${framework_path}/Versions/A/Headers"
  cp -r "${RESOURCES_DIR}" "${framework_path}/Versions/A/Resources"

  mkdir -p "${framework_path}/Versions/A/Modules"
  cat > "${framework_path}/Versions/A/Modules/module.modulemap" <<'EOF'
framework module BRFullTextSearch {
  umbrella header "BRFullTextSearch.h"
  export *
  module * { export * }
}
EOF

  (cd "${framework_path}/Versions" && ln -sf A Current)
  (cd "${framework_path}" && ln -sf Versions/Current/BRFullTextSearch BRFullTextSearch)
  (cd "${framework_path}" && ln -sf Versions/Current/Headers Headers)
  (cd "${framework_path}" && ln -sf Versions/Current/Resources Resources)
  (cd "${framework_path}" && ln -sf Versions/Current/Modules Modules)
}

require_path "${DEVICE_FW}" "dir"
require_path "${SIMULATOR_FW}" "dir"
require_path "${MACOS_FW}" "dir"
require_path "${CATALYST_LIB}" "file"
require_path "${HEADERS_DIR}" "dir"
require_path "${RESOURCES_DIR}" "dir"

add_modulemap() {
  local framework_path="$1"
  mkdir -p "${framework_path}/Versions/A/Modules"
  rm -f "${framework_path}/Versions/A/Modules/Modules"
  cat > "${framework_path}/Versions/A/Modules/module.modulemap" <<'EOF'
framework module BRFullTextSearch {
  umbrella header "BRFullTextSearch.h"
  export *
  module * { export * }
}
EOF
  (cd "${framework_path}" && ln -sf Versions/Current/Modules Modules)
}

echo "Building Mac Catalyst framework wrapper..."
build_framework_from_static_lib "${CATALYST_LIB}" "${CATALYST_FW}"

# Ensure all slices have a module map for Swift import.
add_modulemap "${DEVICE_FW}"
add_modulemap "${SIMULATOR_FW}"
add_modulemap "${MACOS_FW}"
add_modulemap "${CATALYST_FW}"

echo "Creating XCFramework at ${XCFRAMEWORK_PATH}"
rm -rf "${XCFRAMEWORK_PATH}"

xcodebuild -create-xcframework \
  -framework "${DEVICE_FW}" \
  -framework "${SIMULATOR_FW}" \
  -framework "${MACOS_FW}" \
  -framework "${CATALYST_FW}" \
  -output "${XCFRAMEWORK_PATH}"

echo "Done: ${XCFRAMEWORK_PATH}"
