#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

HAP_PATH="${1:-}"

if [ -z "$HAP_PATH" ]; then
  HAP_PATH="$(find "$ROOT_DIR/entry/build" -type f -name '*.hap' 2>/dev/null | sort | tail -n 1 || true)"
fi

if [ -z "$HAP_PATH" ] || [ ! -f "$HAP_PATH" ]; then
  echo "No HAP file found. Pass the HAP file path as the first argument." >&2
  exit 1
fi

HAP_PATH="$(cd "$(dirname "$HAP_PATH")" && pwd)/$(basename "$HAP_PATH")"

if ! command -v hdc >/dev/null 2>&1; then
  echo "hdc not found in PATH." >&2
  echo "Add DevEco SDK toolchains to PATH, e.g.:"
  echo "  export PATH=\"/c/Program Files/Huawei/DevEco Studio/sdk/default/openharmony/toolchains:\$PATH\""
  exit 1
fi

BUNDLE_NAME="com.nw.cleansite.novel.hm"

echo "=== ComicReader Install ==="
echo "HAP: $HAP_PATH"

hdc uninstall "$BUNDLE_NAME" 2>/dev/null || true

WIN_HAP_PATH="$(cygpath -w "$HAP_PATH" 2>/dev/null || echo "$HAP_PATH")"
hdc install -r "$WIN_HAP_PATH"

echo "=== Install Complete ==="
