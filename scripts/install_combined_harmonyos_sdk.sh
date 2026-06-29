#!/usr/bin/env bash
set -euo pipefail

test -n "${HARMONYOS_SDK_URL:-}"

SDK_BASE="${SDK_BASE:-/home/runner/harmonyos-sdk}"
TOOLS_ROOT="$SDK_BASE/command-line-tools"
DOWNLOAD_DIR="${RUNNER_TEMP:-/tmp}/harmonyos-sdk-download"
SDK_EXTRACT="${RUNNER_TEMP:-/tmp}/harmonyos-command-line-sdk"
SDK_REPO="${HARMONYOS_SDK_REPO:-liyan-lucky/HarmonyOS_SDK_Tools}"

rm -rf "$SDK_BASE" "$SDK_EXTRACT" "$DOWNLOAD_DIR"
mkdir -p "$TOOLS_ROOT" "$SDK_EXTRACT" "$DOWNLOAD_DIR"

download_from_release_tag() {
  local tag="$1"
  echo "Downloading SDK release assets from tag: $tag"
  gh release download "$tag" \
    --repo "$SDK_REPO" \
    --pattern "*.7z" \
    --pattern "*.7z.0*" \
    --pattern "*.zip" \
    --dir "$DOWNLOAD_DIR" \
    --clobber
}

download_direct_url() {
  local output="$1"
  local url="$2"
  local headers="$DOWNLOAD_DIR/download-headers.txt"
  echo "Downloading SDK direct URL"
  if echo "$url" | grep -qE '^https://github.com/'; then
    curl -L --fail --retry 3 --retry-delay 5 \
      -H "Authorization: Bearer ${GH_TOKEN:-}" \
      -H "Accept: application/octet-stream" \
      -D "$headers" \
      -o "$output" "$url"
  else
    curl -L --fail --retry 3 --retry-delay 5 \
      -D "$headers" \
      -o "$output" "$url"
  fi
  echo "Download response headers summary:"
  grep -iE '^(HTTP/|content-length:|content-type:|content-disposition:)' "$headers" || true
}

if echo "$HARMONYOS_SDK_URL" | grep -qE '/releases/tag/'; then
  SDK_TAG="${HARMONYOS_SDK_URL##*/releases/tag/}"
  SDK_TAG="${SDK_TAG%%[?#]*}"
  download_from_release_tag "$SDK_TAG"
else
  SDK_ARCHIVE="$DOWNLOAD_DIR/sdk-direct-download"
  if ! download_direct_url "$SDK_ARCHIVE" "$HARMONYOS_SDK_URL"; then
    if echo "$HARMONYOS_SDK_URL" | grep -qE '/releases/download/'; then
      SDK_TAG="${HARMONYOS_SDK_URL#*/releases/download/}"
      SDK_TAG="${SDK_TAG%%/*}"
      rm -f "$SDK_ARCHIVE"
      download_from_release_tag "$SDK_TAG"
    else
      echo "SDK download failed. HARMONYOS_SDK_URL is not reachable." >&2
      exit 1
    fi
  fi
fi

echo "Downloaded SDK files:"
find "$DOWNLOAD_DIR" -maxdepth 1 -type f -printf '%f %s bytes\n' | sort
for file in "$DOWNLOAD_DIR"/*; do
  [ -f "$file" ] || continue
  echo "file: $(basename "$file") => $(file -b "$file" || true)"
done

SDK_ARCHIVE=""
for candidate in \
  $(find "$DOWNLOAD_DIR" -maxdepth 1 -type f \( -name '*.7z.001' -o -name '*.7z' -o -name '*.zip' -o -name 'sdk-direct-download' -o -name '*.pkg' \) ! -name '*.sha256' ! -name '*.sha512' ! -name '*.md5' | sort)
do
  echo "Testing archive candidate: $(basename "$candidate")"
  if 7z l "$candidate" >/tmp/comicreader_7z_test.log 2>&1; then
    SDK_ARCHIVE="$candidate"
    echo "Selected SDK archive: $(basename "$SDK_ARCHIVE")"
    break
  fi
  echo "Not a readable archive: $(basename "$candidate")"
  cat /tmp/comicreader_7z_test.log || true
done

if [ -z "$SDK_ARCHIVE" ]; then
  echo "No readable SDK archive found after download." >&2
  echo "If the listed file is very small or text/plain, HARMONYOS_SDK_URL points to a checksum/error page instead of the SDK package." >&2
  exit 1
fi

7z x -y "$SDK_ARCHIVE" "-o$SDK_EXTRACT"

echo "Archive directories:"
find "$SDK_EXTRACT" -maxdepth 8 -type d | sort | head -260

HVIGORW="$(find "$SDK_EXTRACT" -type f -name hvigorw.js | sort | head -1)"
OHOS_DIR="$(find "$SDK_EXTRACT" -type d -path '*/sdk/default/openharmony' | sort | head -1)"
if [ -z "$OHOS_DIR" ]; then
  OHOS_DIR="$(find "$SDK_EXTRACT" -type d -path '*/openharmony' | while read -r d; do [ -d "$d/native" ] && echo "$d"; done | sort | head -1)"
