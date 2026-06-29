const Module = require('module');

function fallbackJson(options) {
  const fallback = '{}\n';
  const encoding = typeof options === 'string' ? options : options && options.encoding;
  return encoding ? fallback : Buffer.from(fallback);
}

function patchJsonfile(jsonfile, label) {
  if (!jsonfile || typeof jsonfile.readFileSync !== 'function' || jsonfile.__comicReaderEmptySchemaPatched) {
    return jsonfile;
  }

  const originalReadFileSync = jsonfile.readFileSync.bind(jsonfile);
  jsonfile.readFileSync = function (filePath, options) {
    if (typeof filePath === 'string' && filePath.length === 0) {
      console.warn(`ComicReader CI jsonfile empty schema path from ${label || 'jsonfile'}; using permissive empty JSON schema.`);
      return fallbackJson(options);
    }
    try {
      return originalReadFileSync(filePath, options);
    } catch (error) {
      if (error && error.code === 'ENOENT' && typeof filePath === 'string' && filePath.length === 0) {
        console.warn(`ComicReader CI jsonfile could not read empty schema path from ${label || 'jsonfile'}; using permissive empty JSON schema.`);
        return fallbackJson(options);
      }
      throw error;
    }
  };

  jsonfile.__comicReaderEmptySchemaPatched = true;
  console.log(`ComicReader patched jsonfile empty schema fallback: ${label || 'jsonfile'}`);
  return jsonfile;
}

const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  const loaded = originalLoad.call(this, request, parent, isMain);
  const normalized = String(request || '').replace(/\\/g, '/').toLowerCase();
  if (normalized === 'jsonfile' || normalized.endsWith('/jsonfile') || normalized.includes('/jsonfile/')) {
    return patchJsonfile(loaded, request);
  }
  return loaded;
};

module.exports = { patchJsonfile };
