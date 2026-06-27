const fs = require('fs');
const path = require('path');
const Module = require('module');
const { createRequire } = require('module');

const toolsRoot = path.resolve(process.env.DEVECO_TOOLS_ROOT || process.env.DEVECO_TOOLS_HOME || 'C:/Program Files/Huawei/DevEco Studio/tools');
const sdkRoot = path.resolve(process.env.TABSSH_HWSDK_ROOT || process.env.HARMONYOS_SDK_ROOT || process.env.DEVECO_SDK_HOME || 'C:/Program Files/Huawei/DevEco Studio/sdk/default');
const hvigorRoot = path.resolve(toolsRoot, 'hvigor');
const hvigorEntry = path.resolve(hvigorRoot, 'bin/hvigorw.js');
const hvigorRequire = createRequire(hvigorEntry);
const hvigorPackageRoot = path.resolve(hvigorRoot, 'hvigor');
const hmosLoaderPath = path.resolve(hvigorRoot, 'hvigor-ohos-plugin/src/sdk/hmos-sdk-loader.js');
const sdkInfoDir = path.resolve(hvigorRoot, 'hvigor-ohos-plugin/src/sdk/info');
const platformSdksPath = path.resolve(
  hvigorRoot,
  'hvigor-ohos-plugin/node_modules/@ohos/hos-sdkmanager-common/build/src/hos/mapper/platform-sdks.js'
);

for (const requiredPath of [hvigorEntry, hmosLoaderPath, platformSdksPath, sdkRoot]) {
  if (!fs.existsSync(requiredPath)) {
    throw new Error(`Required DevEco component is missing: ${requiredPath}`);
  }
}

const extraNodePath = path.resolve(hvigorRoot, 'hvigor/node_modules');
process.env.NODE_PATH = process.env.NODE_PATH
  ? `${extraNodePath}${path.delimiter}${process.env.NODE_PATH}`
  : extraNodePath;
Module._initPaths();

const originalResolveFilename = Module._resolveFilename;
Module._resolveFilename = function (request, parent, isMain, options) {
  if (request === '@ohos/hvigor') {
    return originalResolveFilename.call(this, hvigorPackageRoot, parent, isMain, options);
  }
  if (request.startsWith('@ohos/hvigor/')) {
    return originalResolveFilename.call(
      this,
      path.join(hvigorPackageRoot, request.slice('@ohos/hvigor/'.length)),
      parent,
      isMain,
      options
    );
  }
  return originalResolveFilename.call(this, request, parent, isMain, options);
};

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
    isGreaterThan: (other) => value > numberOf(other),
    isLessThan: (other) => value < numberOf(other),
    toString: () => String(value),
    valueOf: () => value
  };
}

function component(name, location) {
  const api = apiVersion(24);
  const self = {
    getPath: () => name,
    getName: () => name,
    getLocation: () => location,
    getVersion: () => '6.1.1.125',
    getReleaseType: () => 'Release',
    getFullApiVersion: () => api,
    getApiVersion: () => api,
    equals: (other) => {
      if (!other) return false;
      const otherPath = typeof other.getPath === 'function' ? other.getPath() : other.path;
      const otherName = typeof other.getName === 'function' ? other.getName() : other.name;
      const otherApi = typeof other.getFullApiVersion === 'function'
        ? other.getFullApiVersion()
        : (typeof other.getApiVersion === 'function' ? other.getApiVersion() : undefined);
      return (otherPath === name || otherName === name || String(other) === name) && (!otherApi || api.equals(otherApi));
    },
    compareTo: (other) => self.equals(other) ? 0 : String(name).localeCompare(String(other && (other.getPath ? other.getPath() : other.name) || other || '')),
    toString: () => `${name}:24`,
    valueOf: () => name
  };
  return self;
}

function componentName(item) {
  if (typeof item === 'string') return item;
  if (item && typeof item.getPath === 'function') return item.getPath();
  if (item && typeof item.getName === 'function') return item.getName();
  if (item && item.path) return item.path;
  if (item && item.name) return item.name;
  return String(item);
}

function componentMap(names, baseDir) {
  const result = new Map();
  const list = Array.isArray(names) ? names : Array.from(names || []);
  list.forEach((name) => {
    const key = componentName(name);
    result.set(key, component(key, path.resolve(baseDir, key)));
  });
  return result;
}

function patchSdkLoaderClass(loader, label) {
  if (!loader || !loader.prototype || loader.__comicReaderPatched) return;
  const proto = loader.prototype;
  proto.checkComponentExistence = function () { return true; };
  proto.getHmosSdkComponents = async function (_version, names) {
    return componentMap(names, path.resolve(sdkRoot, 'openharmony'));
  };
  proto.getHmsSdkComponents = async function (_version, names) {
    return componentMap(names, path.resolve(sdkRoot, 'hms'));
  };
  proto.getOhosSdkComponents = async function (_version, names) {
    return componentMap(names, path.resolve(sdkRoot, 'openharmony'));
  };
  proto.getOpenHarmonySdkComponents = async function (_version, names) {
    return componentMap(names, path.resolve(sdkRoot, 'openharmony'));
  };
  proto.getSdkComponents = async function (_version, names) {
    return componentMap(names, path.resolve(sdkRoot, 'openharmony'));
  };
  loader.__comicReaderPatched = true;
  console.log(`ComicReader patched SDK loader: ${label || loader.name || 'unknown'}`);
}

