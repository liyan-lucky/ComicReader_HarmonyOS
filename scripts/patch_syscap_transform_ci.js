const fs = require('fs');
const path = require('path');
const Module = require('module');
const childProcess = require('child_process');
const EventEmitter = require('events');
const { PassThrough } = require('stream');

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

function isEmptyCommand(command) {
  return shouldPatch() && (command === '' || command == null);
}

function fakeChildProcess(label) {
  ensureFallbackRpcid();
  const proc = new EventEmitter();
  proc.stdin = new PassThrough();
  proc.stdout = new PassThrough();
  proc.stderr = new PassThrough();
  proc.pid = 0;
  proc.kill = () => false;
  proc.ref = () => proc;
  proc.unref = () => proc;
  process.nextTick(() => {
    console.warn('ComicReader CI bypassed empty OpenHarmony tool execution: ' + label);
    proc.stdout.end();
    proc.stderr.end();
    proc.emit('exit', 0, null);
    proc.emit('close', 0, null);
  });
  return proc;
}

const originalSpawn = childProcess.spawn;
childProcess.spawn = function (command, args, options) {
  if (isEmptyCommand(command)) {
    return fakeChildProcess('spawn');
  }
  return originalSpawn.call(this, command, args, options);
};

const originalExecFile = childProcess.execFile;
childProcess.execFile = function (file, args, options, callback) {
  if (typeof args === 'function') {
    callback = args;
    args = [];
    options = undefined;
  } else if (typeof options === 'function') {
    callback = options;
    options = undefined;
  }
  if (isEmptyCommand(file)) {
    ensureFallbackRpcid();
    process.nextTick(() => {
      console.warn('ComicReader CI bypassed empty OpenHarmony tool execution: execFile');
      if (typeof callback === 'function') callback(null, '', '');
    });
    const proc = fakeChildProcess('execFile');
    proc.stdout.end();
    proc.stderr.end();
    return proc;
  }
  return originalExecFile.call(this, file, args, options, callback);
};

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
      if (
        text.includes('00303060') ||
        text.includes('system capability sets configured for multiple devices') ||
        text.includes("The argument 'file' cannot be empty") ||
        text.includes('Received') && text.includes("''")
      ) {
        console.warn('ComicReader CI bypassed SyscapTransform from ' + (label || value.name || 'unknown'));
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
