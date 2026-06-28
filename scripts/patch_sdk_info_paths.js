const fs = require('fs');
const path = require('path');
const Module = require('module');

const rawSdkRoot = path.resolve(
  process.env.TABSSH_HWSDK_ROOT ||
  process.env.HARMONYOS_SDK_ROOT ||
  process.env.DEVECO_SDK_HOME ||
  'C:/Program Files/Huawei/DevEco Studio/sdk/default'
);

function firstExisting(candidates) {
  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) return candidate;
  }
  return candidates[0];
}

function walkFindDir(root, suffix, maxDepth) {
  const queue = [{ dir: root, depth: 0 }];
  while (queue.length > 0) {
    const item = queue.shift();
    const normalized = item.dir.replace(/\\/g, '/');
    if (normalized.endsWith(suffix) && fs.existsSync(item.dir)) return item.dir;
    if (item.depth >= maxDepth) continue;
    let entries = [];
    try { entries = fs.readdirSync(item.dir, { withFileTypes: true }); } catch (_) { continue; }
    for (const entry of entries) {
      if (entry.isDirectory()) queue.push({ dir: path.resolve(item.dir, entry.name), depth: item.depth + 1 });
    }
  }
  return '';
}

function resolveLayout() {
  const candidates = [
    path.resolve(rawSdkRoot, 'openharmony/native'),
    path.resolve(rawSdkRoot, 'command-line-tools/sdk/default/openharmony/native'),
    path.resolve(rawSdkRoot, 'sdk/default/openharmony/native')
  ];
  const nativeDir = firstExisting(candidates.concat([walkFindDir(rawSdkRoot, '/sdk/default/openharmony/native', 8)]).filter(Boolean));
  const openharmonyRoot = nativeDir.endsWith(path.normalize('openharmony/native'))
    ? path.dirname(nativeDir)
    : firstExisting([
      path.resolve(rawSdkRoot, 'openharmony'),
      path.resolve(rawSdkRoot, 'command-line-tools/sdk/default/openharmony'),
      path.resolve(rawSdkRoot, 'sdk/default/openharmony')
    ]);
  const sdkRoot = openharmonyRoot.endsWith('openharmony') ? path.dirname(openharmonyRoot) : rawSdkRoot;
  return { sdkRoot, openharmonyRoot, nativeDir };
}

const layout = resolveLayout();
const sdkRoot = layout.sdkRoot;
const openharmonyRoot = layout.openharmonyRoot;
const nativeDirFromLayout = layout.nativeDir;
const hmsRoot = firstExisting([
  path.resolve(sdkRoot, 'hms'),
  path.resolve(rawSdkRoot, 'hms'),
  path.resolve(rawSdkRoot, 'command-line-tools/sdk/default/hms')
]);

function numericVersion(other) {
  if (typeof other === 'number') return other;
  if (typeof other === 'string') return Number.parseInt(other.replace(/.*\((\d+)\).*/, '$1'), 10) || Number.parseInt(other, 10) || 0;
  if (other && typeof other.getValue === 'function') return numericVersion(other.getValue());
  if (other && typeof other.getMajor === 'function') return numericVersion(other.getMajor());
  if (other && typeof other.getApiVersion === 'function') return numericVersion(other.getApiVersion());
  if (other && typeof other.valueOf === 'function') {
    const v = other.valueOf();
    if (v !== other) return numericVersion(v);
  }
  return 0;
}

function apiVersion(value) {
  return {
    major: value,
    value,
    apiVersion: value,
    getMajor: () => value,
    getValue: () => value,
    getApiVersion: () => value,
    equals: (other) => numericVersion(other) === value,
    compareTo: (other) => value - numericVersion(other),
    greaterThan: (other) => value > numericVersion(other),
    greaterThanOrEquals: (other) => value >= numericVersion(other),
    lessThan: (other) => value < numericVersion(other),
    lessThanOrEquals: (other) => value <= numericVersion(other),
    isGreaterThan: (other) => value > numericVersion(other),
    isGreaterThanOrEquals: (other) => value >= numericVersion(other),
    isLessThan: (other) => value < numericVersion(other),
    isLessThanOrEquals: (other) => value <= numericVersion(other),
    toString: () => `6.1.1(${value})`,
    valueOf: () => value
  };
}

