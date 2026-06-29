const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const VERSION_FILE = path.resolve(ROOT, 'version.json');
const BUILD_INFO_FILE = path.resolve(ROOT, 'entry/src/main/ets/common/BuildInfo.ets');
const APP_JSON_FILE = path.resolve(ROOT, 'AppScope/app.json5');
const ROOT_PACKAGE_FILE = path.resolve(ROOT, 'oh-package.json5');
const ENTRY_PACKAGE_FILE = path.resolve(ROOT, 'entry/oh-package.json5');

function readText(file) {
  return fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
}

function writeText(file, content) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, content);
}

function defaultState() {
  return {
    major: 0,
    full: 0,
    incremental: 0,
    buildType: 'ci',
    buildTime: new Date(0).toISOString()
  };
}

function normalizeNumber(value, fallback) {
  const parsed = Number.parseInt(String(value), 10);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : fallback;
}

function readVersionState() {
  const base = defaultState();
  if (!fs.existsSync(VERSION_FILE)) return base;
  try {
    const parsed = JSON.parse(fs.readFileSync(VERSION_FILE, 'utf8'));
    return {
      major: normalizeNumber(parsed.major, base.major),
      full: normalizeNumber(parsed.full, base.full),
      incremental: normalizeNumber(parsed.incremental, base.incremental),
      buildType: typeof parsed.buildType === 'string' ? parsed.buildType : base.buildType,
      buildTime: typeof parsed.buildTime === 'string' ? parsed.buildTime : base.buildTime
    };
  } catch (error) {
    console.warn('Could not parse version.json, using default version state.');
    return base;
  }
}

function versionName(state) {
  return `${state.major}.${state.full}.${state.incremental}`;
}

function versionCode(state) {
  const code = state.major * 1000000 + state.full * 1000 + state.incremental;
  return code > 0 ? code : 1;
}

function writeVersionState(state) {
  const content = JSON.stringify({
    major: state.major,
    full: state.full,
    incremental: state.incremental,
    buildType: state.buildType,
    buildTime: state.buildTime
  }, null, 2) + '\n';
  writeText(VERSION_FILE, content);
}

function writeBuildInfo(state, target) {
  const content = `export const APP_VERSION_MAJOR: number = ${state.major};\n` +
    `export const APP_FULL_BUILD_NUMBER: number = ${state.full};\n` +
    `export const APP_INCREMENTAL_BUILD_NUMBER: number = ${state.incremental};\n` +
    `export const APP_VERSION_CODE: number = ${versionCode(state)};\n` +
    `export const APP_VERSION: string = '${versionName(state)}';\n` +
    `export const APP_BUILD_TYPE: string = '${state.buildType}';\n` +
    `export const APP_BUILD_TIME: string = '${state.buildTime}';\n` +
    `export const APP_BUILD_TARGET: string = '${target || 'source'}';\n`;
  writeText(BUILD_INFO_FILE, content);
}

function replaceJsonValue(text, key, value) {
  const escaped = String(value).replace(/\\/g, '\\\\').replace(/'/g, "\\'");
  const doubleRegex = new RegExp(`("${key}"\\s*:\\s*)"[^"]*"`);
  const singleRegex = new RegExp(`("${key}"\\s*:\\s*)'[^']*'`);
  if (doubleRegex.test(text)) return text.replace(doubleRegex, `$1"${escaped}"`);
  if (singleRegex.test(text)) return text.replace(singleRegex, `$1'${escaped}'`);
  return text;
}

function replaceJsonNumber(text, key, value) {
  const regex = new RegExp(`("${key}"\\s*:\\s*)\\d+`);
  return text.replace(regex, `$1${value}`);
}

function updatePackageVersions(state) {
  const name = versionName(state);
  const code = versionCode(state);

  if (fs.existsSync(APP_JSON_FILE)) {
    let text = readText(APP_JSON_FILE);
    text = replaceJsonNumber(text, 'versionCode', code);
    text = replaceJsonValue(text, 'versionName', name);
    writeText(APP_JSON_FILE, text);
  }

  for (const file of [ROOT_PACKAGE_FILE, ENTRY_PACKAGE_FILE]) {
    if (!fs.existsSync(file)) continue;
    let text = readText(file);
    text = replaceJsonValue(text, 'version', name);
    writeText(file, text);
  }
}

function applyArgs(state, args) {
  let mode = 'none';
  let buildType = process.env.BUILD_PACKAGE_SUFFIX || 'ci';
  let target = process.env.BUILD_PACKAGE_SUFFIX || process.env.BUILD_PRODUCT || 'source';

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === '--full') {
      mode = 'full';
      buildType = 'full';
    } else if (arg === '--incremental') {
      mode = 'incremental';
      buildType = 'incremental';
    } else if (arg === '--no-bump') {
      mode = 'none';
    } else if (arg === '--major') {
      state.major = normalizeNumber(args[i + 1], state.major);
      i++;
    } else if (arg.startsWith('--major=')) {
      state.major = normalizeNumber(arg.slice('--major='.length), state.major);
    } else if (arg === '--build-type') {
      buildType = args[i + 1] || buildType;
      i++;
    } else if (arg.startsWith('--build-type=')) {
      buildType = arg.slice('--build-type='.length) || buildType;
    } else if (arg === '--target') {
      target = args[i + 1] || target;
      i++;
    } else if (arg.startsWith('--target=')) {
      target = arg.slice('--target='.length) || target;
    }
  }

  if (mode === 'full') {
    state.full += 1;
    state.incremental = 0;
  } else if (mode === 'incremental') {
    state.incremental += 1;
  }

  state.buildType = buildType;
  state.buildTime = new Date().toISOString();
  return { state, mode, target };
}

function writeCurrentBuildInfo(options) {
  const state = readVersionState();
  state.buildType = (options && options.buildType) || process.env.BUILD_PACKAGE_SUFFIX || state.buildType || 'ci';
  state.buildTime = new Date().toISOString();
  const target = (options && options.target) || process.env.BUILD_PACKAGE_SUFFIX || process.env.BUILD_PRODUCT || 'source';
  writeVersionState(state);
  writeBuildInfo(state, target);
  updatePackageVersions(state);
  return state;
}

function main() {
  const current = readVersionState();
  const result = applyArgs(current, process.argv.slice(2));
  writeVersionState(result.state);
  writeBuildInfo(result.state, result.target);
  updatePackageVersions(result.state);
  console.log(`ComicReader version ${versionName(result.state)} code ${versionCode(result.state)} mode=${result.mode} target=${result.target}`);
}

if (require.main === module) {
  main();
}

module.exports = {
  readVersionState,
  writeCurrentBuildInfo,
  versionName,
  versionCode
};
