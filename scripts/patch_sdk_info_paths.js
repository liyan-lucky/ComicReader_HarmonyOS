const fs = require('fs');
const path = require('path');
const Module = require('module');

const sdkRoot = path.resolve(
  process.env.TABSSH_HWSDK_ROOT ||
  process.env.HARMONYOS_SDK_ROOT ||
  process.env.DEVECO_SDK_HOME ||
  'C:/Program Files/Huawei/DevEco Studio/sdk/default'
);
const openharmonyRoot = path.resolve(sdkRoot, 'openharmony');
const hmsRoot = path.resolve(sdkRoot, 'hms');

function firstExisting(candidates) {
  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) return candidate;
  }
  return candidates[0];
}

function numericVersion(other) {
  if (typeof other === 'number') return other;
  if (typeof other === 'string') return Number.parseInt(other, 10) || 0;
  if (other && typeof other.getValue === 'function') return numericVersion(other.getValue());
  if (other && typeof other.getMajor === 'function') return numericVersion(other.getMajor());
  return 0;
}

function apiVersion(value) {
  return {
    getMajor: () => value,
    getValue: () => value,
    equals: (other) => numericVersion(other) === value,
    compareTo: (other) => value - numericVersion(other),
    greaterThan: (other) => value > numericVersion(other),
    greaterThanOrEquals: (other) => value >= numericVersion(other),
    lessThan: (other) => value < numericVersion(other),
    lessThanOrEquals: (other) => value <= numericVersion(other),
    isGreaterThan: (other) => value > numericVersion(other),
    isLessThan: (other) => value < numericVersion(other),
    toString: () => String(value),
    valueOf: () => value
  };
}

function patchInfoClass(value, label) {
  if (typeof value !== 'function' || !value.prototype || value.__comicReaderSdkInfoPathsPatched) return;
  const proto = value.prototype;
  const nativeDir = firstExisting([
    path.resolve(openharmonyRoot, 'native'),
    path.resolve(hmsRoot, 'native')
  ]);
  const toolchainsDir = firstExisting([
    path.resolve(openharmonyRoot, 'toolchains'),
    path.resolve(hmsRoot, 'toolchains')
  ]);
  const etsDir = firstExisting([
    path.resolve(openharmonyRoot, 'ets'),
    path.resolve(hmsRoot, 'ets')
  ]);

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
  proto.getApiVersion = function () { return apiVersion(24); };
  proto.getFullApiVersion = function () { return apiVersion(24); };
  value.__comicReaderSdkInfoPathsPatched = true;
  console.log(`ComicReader patched SDK info paths: ${label || value.name || 'unknown'}`);
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
