const fs = require('fs');
const path = require('path');

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
    '"deviceTypes": [\n      "default"\n    ]'
  );

  if (patched !== original) {
    fs.writeFileSync(moduleJson5, patched);
    console.log('ComicReader CI patched entry/src/main/module.json5 deviceTypes to ["default"] for OpenHarmony syscap check.');
  } else {
    console.warn('ComicReader CI did not find deviceTypes in entry/src/main/module.json5 to patch.');
  }
}

function writeSyscapJson() {
  if (!shouldPatch()) return;

  const syscapJson = path.resolve(process.cwd(), 'syscap.json');
  const content = {
    devices: {
      general: ['default'],
      custom: []
    },
    development: {
      addedSysCaps: []
    },
    production: {
      addedSysCaps: [],
      removedSysCaps: []
    }
  };

  fs.writeFileSync(syscapJson, `${JSON.stringify(content, null, 2)}\n`);
  console.log('ComicReader CI wrote root syscap.json with devices.general=["default"] for OpenHarmony syscap check.');
}

patchModuleJson5();
writeSyscapJson();

module.exports = { patchModuleJson5, writeSyscapJson };