fi

if [ -z "$HVIGORW" ]; then
  echo "Could not locate hvigorw.js in combined SDK archive." >&2
  find "$SDK_EXTRACT" -maxdepth 12 -type f | sort | head -320 >&2
  exit 1
fi
if [ -z "$OHOS_DIR" ]; then
  echo "Could not locate OpenHarmony SDK directory in combined SDK archive." >&2
  find "$SDK_EXTRACT" -maxdepth 12 -type d | sort | head -320 >&2
  exit 1
fi

HVIGOR_ROOT="$(dirname "$(dirname "$HVIGORW")")"
SDK_DEFAULT_DIR="${OHOS_DIR%/openharmony}"
SDK_CONTAINER_DIR="$(dirname "$SDK_DEFAULT_DIR")"

echo "HVIGOR_ROOT=$HVIGOR_ROOT"
echo "SDK_DEFAULT_DIR=$SDK_DEFAULT_DIR"
echo "SDK_CONTAINER_DIR=$SDK_CONTAINER_DIR"

rsync -a "$HVIGOR_ROOT/" "$TOOLS_ROOT/hvigor/"
if [ -d "$(dirname "$HVIGOR_ROOT")/ohpm" ]; then
  rsync -a "$(dirname "$HVIGOR_ROOT")/ohpm/" "$TOOLS_ROOT/ohpm/"
fi
if [ -d "$(dirname "$HVIGOR_ROOT")/bin" ]; then
  rsync -a "$(dirname "$HVIGOR_ROOT")/bin/" "$TOOLS_ROOT/bin/"
fi
if [ "$(basename "$SDK_CONTAINER_DIR")" = "sdk" ]; then
  rsync -a "$SDK_CONTAINER_DIR/" "$TOOLS_ROOT/sdk/"
else
  mkdir -p "$TOOLS_ROOT/sdk/default"
  rsync -a "$SDK_DEFAULT_DIR/" "$TOOLS_ROOT/sdk/default/"
fi

chmod +x "$TOOLS_ROOT/hvigor/bin"/* 2>/dev/null || true
chmod +x "$TOOLS_ROOT/ohpm/bin"/* 2>/dev/null || true
chmod +x "$TOOLS_ROOT/bin"/* 2>/dev/null || true
chmod +x "$TOOLS_ROOT/sdk/default/openharmony/toolchains"/* 2>/dev/null || true
chmod +x "$TOOLS_ROOT/sdk/default/openharmony/native/llvm/bin"/* 2>/dev/null || true
chmod +x "$TOOLS_ROOT/sdk/default/openharmony/native/build-tools/cmake/bin"/* 2>/dev/null || true
chmod +x "$TOOLS_ROOT/sdk/default/openharmony/ets/build-tools/ets-loader/bin/ark/build/bin"/* 2>/dev/null || true

echo "Installed command-line tools:"
find "$TOOLS_ROOT" -maxdepth 5 -type d | sort | head -220

test -f "$TOOLS_ROOT/hvigor/bin/hvigorw.js"
test -f "$TOOLS_ROOT/hvigor/hvigor-ohos-plugin/node_modules/@ohos/hos-sdkmanager-common/build/src/hos/mapper/platform-sdks.js"
test -d "$TOOLS_ROOT/sdk/default/openharmony/native"
test -f "$TOOLS_ROOT/sdk/default/openharmony/native/build/cmake/ohos.toolchain.cmake"
