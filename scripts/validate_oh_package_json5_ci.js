const fs = require('fs');
const path = require('path');

const rootDir = path.resolve(__dirname, '..');

const fallbacks = {
  'oh-package.json5': `{
  "name": "comic-reader-harmonyos",
  "version": "1.0.0",
  "description": "ComicReader HarmonyOS",
  "main": "",
  "author": "",
  "license": "MIT",
  "dependencies": {},
  "devDependencies": {}
}
`,
  'entry/oh-package.json5': `{
  "name": "entry",
  "version": "1.0.0",
  "description": "entry",
  "main": "",
  "author": "",
  "license": "MIT",
  "dependencies": {}
}
`
};

function looksStructurallyValidJson5(text) {
  const value = String(text || '').trim();
  if (value.length < 2) return false;
  if (!value.startsWith('{') || !value.endsWith('}')) return false;
  let depth = 0;
  let inString = false;
  let quote = '';
  let escaped = false;
  for (const ch of value) {
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (ch === '\\') {
        escaped = true;
      } else if (ch === quote) {
        inString = false;
      }
      continue;
    }
    if (ch === '"' || ch === "'") {
      inString = true;
      quote = ch;
      continue;
    }
    if (ch === '{') depth++;
    if (ch === '}') depth--;
    if (depth < 0) return false;
  }
  return depth === 0 && !inString;
}

function ensurePackageFile(relPath, fallbackContent) {
  const file = path.join(rootDir, relPath);
  let current = '';
  try {
    current = fs.readFileSync(file, 'utf8');
  } catch (err) {
    console.warn(`包配置缺失，准备恢复：${relPath}`);
  }

  if (!looksStructurallyValidJson5(current)) {
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, fallbackContent, 'utf8');
    console.warn(`已恢复 ${relPath} 为最小合法 JSON5，避免 hvigor 读取空文件。`);
    return;
  }
  console.log(`已校验 ${relPath}：结构完整。`);
}

for (const [relPath, fallbackContent] of Object.entries(fallbacks)) {
  ensurePackageFile(relPath, fallbackContent);
}
