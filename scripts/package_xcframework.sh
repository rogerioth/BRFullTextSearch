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
  umbrella header "../Headers/BRFullTextSearch.h"
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

CLUCENE_SRC="${DEVICE_FW}/Versions/A/Headers/CLucene"
if [[ ! -d "${CLUCENE_SRC}" && -d "${SIMULATOR_FW}/Versions/A/Headers/CLucene" ]]; then
  CLUCENE_SRC="${SIMULATOR_FW}/Versions/A/Headers/CLucene"
fi
LIBSTEMMER_SRC="${DEVICE_FW}/Versions/A/Headers/libstemmer.h"
if [[ ! -f "${LIBSTEMMER_SRC}" && -f "${SIMULATOR_FW}/Versions/A/Headers/libstemmer.h" ]]; then
  LIBSTEMMER_SRC="${SIMULATOR_FW}/Versions/A/Headers/libstemmer.h"
fi

copy_public_headers() {
  local framework_path="$1"
  local dest="${framework_path}/Versions/A/Headers"
  mkdir -p "${dest}"
  for header in "${ROOT_DIR}/BRFullTextSearch/"*.h; do
    cp "${header}" "${dest}/"
  done
  if [[ -d "${CLUCENE_SRC}" ]]; then
    mkdir -p "${dest}/CLucene"
    if [[ "${CLUCENE_SRC}" != "${dest}/CLucene" ]]; then
      rsync -a "${CLUCENE_SRC}/" "${dest}/CLucene/"
    fi
  fi
  if [[ -f "${LIBSTEMMER_SRC:-}" && ! -f "${dest}/libstemmer.h" ]]; then
    cp "${LIBSTEMMER_SRC}" "${dest}/"
  fi
}

add_modulemap() {
  local framework_path="$1"
  mkdir -p "${framework_path}/Versions/A/Modules"
  rm -f "${framework_path}/Versions/A/Modules/Modules"
  cat > "${framework_path}/Versions/A/Modules/module.modulemap" <<'EOF'
framework module BRFullTextSearch {
  umbrella header "../Headers/BRFullTextSearch.h"
  export *
  module * { export * }
}
EOF
  (cd "${framework_path}" && ln -sf Versions/Current/Modules Modules)
}

echo "Building Mac Catalyst framework wrapper..."
build_framework_from_static_lib "${CATALYST_LIB}" "${CATALYST_FW}"

# Ensure all slices have a module map for Swift import.
copy_public_headers "${DEVICE_FW}"
copy_public_headers "${SIMULATOR_FW}"
copy_public_headers "${MACOS_FW}"
copy_public_headers "${CATALYST_FW}"
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
