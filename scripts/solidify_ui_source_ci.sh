#!/usr/bin/env bash
set -euo pipefail

INDEX="entry/src/main/ets/pages/Index.ets"
BACKUP="entry/src/main/ets/pages/Index.original.ets"

test -f "$INDEX"
if [ ! -f "$BACKUP" ]; then
  cp "$INDEX" "$BACKUP"
fi

node scripts/update_build_version.js --no-bump --target source-solidified
node scripts/patch_about_page_ci.js
node scripts/patch_modern_ui_ci.js

python3 - <<'PY'
from pathlib import Path
p = Path('scripts/build_hap_ci.js')
s = p.read_text()
old = """function applySourcePatchesOnce() {
  if (process.env.COMIC_READER_SOURCE_PATCHED === '1') {
    console.log('ComicReader CI skipped source UI patches because they were already applied in this process tree.');
    return;
  }
  process.env.COMIC_READER_SOURCE_PATCHED = '1';
  require('./update_build_version.js').writeCurrentBuildInfo({
    buildType: process.env.BUILD_PACKAGE_SUFFIX || 'ci',
    target: process.env.BUILD_PACKAGE_SUFFIX || process.env.BUILD_PRODUCT || 'source'
  });
  require('./patch_about_page_ci.js');
  require('./patch_modern_ui_ci.js');
}

installPrimitiveSdkComponentCompat();
applySourcePatchesOnce();
"""
new = """function writeCurrentBuildInfoOnly() {
  require('./update_build_version.js').writeCurrentBuildInfo({
    buildType: process.env.BUILD_PACKAGE_SUFFIX || 'ci',
    target: process.env.BUILD_PACKAGE_SUFFIX || process.env.BUILD_PRODUCT || 'source'
  });
}

installPrimitiveSdkComponentCompat();
writeCurrentBuildInfoOnly();
"""
if old not in s:
    raise SystemExit('build_hap_ci.js marker not found')
p.write_text(s.replace(old, new))
PY

python3 - <<'PY'
from pathlib import Path
for name in ['scripts/build_full.sh', 'scripts/build_incremental.sh']:
    p = Path(name)
    s = p.read_text()
    s = s.replace('\nif [ "${SKIP_HAP_BUILD:-0}" = "1" ]; then\n  node scripts/patch_about_page_ci.js\n  node scripts/patch_modern_ui_ci.js\n  echo "Version and UI source patch updated only. SKIP_HAP_BUILD=1, skip hvigor build."\n  exit 0\nfi\n', '\nif [ "${SKIP_HAP_BUILD:-0}" = "1" ]; then\n  echo "Version updated only. SKIP_HAP_BUILD=1, skip hvigor build."\n  exit 0\nfi\n')
    p.write_text(s)
PY

node - <<'NODE'
const fs = require('fs');
const index = fs.readFileSync('entry/src/main/ets/pages/Index.ets', 'utf8');
for (const marker of ['../common/BuildInfo','@State private appTheme','@State private appLanguage','private TabPill(','private AboutPage()','private ReaderFloatingButton(','lastReadUrl','progressPercent','readCount']) {
  if (!index.includes(marker)) throw new Error('Missing marker: ' + marker);
}
const build = fs.readFileSync('scripts/build_hap_ci.js', 'utf8');
if (build.includes("require('./patch_about_page_ci.js')") || build.includes("require('./patch_modern_ui_ci.js')")) {
  throw new Error('formal build still invokes UI patch scripts');
}
NODE
