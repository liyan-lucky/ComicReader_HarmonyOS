const fs = require('fs');
const path = require('path');

const PHONE_DEVICE_TYPE = 'phone';
const OPENHARMONY_CUSTOM_DEVICE_TYPE = 'comic_reader_ci';
const OPENHARMONY_CUSTOM_SYSCAPS = [
  'SystemCapability.Ability.AbilityRuntime.Core',
  'SystemCapability.ArkUI.ArkUI.Full',
  'SystemCapability.BundleManager.BundleFramework.Core',
  'SystemCapability.Communication.NetManager.Core',
  'SystemCapability.Global.ResourceManager',
  'SystemCapability.Utils.Lang'
];

function currentRuntime() {
  return String(process.env.BUILD_RUNTIME_OS || process.env.BUILD_PLATFORM || '').toLowerCase();
}

function isOpenHarmony() {
  return currentRuntime().includes('openharmony');
}

function shouldPatch() {
  return currentRuntime().includes('openharmony') || currentRuntime().includes('harmonyos');
}

function targetDeviceType() {
  return isOpenHarmony() ? OPENHARMONY_CUSTOM_DEVICE_TYPE : PHONE_DEVICE_TYPE;
}

function patchModuleJson5() {
  if (!shouldPatch()) return;

  const deviceType = targetDeviceType();
  const moduleJson5 = path.resolve(process.cwd(), 'entry/src/main/module.json5');
  if (!fs.existsSync(moduleJson5)) return;

  const original = fs.readFileSync(moduleJson5, 'utf8');
  const patched = original.replace(
    /"deviceTypes"\s*:\s*\[[\s\S]*?\]/,
    `"deviceTypes": [\n      "${deviceType}"\n    ]`
  );

  if (patched !== original) {
    fs.writeFileSync(moduleJson5, patched);
    console.log('ComicReader CI patched module deviceTypes to ' + deviceType + '.');
  } else {
    console.warn('ComicReader CI did not find deviceTypes to patch.');
  }
}

function syscapBody() {
  if (isOpenHarmony()) {
    const customDevice = { [OPENHARMONY_CUSTOM_DEVICE_TYPE]: OPENHARMONY_CUSTOM_SYSCAPS };
    return {
      general: [OPENHARMONY_CUSTOM_DEVICE_TYPE],
      custom: [customDevice],
      devices: { general: [OPENHARMONY_CUSTOM_DEVICE_TYPE], custom: [customDevice] },
      development: { addedSysCaps: OPENHARMONY_CUSTOM_SYSCAPS },
      production: { addedSysCaps: OPENHARMONY_CUSTOM_SYSCAPS, removedSysCaps: [] }
    };
  }

  return {
    general: [PHONE_DEVICE_TYPE],
    custom: [],
    devices: { general: [PHONE_DEVICE_TYPE], custom: [] },
    development: { addedSysCaps: [] },
    production: { addedSysCaps: [], removedSysCaps: [] }
  };
}

function writeSyscapFile(target) {
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, JSON.stringify(syscapBody(), null, 2) + '\n');
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
