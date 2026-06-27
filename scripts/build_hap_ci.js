const path = require('path');
const { createRequire } = require('module');

const toolsRoot = path.resolve(process.env.DEVECO_TOOLS_ROOT || process.env.DEVECO_TOOLS_HOME || 'C:/Program Files/Huawei/DevEco Studio/tools');
const sdkRoot = path.resolve(process.env.TABSSH_HWSDK_ROOT || process.env.HARMONYOS_SDK_ROOT || process.env.DEVECO_SDK_HOME || 'C:/Program Files/Huawei/DevEco Studio/sdk/default');
const hvigorRoot = path.resolve(toolsRoot, 'hvigor');
const hvigorEntry = path.resolve(hvigorRoot, 'bin/hvigorw.js');
const hvigorRequire = createRequire(hvigorEntry);

function apiVersion(value) {
  function numberOf(other) {
    if (typeof other === 'number') return other;
    if (typeof other === 'string') return Number.parseInt(other, 10) || 0;
    if (other && typeof other.getValue === 'function') return numberOf(other.getValue());
    if (other && typeof other.getMajor === 'function') return numberOf(other.getMajor());
    if (other && typeof other.valueOf === 'function') {
      const v = other.valueOf();
      if (v !== other) return numberOf(v);
    }
    return 0;
  }
  return {
    getMajor: () => value,
    getValue: () => value,
    equals: (other) => numberOf(other) === value,
    compareTo: (other) => value - numberOf(other),
    greaterThan: (other) => value > numberOf(other),
    greaterThanOrEquals: (other) => value >= numberOf(other),
    lessThan: (other) => value < numberOf(other),
    lessThanOrEquals: (other) => value <= numberOf(other),
    toString: () => String(value),
    valueOf: () => value
  };
}

function safeComponentName(value) {
  if (value == null) return 'unknown';
  if (typeof value === 'string') return value;
  if (typeof value.getPath === 'function') return value.getPath();
  if (typeof value.getName === 'function') return value.getName();
  if (value.path) return value.path;
  if (value.name) return value.name;
  return String(value);
}

function installUniversalSdkComponentCompat() {
  const api = apiVersion(24);
  const methods = {
    getPath() { return safeComponentName(this); },
    getName() { return safeComponentName(this); },
    getLocation() { return path.resolve(sdkRoot, 'openharmony', safeComponentName(this)); },
    getVersion() { return '6.1.1.125'; },
    getReleaseType() { return 'Release'; },
    getFullApiVersion() { return api; },
    getApiVersion() { return api; },
    equals(other) { return safeComponentName(this) === safeComponentName(other); },
    compareTo(other) { return safeComponentName(this).localeCompare(safeComponentName(other)); }
  };

  for (const proto of [String.prototype, Object.prototype]) {
    for (const [name, fn] of Object.entries(methods)) {
      if (typeof proto[name] !== 'function') {
        Object.defineProperty(proto, name, {
          value: fn,
          configurable: true,
          writable: true,
          enumerable: false
        });
      }
    }
  }
}

installUniversalSdkComponentCompat();
require('./run_hvigor_with_sdk_patch.js');

function resolveProductName() {
  const explicitProduct = String(process.env.BUILD_PRODUCT || '').trim();
  if (explicitProduct.length > 0) return explicitProduct;
  return process.env.BUILD_PLATFORM === 'openharmony' ? 'openharmony_verify' : 'default';
}

function ensureSelfPreload() {
  const preload = `--require=${__filename}`;
  if (!process.env.NODE_OPTIONS || !process.env.NODE_OPTIONS.includes(__filename)) {
    process.env.NODE_OPTIONS = process.env.NODE_OPTIONS ? `${preload} ${process.env.NODE_OPTIONS}` : preload;
  }
}

if (require.main === module) {
  ensureSelfPreload();
  const tasks = process.argv.slice(2);
  const productName = resolveProductName();
  const moduleTarget = productName === 'default' ? 'entry@default' : `entry@${productName}`;
  process.argv = [
    process.argv[0],
    hvigorEntry,
    '--no-daemon',
    '--stacktrace',
    '--mode', 'module',
    '-p', `product=${productName}`,
    '-p', `module=${moduleTarget}`,
    '-p', 'pageType=page',
    '-p', 'compileResInc=true',
    ...(tasks.length > 0 ? tasks : ['assembleHap'])
  ];
  console.log(`ComicReader CI build product=${productName} module=${moduleTarget}`);
  hvigorRequire(hvigorEntry);
}
