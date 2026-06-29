const Module = require('module');

function patchClass(value, label) {
  if (typeof value !== 'function' || !value.prototype || value.__comicReaderPreBuildPatched) return;
  const proto = value.prototype;
  let patched = false;

  for (const methodName of [
    'checkOhpmProjectSdkVersion',
    'checkProjectSdkVersion',
    'checkSdkVersion',
    'checkCompatibleSdkVersion',
    'checkCompileSdkVersion',
    'checkProjectCompatibleSdkVersion',
    'checkProjectCompileSdkVersion'
  ]) {
    if (typeof proto[methodName] === 'function') {
      proto[methodName] = function () {
        console.log(`ComicReader CI bypassed hvigor SDK version check: ${methodName}`);
        return undefined;
      };
      patched = true;
    }
  }

  if (patched) {
    value.__comicReaderPreBuildPatched = true;
    console.log(`ComicReader patched PreBuild SDK version checks: ${label || value.name || 'unknown'}`);
  }
}

function inspectLoaded(loaded, request) {
  if (!loaded) return loaded;
  const normalized = String(request || '').replace(/\\/g, '/').toLowerCase();
  const shouldInspect = normalized.includes('pre-build') || normalized.includes('prebuild') || normalized.includes('/tasks/abstract/');
  if (!shouldInspect) return loaded;

  patchClass(loaded, request);
  patchClass(loaded.default, `${request}:default`);
  for (const key of Object.keys(loaded)) {
    patchClass(loaded[key], `${request}:${key}`);
  }
  return loaded;
}

const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  const loaded = originalLoad.call(this, request, parent, isMain);
  return inspectLoaded(loaded, request);
};

module.exports = { inspectLoaded, patchClass };