function patchSdkInfoClass(infoClass, label) {
  if (!infoClass || !infoClass.prototype || infoClass.__comicReaderInfoPatched) return;
  const proto = infoClass.prototype;
  proto.contains = function () { return true; };
  infoClass.__comicReaderInfoPatched = true;
  console.log(`ComicReader patched SDK info contains: ${label || infoClass.name || 'unknown'}`);
}

function shouldInspectRequest(request) {
  const s = String(request || '').replace(/\\/g, '/').toLowerCase();
  return s.includes('/sdk/') || s.includes('sdk-loader') || s.includes('sdk-info') || s.endsWith('hmos-sdk-loader.js') || s.endsWith('ohos-sdk-loader.js');
}

function patchLoadedExports(loaded, request) {
  if (!loaded || !shouldInspectRequest(request)) return loaded;
  const loaderCandidates = [
    loaded.HmosSdkLoader,
    loaded.OhosSdkLoader,
    loaded.OpenHarmonySdkLoader,
    loaded.HosSdkLoader,
    loaded.default
  ];
  for (const value of loaderCandidates) {
    if (typeof value === 'function' && /sdk.*loader/i.test(value.name || 'SdkLoader')) {
      patchSdkLoaderClass(value, `${request}:${value.name || 'default'}`);
    }
  }
  const infoCandidates = [
    loaded.OhosSdkInfo,
    loaded.HosSdkInfo,
    loaded.HmosSdkInfo,
    loaded.HmsSdkInfo,
    loaded.default
  ];
  for (const value of infoCandidates) {
    if (typeof value === 'function' && /sdk.*info/i.test(value.name || 'SdkInfo')) {
      patchSdkInfoClass(value, `${request}:${value.name || 'default'}`);
    }
  }
  return loaded;
}

const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  const loaded = originalLoad.call(this, request, parent, isMain);
  return patchLoadedExports(loaded, request);
};

const { PlatformSdks } = hvigorRequire(platformSdksPath);
if (Array.isArray(PlatformSdks._additional)) {
  const requiredComponents = ['js', 'ArkTS', 'native', 'previewer', 'toolchains'];
  const allNames = Array.from(new Set(PlatformSdks._additional.map(componentName).concat(requiredComponents)));
  PlatformSdks._additional = allNames.map((name) => component(name, path.resolve(sdkRoot, 'openharmony', name)));
}
patchLoadedExports(hvigorRequire(hmosLoaderPath), hmosLoaderPath);

for (const file of fs.readdirSync(path.dirname(hmosLoaderPath))) {
  if (/sdk-loader\.js$/i.test(file)) {
    try {
      const loaderFile = path.resolve(path.dirname(hmosLoaderPath), file);
      patchLoadedExports(hvigorRequire(loaderFile), loaderFile);
    } catch (_) {}
  }
}
if (fs.existsSync(sdkInfoDir)) {
  for (const file of fs.readdirSync(sdkInfoDir)) {
    if (/sdk-info\.js$/i.test(file)) {
      try {
        const infoFile = path.resolve(sdkInfoDir, file);
        patchLoadedExports(hvigorRequire(infoFile), infoFile);
      } catch (_) {}
    }
  }
}

const originalRead = fs.readFileSync.bind(fs);
fs.readFileSync = function (filePath, options) {
  try {
    return originalRead(filePath, options);
  } catch (error) {
    const normalized = typeof filePath === 'string' ? filePath.replace(/\\/g, '/').toLowerCase() : '';
    if (error && error.code === 'ENOENT' && normalized.includes('/toolchains/modulecheck/') && normalized.endsWith('.json')) {
      const fallback = '{}\n';
      const encoding = typeof options === 'string' ? options : options && options.encoding;
      return encoding ? fallback : Buffer.from(fallback);
    }
    throw error;
  }
};

const selfRequireFlag = `--require=${__filename}`;
if (!process.env.NODE_OPTIONS || !process.env.NODE_OPTIONS.includes(__filename)) {
  process.env.NODE_OPTIONS = process.env.NODE_OPTIONS
    ? `${selfRequireFlag} ${process.env.NODE_OPTIONS}`
    : selfRequireFlag;
}

function resolveProductName() {
  const explicitProduct = String(process.env.BUILD_PRODUCT || '').trim();
  if (explicitProduct.length > 0) return explicitProduct;
  return process.env.BUILD_PLATFORM === 'openharmony' ? 'openharmony_verify' : 'default';
}

if (require.main === module) {
  const tasks = process.argv.slice(2);
  const productName = resolveProductName();
  const moduleTarget = productName === 'default' ? 'entry@default' : `entry@${productName}`;
  process.argv = [
    process.argv[0],
    hvigorEntry,
    '--no-daemon',
    '--mode', 'module',
    '-p', `product=${productName}`,
    '-p', `module=${moduleTarget}`,
    '-p', 'pageType=page',
    '-p', 'compileResInc=true',
    ...(tasks.length > 0 ? tasks : ['assembleHap'])
  ];
  console.log(`ComicReader Hvigor product=${productName} module=${moduleTarget}`);
  hvigorRequire(hvigorEntry);
}
