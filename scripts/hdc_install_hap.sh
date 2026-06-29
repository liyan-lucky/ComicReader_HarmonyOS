#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

HAP_PATH="${1:-}"

if [ -z "$HAP_PATH" ]; then
  HAP_PATH="$(find "$ROOT_DIR" /tmp/comic_reader_harmonyos_artifacts -type f -name '*.hap' 2>/dev/null | sort | tail -n 1 || true)"
fi

if [ -z "$HAP_PATH" ] || [ ! -f "$HAP_PATH" ]; then
  echo "No HAP file found. Pass the HAP file path as the first argument." >&2
  exit 1
fi

if ! command -v hdc >/dev/null 2>&1; then
  echo "hdc not found in PATH." >&2
  exit 1
fi

hdc list targets || true
hdc install -r "$HAP_PATH"
