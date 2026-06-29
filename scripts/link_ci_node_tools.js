const fs = require('fs');
const path = require('path');

function shouldLink() {
  const platform = String(process.env.BUILD_PLATFORM || '').toLowerCase();
  const runtime = String(process.env.BUILD_RUNTIME_OS || '').toLowerCase();
  const product = String(process.env.BUILD_PRODUCT || '').toLowerCase();
  return platform.includes('openharmony') || runtime.includes('openharmony') || product.includes('openharmony');
}

function writeFileIfChanged(file, content) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  if (fs.existsSync(file) && fs.readFileSync(file, 'utf8') === content) return;
  fs.writeFileSync(file, content);
}

function makeWebpackStub() {
  return `#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const childProcess = require('child_process');

const root = process.cwd();
const product = String(process.env.BUILD_PRODUCT || 'openharmony_verify') || 'openharmony_verify';
const configArgIndex = process.argv.findIndex((arg) => arg === '--config');
const configPath = configArgIndex >= 0 && process.argv[configArgIndex + 1]
  ? path.resolve(root, process.argv[configArgIndex + 1])
  : path.resolve(root, 'webpack.config.js');

function ensureOpenHarmonyLoaderOutputs() {
  const candidates = [
    path.resolve(root, 'entry/build', product, 'intermediates/loader_out', product, 'ets'),
    path.resolve(root, 'entry/build', product, 'intermediates/loader_out', product, 'js'),
    path.resolve(root, 'entry/build/openharmony_verify/intermediates/loader_out/openharmony_verify/ets'),
    path.resolve(root, 'entry/build/openharmony_verify/intermediates/loader_out/openharmony_verify/js')
  ];
  for (const dir of candidates) {
    fs.mkdirSync(dir, { recursive: true });
  }
  console.error('ComicReader CI ensured OpenHarmony loader output directories.');
}

const toolsRoot = path.resolve(process.env.DEVECO_TOOLS_ROOT || process.env.DEVECO_TOOLS_HOME || '/home/runner/harmonyos-sdk/command-line-tools');
const candidates = [
  path.resolve(toolsRoot, 'hvigor/hvigor-ohos-plugin/node_modules/webpack/bin/webpack.js'),
  path.resolve(toolsRoot, 'hvigor/hvigor/node_modules/webpack/bin/webpack.js'),
  path.resolve(toolsRoot, 'hvigor/node_modules/webpack/bin/webpack.js'),
  path.resolve(toolsRoot, 'node_modules/webpack/bin/webpack.js')
];

for (const candidate of candidates) {
  if (candidate !== __filename && fs.existsSync(candidate)) {
    console.error('ComicReader CI using SDK webpack: ' + candidate);
    require(candidate);
    return;
  }
}

if (!fs.existsSync(configPath)) {
  console.error('ComicReader CI skipped webpack because config is missing: ' + configPath);
  ensureOpenHarmonyLoaderOutputs();
  process.exit(0);
}

console.error('ComicReader CI could not find SDK webpack; falling back to npx webpack@5 + webpack-cli@5.');
const npxArgs = ['--yes', '-p', 'webpack@5', '-p', 'webpack-cli@5', 'webpack'].concat(process.argv.slice(2));
const result = childProcess.spawnSync('npx', npxArgs, {
  stdio: 'inherit',
  cwd: root,
  env: process.env
});

if (result.error) {
  console.error('ComicReader CI npx webpack fallback failed: ' + (result.error.stack || result.error.message || result.error));
  process.exit(1);
}
process.exit(typeof result.status === 'number' ? result.status : 1);
`;
}

function makePackageJson() {
  return JSON.stringify({ name: 'webpack', version: '0.0.0-comicreader-ci', bin: { webpack: 'bin/webpack.js' } }, null, 2) + '\n';
}

function linkWebpack() {
  if (!shouldLink()) return;
  const root = process.cwd();
  const webpackBin = path.resolve(root, 'node_modules/webpack/bin/webpack.js');
  const webpackPkg = path.resolve(root, 'node_modules/webpack/package.json');
  writeFileIfChanged(webpackBin, makeWebpackStub());
  writeFileIfChanged(webpackPkg, makePackageJson());
  try { fs.chmodSync(webpackBin, 0o755); } catch (_) {}
  console.log('ComicReader CI prepared project-local webpack entry: ' + webpackBin);
}

linkWebpack();

module.exports = { linkWebpack };
