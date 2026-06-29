#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BUILD_PRODUCT="${BUILD_PRODUCT:-default}"
BUILD_PLATFORM="${BUILD_PLATFORM:-harmonyos}"
BUILD_RUNTIME_OS="${BUILD_RUNTIME_OS:-HarmonyOS}"
BUILD_PACKAGE_SUFFIX="${BUILD_PACKAGE_SUFFIX:-local-full}"

export BUILD_PRODUCT BUILD_PLATFORM BUILD_RUNTIME_OS BUILD_PACKAGE_SUFFIX

node scripts/update_build_version.js --full --target "$BUILD_PACKAGE_SUFFIX"

if [ "${SKIP_HAP_BUILD:-0}" = "1" ]; then
  node scripts/patch_about_page_ci.js
  node scripts/patch_modern_ui_ci.js
  echo "Version and UI source patch updated only. SKIP_HAP_BUILD=1, skip hvigor build."
  exit 0
fi

node scripts/build_hap_ci.js assembleHap

echo "Possible HAP outputs:"
find "$ROOT_DIR" -type f -name '*.hap' -print | sort
