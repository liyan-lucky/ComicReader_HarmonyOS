const fs = require('fs');
const path = require('path');

const CI_DEVICE_TYPE = 'phone';

function shouldPatch() {
  const platform = String(process.env.BUILD_PLATFORM || '').toLowerCase();
  const runtime = String(process.env.BUILD_RUNTIME_OS || '').toLowerCase();
  const product = String(process.env.BUILD_PRODUCT || '').toLowerCase();
  return platform.includes('openharmony') || runtime.includes('openharmony') || product.includes('openharmony');
}

function patchModuleJson5() {
  if (!shouldPatch()) return;

  const moduleJson5 = path.resolve(process.cwd(), 'entry/src/main/module.json5');
  if (!fs.existsSync(moduleJson5)) return;

  const original = fs.readFileSync(moduleJson5, 'utf8');
  const patched = original.replace(
    /"deviceTypes"\s*:\s*\[[\s\S]*?\]/,
    `"deviceTypes": [\n      "${CI_DEVICE_TYPE}"\n    ]`
  );

  if (patched !== original) {
    fs.writeFileSync(moduleJson5, patched);
    console.log('ComicReader CI patched module deviceTypes to ' + CI_DEVICE_TYPE + '.');
  } else {
    console.warn('ComicReader CI did not find deviceTypes to patch.');
  }
}

function writeSyscapFile(target) {
  const body = {
    general: [CI_DEVICE_TYPE],
    custom: [],
    devices: { general: [CI_DEVICE_TYPE], custom: [] },
    development: { addedSysCaps: [] },
    production: { addedSysCaps: [], removedSysCaps: [] }
  };
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, JSON.stringify(body, null, 2) + '\n');
  console.log('ComicReader CI wrote syscap file: ' + target);
}

function writeSyscapJson() {
  if (!shouldPatch()) return;
  const cwd = process.cwd();
  [
    'syscap.json',
    'entry/syscap.json',
    'entry/src/main/syscap.json'
  ].forEach((rel) => writeSyscapFile(path.resolve(cwd, rel)));
}

patchModuleJson5();
writeSyscapJson();

module.exports = { patchModuleJson5, writeSyscapJson };