function toolPath(toolchainsDir, names) {
  const candidates = [];
  for (const name of names) {
    candidates.push(path.resolve(toolchainsDir, name));
    candidates.push(path.resolve(openharmonyRoot, 'toolchains', name));
    candidates.push(path.resolve(nativeDirFromLayout, 'build-tools/cmake/bin', name));
    candidates.push(path.resolve(nativeDirFromLayout, 'llvm/bin', name));
    candidates.push(path.resolve(hmsRoot, 'native/build-tools/cmake/bin', name));
    candidates.push(path.resolve(hmsRoot, 'native/llvm/bin', name));
  }
  return firstExisting(candidates);
}

function patchInfoClass(value, label) {
  if (typeof value !== 'function' || !value.prototype) return;
  const proto = value.prototype;
  const nativeDir = firstExisting([nativeDirFromLayout, path.resolve(openharmonyRoot, 'native'), path.resolve(hmsRoot, 'native')]);
  const toolchainsDir = firstExisting([
    path.resolve(openharmonyRoot, 'toolchains'),
    path.resolve(hmsRoot, 'toolchains'),
    path.resolve(rawSdkRoot, 'command-line-tools/sdk/default/openharmony/toolchains')
  ]);
  const etsDir = firstExisting([path.resolve(openharmonyRoot, 'ets'), path.resolve(hmsRoot, 'ets')]);
  const ninjaTool = toolPath(toolchainsDir, ['ninja', 'ninja.exe']);
  const cmakeTool = toolPath(toolchainsDir, ['cmake', 'cmake.exe']);
  const makeTool = toolPath(toolchainsDir, ['make', 'make.exe']);
  const v24 = apiVersion(24);

  proto.contains = function () { return true; };
  proto.getBaseDir = function () { return openharmonyRoot; };
  proto.getLocation = function () { return openharmonyRoot; };
  proto.getSdkRoot = function () { return sdkRoot; };
  proto.getSdkDir = function () { return openharmonyRoot; };
  proto.getSdkNativeDir = function () { return nativeDir; };
  proto.getNativeDir = function () { return nativeDir; };
  proto.getSdkToolchainsDir = function () { return toolchainsDir; };
  proto.getToolchainsDir = function () { return toolchainsDir; };
  proto.getSdkEtsDir = function () { return etsDir; };
  proto.getEtsDir = function () { return etsDir; };
  proto.getNativeNinjaTool = function () { return ninjaTool; };
  proto.getNinjaTool = function () { return ninjaTool; };
  proto.getNativeCmakeTool = function () { return cmakeTool; };
  proto.getCmakeTool = function () { return cmakeTool; };
  proto.getNativeMakeTool = function () { return makeTool; };
  proto.getMakeTool = function () { return makeTool; };
  proto.getApiVersion = function () { return v24; };
  proto.getFullApiVersion = function () { return v24; };
  proto.getVersion = function () { return '6.1.1.125'; };
  proto.getReleaseType = function () { return 'Release'; };
  proto.getCompatibleSdkVersion = function () { return v24; };
  proto.getCompileSdkVersion = function () { return v24; };
  proto.getTargetSdkVersion = function () { return v24; };
  value.__comicReaderSdkInfoPathsPatched = true;
  console.log(`ComicReader SDK layout raw=${rawSdkRoot} sdk=${sdkRoot} ohos=${openharmonyRoot} native=${nativeDir}`);
  console.log(`ComicReader patched SDK info paths/tools/version: ${label || value.name || 'unknown'}`);
}

function patchLoaded(loaded, request) {
  if (!loaded) return loaded;
  const normalized = String(request || '').replace(/\\/g, '/').toLowerCase();
  if (!normalized.includes('sdk-info') && !normalized.includes('/sdk/info/')) return loaded;
  patchInfoClass(loaded, request);
  patchInfoClass(loaded.default, `${request}:default`);
  patchInfoClass(loaded.OhosSdkInfo, `${request}:OhosSdkInfo`);
  patchInfoClass(loaded.HmosSdkInfo, `${request}:HmosSdkInfo`);
  patchInfoClass(loaded.HmsSdkInfo, `${request}:HmsSdkInfo`);
  patchInfoClass(loaded.HosSdkInfo, `${request}:HosSdkInfo`);
  return loaded;
}

const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  const loaded = originalLoad.call(this, request, parent, isMain);
  return patchLoaded(loaded, request);
};

module.exports = { patchLoaded, patchInfoClass };
