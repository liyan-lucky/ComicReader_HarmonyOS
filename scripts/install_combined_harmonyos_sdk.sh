#!/usr/bin/env bash
set -euo pipefail

test -n "${HARMONYOS_SDK_URL:-}"

SDK_BASE="${SDK_BASE:-/home/runner/harmonyos-sdk}"
TOOLS_ROOT="$SDK_BASE/command-line-tools"
DOWNLOAD_DIR="${RUNNER_TEMP:-/tmp}/harmonyos-sdk-download"
SDK_EXTRACT="${RUNNER_TEMP:-/tmp}/harmonyos-command-line-sdk"
SDK_REPO="${HARMONYOS_SDK_REPO:-liyan-lucky/HarmonyOS_SDK_Tools}"
SDK_TAG_FALLBACK="${HARMONYOS_SDK_TAG:-linux_command_line_tool_6.1.1}"
TMP_BASE="${RUNNER_TEMP:-/tmp}/comicreader-sdk-tmp"

rm -rf "$SDK_BASE" "$SDK_EXTRACT" "$DOWNLOAD_DIR" "$TMP_BASE"
mkdir -p "$TOOLS_ROOT" "$SDK_EXTRACT" "$DOWNLOAD_DIR" "$TMP_BASE"

print_sorted_dirs_head() {
  local root="$1"
  local depth="$2"
  local limit="$3"
  local out="$TMP_BASE/dirs-$(date +%s%N).txt"
  find "$root" -maxdepth "$depth" -type d | sort > "$out"
  head -n "$limit" "$out" || true
}

print_sorted_files_head_stderr() {
  local root="$1"
  local depth="$2"
  local limit="$3"
  local out="$TMP_BASE/files-$(date +%s%N).txt"
  find "$root" -maxdepth "$depth" -type f | sort > "$out" || true
  head -n "$limit" "$out" >&2 || true
}

print_sorted_dirs_head_stderr() {
  local root="$1"
  local depth="$2"
  local limit="$3"
  local out="$TMP_BASE/dirs-err-$(date +%s%N).txt"
  find "$root" -maxdepth "$depth" -type d | sort > "$out" || true
  head -n "$limit" "$out" >&2 || true
}

find_command_line_tools_root() {
  local hvigor_root="$1"
  local ohos_dir="$2"
  local parent="$(dirname "$hvigor_root")"

  if [ -d "$parent/sdk/default/openharmony" ]; then
    echo "$parent"
    return 0
  fi

  while IFS= read -r candidate; do
    if [ -d "$candidate/hvigor" ] && [ -d "$candidate/sdk/default/openharmony" ]; then
      echo "$candidate"
      return 0
    fi
  done < <(find "$SDK_EXTRACT" -type d -name command-line-tools | sort)

  while IFS= read -r candidate; do
    if [ -d "$candidate/hvigor" ] && [ -d "$candidate/sdk/default/openharmony" ]; then
      echo "$candidate"
      return 0
    fi
  done < <(find "$SDK_EXTRACT" -type d | sort)

  if [ -n "$ohos_dir" ]; then
    local default_dir="${ohos_dir%/openharmony}"
    local sdk_dir="$(dirname "$default_dir")"
    local maybe_tools_root="$(dirname "$sdk_dir")"
    if [ -d "$maybe_tools_root/sdk/default/openharmony" ]; then
      echo "$maybe_tools_root"
      return 0
    fi
  fi

  return 1
}

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
  local curl_status=0
  echo "Downloading SDK direct URL"
  if echo "$url" | grep -qE '^https://github.com/'; then
    curl -L --fail --retry 3 --retry-delay 5 \
      -H "Authorization: Bearer ${GH_TOKEN:-}" \
      -H "Accept: application/octet-stream" \
      -D "$headers" \
      -o "$output" "$url" || curl_status=$?
  else
    curl -L --fail --retry 3 --retry-delay 5 \
      -D "$headers" \
      -o "$output" "$url" || curl_status=$?
  fi
  echo "Download response headers summary:"
  grep -iE '^(HTTP/|content-length:|content-type:|content-disposition:)' "$headers" || true
  return "$curl_status"
}

if echo "$HARMONYOS_SDK_URL" | grep -qE '/releases/tag/'; then
  SDK_TAG="${HARMONYOS_SDK_URL##*/releases/tag/}"
  SDK_TAG="${SDK_TAG%%[?#]*}"
  download_from_release_tag "$SDK_TAG"
else
  SDK_ARCHIVE="$DOWNLOAD_DIR/sdk-direct-download"
  if ! download_direct_url "$SDK_ARCHIVE" "$HARMONYOS_SDK_URL"; then
    rm -f "$SDK_ARCHIVE"
    if echo "$HARMONYOS_SDK_URL" | grep -qE '/releases/download/'; then
      SDK_TAG="${HARMONYOS_SDK_URL#*/releases/download/}"
      SDK_TAG="${SDK_TAG%%/*}"
      echo "Direct SDK URL failed; falling back to release tag from URL: $SDK_TAG"
      download_from_release_tag "$SDK_TAG"
    elif [ -n "$SDK_TAG_FALLBACK" ]; then
      echo "Direct SDK URL failed; falling back to release tag: $SDK_TAG_FALLBACK"
      download_from_release_tag "$SDK_TAG_FALLBACK"
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
while IFS= read -r candidate; do
  [ -n "$candidate" ] || continue
  echo "Testing archive candidate: $(basename "$candidate")"
  if 7z l "$candidate" >/tmp/comicreader_7z_test.log 2>&1; then
    SDK_ARCHIVE="$candidate"
    echo "Selected SDK archive: $(basename "$SDK_ARCHIVE")"
    break
  fi
  echo "Not a readable archive: $(basename "$candidate")"
  cat /tmp/comicreader_7z_test.log || true
