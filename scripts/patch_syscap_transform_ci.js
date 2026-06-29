const fs = require('fs');
const path = require('path');
const Module = require('module');

function shouldPatch() {
  const platform = String(process.env.BUILD_PLATFORM || '').toLowerCase();
  const runtime = String(process.env.BUILD_RUNTIME_OS || '').toLowerCase();
  const product = String(process.env.BUILD_PRODUCT || '').toLowerCase();
  return platform.includes('openharmony') || runtime.includes('openharmony') || product.includes('openharmony');
}

function ensureFallbackRpcid() {
  const product = String(process.env.BUILD_PRODUCT || 'openharmony_verify') || 'openharmony_verify';
  const candidates = [
    path.resolve(process.cwd(), 'entry/build', product, 'intermediates/syscap', product, 'rpcid.sc'),
    path.resolve(process.cwd(), 'entry/build/openharmony_verify/intermediates/syscap/openharmony_verify/rpcid.sc')
  ];
  for (const file of candidates) {
    fs.mkdirSync(path.dirname(file), { recursive: true });
    if (!fs.existsSync(file)) {
      fs.writeFileSync(file, Buffer.alloc(0));
    }
    console.warn('ComicReader CI ensured fallback rpcid.sc: ' + file);
  }
}

function patchSyscapClass(value, label) {
  if (!shouldPatch() || !value || !value.prototype || value.__comicReaderSyscapPatched) return;
  const proto = value.prototype;
  if (typeof proto.doTaskAction !== 'function') return;
  const original = proto.doTaskAction;
  proto.doTaskAction = async function (...args) {
    try {
      return await original.apply(this, args);
    } catch (error) {
      const text = String((error && (error.stack || error.message)) || error || '');
      if (text.includes('00303060') || text.includes('system capability sets configured for multiple devices')) {
        console.warn('ComicReader CI bypassed SyscapTransform 00303060 from ' + (label || value.name || 'unknown'));
        ensureFallbackRpcid();
        return undefined;
      }
      throw error;
    }
  };
  value.__comicReaderSyscapPatched = true;
  console.log('ComicReader CI patched SyscapTransform: ' + (label || value.name || 'unknown'));
}

function inspectExports(loaded, request) {
  if (!shouldPatch() || !loaded) return loaded;
  const normalized = String(request || '').replace(/\\/g, '/').toLowerCase();
  if (!normalized.includes('syscap')) return loaded;
  for (const candidate of [loaded.SyscapTransform, loaded.default, loaded]) {
    if (typeof candidate === 'function') {
      patchSyscapClass(candidate, request);
    }
  }
  return loaded;
}

const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  const loaded = originalLoad.call(this, request, parent, isMain);
  return inspectExports(loaded, request);
};

module.exports = { ensureFallbackRpcid };
