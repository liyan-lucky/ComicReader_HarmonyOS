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
  return {
    getMajor: () => value,
    getValue: () => value,
    toString: () => String(value),
    valueOf: () => value
  };
}

function component(name, location) {
  return {
    getPath: () => name,
    getName: () => name,
    getLocation: () => location,
    getVersion: () => '6.1.1.125',
    getReleaseType: () => 'Release',
    getFullApiVersion: () => apiVersion(24),
    getApiVersion: () => apiVersion(24)
  };
}

function componentMap(names, baseDir) {
  const result = new Map();
  const list = Array.isArray(names) ? names : Array.from(names || []);
  list.forEach((name) => result.set(name, component(name, path.resolve(baseDir, name))));
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

function patchLoadedExports(loaded, request) {
  if (!loaded) return loaded;
  for (const value of Object.values(loaded)) {
    if (typeof value === 'function' && /sdk.*loader/i.test(value.name || '')) {
      patchSdkLoaderClass(value, `${request}:${value.name}`);
    }
  }
  if (loaded.HmosSdkLoader) patchSdkLoaderClass(loaded.HmosSdkLoader, `${request}:HmosSdkLoader`);
  if (loaded.OhosSdkLoader) patchSdkLoaderClass(loaded.OhosSdkLoader, `${request}:OhosSdkLoader`);
  if (loaded.OpenHarmonySdkLoader) patchSdkLoaderClass(loaded.OpenHarmonySdkLoader, `${request}:OpenHarmonySdkLoader`);
  return loaded;
}

const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  const loaded = originalLoad.call(this, request, parent, isMain);
  return patchLoadedExports(loaded, request);
};

const { PlatformSdks } = hvigorRequire(platformSdksPath);
if (Array.isArray(PlatformSdks._additional)) {
  for (const name of ['js', 'ArkTS', 'native', 'previewer', 'toolchains']) {
    if (!PlatformSdks._additional.includes(name)) {
      PlatformSdks._additional = PlatformSdks._additional.concat(name);
    }
  }
}
patchLoadedExports(hvigorRequire(hmosLoaderPath), hmosLoaderPath);

// 预加载并补丁 SDK 目录下所有 loader，避免 OpenHarmony/HarmonyOS 分支走不同类。
for (const file of fs.readdirSync(path.dirname(hmosLoaderPath))) {
  if (/sdk-loader\.js$/i.test(file)) {
    try {
      patchLoadedExports(hvigorRequire(path.resolve(path.dirname(hmosLoaderPath), file)), file);
    } catch (_) {}
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
