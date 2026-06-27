const path = require('path');
const { createRequire } = require('module');

const toolsRoot = path.resolve(process.env.DEVECO_TOOLS_ROOT || process.env.DEVECO_TOOLS_HOME || 'C:/Program Files/Huawei/DevEco Studio/tools');
const sdkRoot = path.resolve(process.env.TABSSH_HWSDK_ROOT || process.env.HARMONYOS_SDK_ROOT || process.env.DEVECO_SDK_HOME || 'C:/Program Files/Huawei/DevEco Studio/sdk/default');
const hvigorRoot = path.resolve(toolsRoot, 'hvigor');
const hvigorEntry = path.resolve(hvigorRoot, 'bin/hvigorw.js');
const hvigorRequire = createRequire(hvigorEntry);

function primitiveName(value) {
  if (value == null) return 'unknown';
  if (typeof value === 'string') return value;
  if (typeof value === 'number' || typeof value === 'boolean' || typeof value === 'bigint') return String(value);
  if (value instanceof String || value instanceof Number || value instanceof Boolean) return String(value.valueOf());
  return undefined;
}

function apiVersion(value) {
  function numberOf(other) {
    const primitive = primitiveName(other);
    if (primitive !== undefined) return Number.parseInt(primitive, 10) || 0;
    if (other && Object.prototype.hasOwnProperty.call(other, 'getValue') && typeof other.getValue === 'function') return numberOf(other.getValue());
    if (other && Object.prototype.hasOwnProperty.call(other, 'getMajor') && typeof other.getMajor === 'function') return numberOf(other.getMajor());
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
  const primitive = primitiveName(value);
  if (primitive !== undefined) return primitive;
  if (value && Object.prototype.hasOwnProperty.call(value, 'path')) return value.path;
  if (value && Object.prototype.hasOwnProperty.call(value, 'name')) return value.name;
  if (value && Object.prototype.hasOwnProperty.call(value, 'getPath') && typeof value.getPath === 'function') return value.getPath();
  if (value && Object.prototype.hasOwnProperty.call(value, 'getName') && typeof value.getName === 'function') return value.getName();
  return Object.prototype.toString.call(value);
}

function installPrimitiveSdkComponentCompat() {
  const api = apiVersion(24);
  const methods = {
    getPath() { return String(this.valueOf()); },
    getName() { return String(this.valueOf()); },
    getLocation() { return path.resolve(sdkRoot, 'openharmony', String(this.valueOf())); },
    getVersion() { return '6.1.1.125'; },
    getReleaseType() { return 'Release'; },
    getFullApiVersion() { return api; },
    getApiVersion() { return api; },
    equals(other) { return String(this.valueOf()) === safeComponentName(other); },
    compareTo(other) { return String(this.valueOf()).localeCompare(safeComponentName(other)); }
  };

  for (const proto of [String.prototype, Number.prototype, Boolean.prototype]) {
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

installPrimitiveSdkComponentCompat();
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