done < <(find "$DOWNLOAD_DIR" -maxdepth 1 -type f \( -name '*.7z.001' -o -name '*.7z' -o -name '*.zip' -o -name 'sdk-direct-download' -o -name '*.pkg' \) ! -name '*.sha256' ! -name '*.sha512' ! -name '*.md5' | sort)

if [ -z "$SDK_ARCHIVE" ]; then
  echo "No readable SDK archive found after download." >&2
  echo "If the listed file is very small or text/plain, HARMONYOS_SDK_URL points to a checksum/error page instead of the SDK package." >&2
  exit 1
fi

7z x -y "$SDK_ARCHIVE" "-o$SDK_EXTRACT"

echo "Archive directories:"
print_sorted_dirs_head "$SDK_EXTRACT" 8 260

HVIGORW=""
while IFS= read -r f; do
  HVIGORW="$f"
  break
done < <(find "$SDK_EXTRACT" -type f -name hvigorw.js | sort)

OHOS_DIR=""
while IFS= read -r d; do
  OHOS_DIR="$d"
  break
done < <(find "$SDK_EXTRACT" -type d -path '*/sdk/default/openharmony' | sort)

if [ -z "$OHOS_DIR" ]; then
  while IFS= read -r d; do
    if [ -d "$d/native" ]; then
      OHOS_DIR="$d"
      break
    fi
  done < <(find "$SDK_EXTRACT" -type d -path '*/openharmony' | sort)
fi

if [ -z "$HVIGORW" ]; then
  echo "Could not locate hvigorw.js in combined SDK archive." >&2
  print_sorted_files_head_stderr "$SDK_EXTRACT" 12 320
  exit 1
fi
if [ -z "$OHOS_DIR" ]; then
  echo "Could not locate OpenHarmony SDK directory in combined SDK archive." >&2
  print_sorted_dirs_head_stderr "$SDK_EXTRACT" 12 320
  exit 1
fi

HVIGOR_ROOT="$(dirname "$(dirname "$HVIGORW")")"
SDK_DEFAULT_DIR="${OHOS_DIR%/openharmony}"
SDK_CONTAINER_DIR="$(dirname "$SDK_DEFAULT_DIR")"
COMMAND_LINE_TOOLS_ROOT="$(find_command_line_tools_root "$HVIGOR_ROOT" "$OHOS_DIR" || true)"

echo "COMMAND_LINE_TOOLS_ROOT=$COMMAND_LINE_TOOLS_ROOT"
echo "HVIGOR_ROOT=$HVIGOR_ROOT"
echo "SDK_DEFAULT_DIR=$SDK_DEFAULT_DIR"
echo "SDK_CONTAINER_DIR=$SDK_CONTAINER_DIR"

rm -rf "$TOOLS_ROOT"
mkdir -p "$TOOLS_ROOT"

if [ -n "$COMMAND_LINE_TOOLS_ROOT" ]; then
  echo "Installing full command-line-tools layout from $COMMAND_LINE_TOOLS_ROOT"
  rsync -a "$COMMAND_LINE_TOOLS_ROOT/" "$TOOLS_ROOT/"
else
  echo "Full command-line-tools root not found; installing detected components only."
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
fi

chmod +x "$TOOLS_ROOT/hvigor/bin"/* 2>/dev/null || true
chmod +x "$TOOLS_ROOT/ohpm/bin"/* 2>/dev/null || true
chmod +x "$TOOLS_ROOT/bin"/* 2>/dev/null || true
chmod +x "$TOOLS_ROOT/sdk/default/openharmony/toolchains"/* 2>/dev/null || true
chmod +x "$TOOLS_ROOT/sdk/default/openharmony/native/llvm/bin"/* 2>/dev/null || true
chmod +x "$TOOLS_ROOT/sdk/default/openharmony/native/build-tools/cmake/bin"/* 2>/dev/null || true
chmod +x "$TOOLS_ROOT/sdk/default/openharmony/ets/build-tools/ets-loader/bin/ark/build/bin"/* 2>/dev/null || true

echo "Installed command-line tools:"
print_sorted_dirs_head "$TOOLS_ROOT" 5 260

echo "Installed command-line-tools top-level entries:"
find "$TOOLS_ROOT" -maxdepth 1 -mindepth 1 -printf '%f\n' | sort

echo "Installed sdk/default entries:"
find "$TOOLS_ROOT/sdk/default" -maxdepth 1 -mindepth 1 -printf '%f\n' | sort || true

test -f "$TOOLS_ROOT/hvigor/bin/hvigorw.js"
test -f "$TOOLS_ROOT/hvigor/hvigor-ohos-plugin/node_modules/@ohos/hos-sdkmanager-common/build/src/hos/mapper/platform-sdks.js"
test -d "$TOOLS_ROOT/sdk/default/openharmony/native"
test -f "$TOOLS_ROOT/sdk/default/openharmony/native/build/cmake/ohos.toolchain.cmake"
