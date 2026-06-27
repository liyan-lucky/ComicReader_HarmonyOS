#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_ROOT="/home/runner/harmonyos-sdk"
ARTIFACT_DIR="${ARTIFACT_DIR:-${RUNNER_TEMP:-/tmp}/comic_reader_harmonyos_artifacts}"
SDK_URL="${HARMONYOS_SDK_URL:-}"
FULL_URL="${HARMONYOS_FULL_URL:-}"
RUNNER_TEMP="${RUNNER_TEMP:-/tmp}"

say() {
  echo "[漫画浏览器构建] $*"
}

need_url() {
  local name="$1"
  local value="$2"
  local desc="$3"
  if [ -z "$value" ]; then
    say "没有填写 $name。"
    say "请在仓库 Settings → Secrets and variables → Actions 里添加 $name。"
    say "用途：$desc"
    exit 1
  fi
}

need_file() {
  local path="$1"
  if [ ! -e "$ROOT/$path" ]; then
    say "缺少项目文件：$path"
    return 1
  fi
  say "存在：$path"
  return 0
}

install_sdk() {
  need_url "HARMONYOS_SDK_URL" "$SDK_URL" "完整 HarmonyOS SDK 压缩包下载链接。"
  need_url "HARMONYOS_FULL_URL" "$FULL_URL" "SDK 以外的完整命令行工具、hvigor 或补充文件压缩包下载链接。"

  local sdk_zip="$RUNNER_TEMP/harmonyos-sdk.zip"
  local sdk_unzip="$RUNNER_TEMP/harmonyos-sdk-unzip"
  rm -rf "$SDK_ROOT" "$sdk_unzip"
  mkdir -p "$SDK_ROOT" "$sdk_unzip"

  say "正在下载完整 SDK 包..."
  curl -L --fail --retry 3 --retry-delay 5 -o "$sdk_zip" "$SDK_URL"

  say "正在解压完整 SDK 包..."
  unzip -oq "$sdk_zip" -d "$sdk_unzip"

  local source=""
  shopt -s nullglob
  for candidate in \
    "$sdk_unzip" \
    "$sdk_unzip"/* \
    "$sdk_unzip"/default \
    "$sdk_unzip"/sdk/default \
    "$sdk_unzip"/*/default \
    "$sdk_unzip"/*/sdk/default
  do
    if [ -d "$candidate/openharmony" ] || [ -d "$candidate/hms" ] || [ -f "$candidate/sdk-pkg.json" ]; then
      source="$candidate"
      break
    fi
  done

  if [ -z "$source" ]; then
    say "没有在 SDK 压缩包里找到 SDK 根目录。"
    find "$sdk_unzip" -maxdepth 5 -type f | sort | head -160
    exit 1
  fi

  say "找到 SDK 来源目录：$source"

  move_item() {
    local src="$1"
    local dst="$2"
    if [ -e "$src" ]; then
      rm -rf "$dst"
      mv "$src" "$dst"
    fi
  }

  move_item "$source/openharmony" "$SDK_ROOT/openharmony"
  move_item "$source/hms" "$SDK_ROOT/hms"
  move_item "$source/sdk-pkg.json" "$SDK_ROOT/sdk-pkg.json"
  move_item "$source/command-line-tools" "$SDK_ROOT/command-line-tools"

  if [ ! -e "$SDK_ROOT/HarmonyOS-6.1.1" ] && [ -d "$SDK_ROOT/hms" ]; then
    ln -s hms "$SDK_ROOT/HarmonyOS-6.1.1"
  fi

  say "正在下载 SDK 以外补充文件包..."
  local extra_zip="$RUNNER_TEMP/harmonyos-extra.zip"
  local extra_unzip="$RUNNER_TEMP/harmonyos-extra-unzip"
  rm -rf "$extra_unzip"
  mkdir -p "$extra_unzip"
  curl -L --fail --retry 3 --retry-delay 5 -o "$extra_zip" "$FULL_URL"

  say "正在解压 SDK 以外补充文件包..."
  unzip -oq "$extra_zip" -d "$extra_unzip"

  local extra_source=""
  for candidate in "$extra_unzip" "$extra_unzip"/* "$extra_unzip"/*/*; do
    if [ -d "$candidate/command-line-tools" ] || [ -d "$candidate/hvigor" ] || [ -d "$candidate/ohpm" ]; then
      extra_source="$candidate"
      break
    fi
  done

  if [ -z "$extra_source" ]; then
    say "没有识别到补充文件根目录，按原样合并到 SDK 根目录。"
    rsync -a "$extra_unzip"/ "$SDK_ROOT"/
  else
    say "识别到补充文件来源目录：$extra_source"
    mkdir -p "$SDK_ROOT/command-line-tools"
    if [ -d "$extra_source/command-line-tools" ]; then
      rsync -a "$extra_source/command-line-tools"/ "$SDK_ROOT/command-line-tools"/
    else
      rsync -a "$extra_source"/ "$SDK_ROOT/command-line-tools"/
    fi
  fi

  chmod +x "$SDK_ROOT"/openharmony/toolchains/* 2>/dev/null || true
  chmod +x "$SDK_ROOT"/hms/toolchains/* 2>/dev/null || true
  chmod +x "$SDK_ROOT"/command-line-tools/*/bin/* 2>/dev/null || true
  chmod +x "$SDK_ROOT"/command-line-tools/hvigor/bin/* 2>/dev/null || true
  chmod +x "$SDK_ROOT"/command-line-tools/ohpm/bin/* 2>/dev/null || true

  export DEVECO_SDK_HOME="$SDK_ROOT"
  export OHOS_HVIGOR_SDK_ROOT="$SDK_ROOT"
  export DEVECO_TOOLS_HOME="$SDK_ROOT/command-line-tools"
  export DEVECO_NODE_EXE="$(command -v node)"
  export PATH="$SDK_ROOT/command-line-tools/bin:$SDK_ROOT/command-line-tools/ohpm/bin:$SDK_ROOT/command-line-tools/hvigor/bin:$PATH"
  export LD_LIBRARY_PATH="$SDK_ROOT/hms/toolchains/lib:$SDK_ROOT/openharmony/previewer/common/bin:$SDK_ROOT/openharmony/ets/build-tools/ets-loader/bin/ark/build/bin:$SDK_ROOT/openharmony/toolchains:$SDK_ROOT/openharmony/toolchains/lib:$SDK_ROOT/hms/native/sysroot/usr/lib/x86_64-linux-ohos:${LD_LIBRARY_PATH:-}"

  say "SDK 根目录：$SDK_ROOT"
  find "$SDK_ROOT" -maxdepth 3 -type d | sort | head -120
}

check_project() {
  say "检查项目结构..."
  local missing=0
  need_file "build-profile.json5" || missing=1
  need_file "hvigorfile.ts" || missing=1
  need_file "oh-package.json5" || missing=1
  need_file "AppScope/app.json5" || missing=1
  need_file "entry/build-profile.json5" || missing=1
  need_file "entry/hvigorfile.ts" || missing=1
  need_file "entry/oh-package.json5" || missing=1
  need_file "entry/src/main/module.json5" || missing=1
  need_file "entry/src/main/ets/pages/Index.ets" || missing=1
  if [ "$missing" -ne 0 ]; then
    say "项目结构不完整，停止构建。"
    exit 1
  fi
}

install_deps() {
  say "尝试安装 ohpm 依赖..."
  local ohpm=""
  for candidate in \
    "$SDK_ROOT/command-line-tools/ohpm/bin/ohpm" \
    "$SDK_ROOT/command-line-tools/bin/ohpm" \
    "$(command -v ohpm || true)"
  do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
      ohpm="$candidate"
      break
    fi
  done

  if [ -z "$ohpm" ]; then
    say "没有找到 ohpm，跳过依赖安装。"
    return 0
  fi
  say "使用 ohpm：$ohpm"
  cd "$ROOT"
  "$ohpm" install --all || "$ohpm" install || true
}

patch_unsigned() {
  say "确认未签名构建配置..."
  python3 - <<'PY'
from pathlib import Path
import re
p = Path('build-profile.json5')
s = p.read_text(encoding='utf-8')
# JSON5 允许空格和单引号，这里统一把 default 签名清空，避免线上无证书时报错。
s = re.sub(r'(["\']signingConfig["\']\s*:\s*)["\']default["\']', r'\1""', s)
p.write_text(s, encoding='utf-8')
print('已确认 signingConfig 为空。')
PY
}

run_build() {
  say "开始执行 HAP 构建..."
  cd "$ROOT"
  mkdir -p "$ARTIFACT_DIR"

  local build_ok=0
  try_build() {
    say "尝试构建命令：$*"
    if "$@"; then
      build_ok=1
    fi
  }

  if [ -x "$SDK_ROOT/command-line-tools/hvigor/bin/hvigorw" ]; then
    try_build "$SDK_ROOT/command-line-tools/hvigor/bin/hvigorw" assembleHap || true
  fi

  if [ "$build_ok" -eq 0 ] && [ -f "$SDK_ROOT/command-line-tools/hvigor/bin/hvigorw.js" ]; then
    try_build node "$SDK_ROOT/command-line-tools/hvigor/bin/hvigorw.js" assembleHap || true
  fi

  if [ "$build_ok" -eq 0 ] && command -v hvigorw >/dev/null 2>&1; then
    try_build hvigorw assembleHap || true
  fi

  if [ "$build_ok" -eq 0 ]; then
    say "HAP 构建命令没有成功。下面列出可疑工具文件："
    find "$SDK_ROOT/command-line-tools" -maxdepth 6 -type f \( -name "hvigor*" -o -name "ohpm" \) | sort || true
    exit 1
  fi

  say "查找构建产物..."
  find "$ROOT" -type f \( -name "*.hap" -o -name "*.app" -o -name "*.har" \) -print | sort | tee "$RUNNER_TEMP/artifact-list.txt"
  if ! grep -q "\.hap$" "$RUNNER_TEMP/artifact-list.txt"; then
    say "没有找到 HAP 包，说明构建虽然返回成功，但没有实际出包。"
    exit 1
  fi

  while IFS= read -r file_path; do
    [ -f "$file_path" ] || continue
    cp -f "$file_path" "$ARTIFACT_DIR/$(basename "$file_path")"
  done < "$RUNNER_TEMP/artifact-list.txt"

  say "最终上传目录："
  find "$ARTIFACT_DIR" -maxdepth 1 -type f -print | sort
}

main() {
  cd "$ROOT"
  say "Node 版本：$(node -v)"
  install_sdk
  check_project
  install_deps
  patch_unsigned
  run_build
}

main "$@"
