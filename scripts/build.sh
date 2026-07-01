#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DEVECO_SDK_HOME="${DEVECO_SDK_HOME:-C:/Program Files/Huawei/DevEco Studio/sdk/default}"
OHOS_BASE_SDK_HOME="${OHOS_BASE_SDK_HOME:-$DEVECO_SDK_HOME}"
BUILD_MODE="${1:-incremental}"

export DEVECO_SDK_HOME OHOS_BASE_SDK_HOME

if [ "$BUILD_MODE" = "full" ]; then
  VERSION_FLAG="--full"
  BUILD_PACKAGE_SUFFIX="local-full"
else
  VERSION_FLAG="--incremental"
  BUILD_PACKAGE_SUFFIX="local-incremental"
fi

export BUILD_PRODUCT="${BUILD_PRODUCT:-default}"
export BUILD_PLATFORM="${BUILD_PLATFORM:-harmonyos}"
export BUILD_RUNTIME_OS="${BUILD_RUNTIME_OS:-HarmonyOS}"
export BUILD_PACKAGE_SUFFIX

echo "=== ComicReader Build ==="
echo "Mode: $BUILD_MODE"
echo "SDK:  $DEVECO_SDK_HOME"

node scripts/update_build_version.js $VERSION_FLAG --target "$BUILD_PACKAGE_SUFFIX"

if [ "${SKIP_HAP_BUILD:-0}" = "1" ]; then
  echo "Version updated only. SKIP_HAP_BUILD=1, skip hvigor build."
  exit 0
fi

node scripts/build_hap_ci.js assembleHap

HAP_FILE="$(find "$ROOT_DIR/entry/build" -type f -name '*.hap' 2>/dev/null | sort | tail -n 1 || true)"
if [ -n "$HAP_FILE" ]; then
  echo "=== Build Success ==="
  echo "HAP: $HAP_FILE"
else
  echo "=== Build Failed ==="
  exit 1
fi
