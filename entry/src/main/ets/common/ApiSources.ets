import { SearchResultItem, ReaderImageItem } from '../model/ComicModels';

const IA_SOURCE_ID = 'internet_archive_iiif_api';
const WIKI_SOURCE_ID = 'wikimedia_commons_api';
const PEPPER_SOURCE_ID = 'pepper_carrot_public_catalog';
const OPEN_LIBRARY_SOURCE_ID = 'open_library_public_api';
const LOC_SOURCE_ID = 'library_of_congress_public_api';

function jsonUnescape(value: string): string {
  return value
    .replace(/\\\//g, '/')
    .replace(/\\u0026/g, '&')
    .replace(/\\u003d/g, '=')
    .replace(/\\u003c/g, '<')
    .replace(/\\u003e/g, '>')
    .replace(/\\u002F/g, '/')
    .replace(/\\"/g, '"')
    .replace(/\\n/g, ' ')
    .replace(/\\r/g, ' ')
    .replace(/\\t/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function readJsonString(block: string, key: string): string {
  const regex = new RegExp('"' + key + '"\\s*:\\s*"((?:\\\\.|[^"\\\\])*)"', 'im');
  const match = regex.exec(block);
  if (match && match.length > 1) {
    return jsonUnescape(match[1]);
  }
  return '';
}

function readJsonNumber(block: string, key: string): string {
  const regex = new RegExp('"' + key + '"\\s*:\\s*([0-9]+)', 'im');
  const match = regex.exec(block);
  if (match && match.length > 1) {
    return match[1];
  }
  return '';
}

function readFirstArrayString(block: string, key: string): string {
  const arr = extractArrayByKey(block, key);
  const match = /"((?:\\.|[^"\\])*)"/im.exec(arr);
  if (match && match.length > 1) {
    return jsonUnescape(match[1]);
  }
  return '';
}

function extractArrayByKey(jsonText: string, key: string): string {
  const token = '"' + key + '"';
  const keyIndex = jsonText.indexOf(token);
  if (keyIndex < 0) {
    return '';
  }
  const start = jsonText.indexOf('[', keyIndex);
  if (start < 0) {
    return '';
  }
  let depth = 0;
  let inString = false;
  let escaped = false;
  for (let i = start; i < jsonText.length; i++) {
    const ch = jsonText.charAt(i);
    if (escaped) {
      escaped = false;
      continue;
    }
    if (ch === '\\') {
      escaped = true;
      continue;
    }
    if (ch === '"') {
      inString = !inString;
      continue;
    }
    if (!inString) {
      if (ch === '[') {
        depth++;
      } else if (ch === ']') {
        depth--;
        if (depth === 0) {
          return jsonText.substring(start + 1, i);
        }
      }
    }
  }
  return '';
}

function extractObjectArrayByKey(jsonText: string, key: string): string[] {
  const arr = extractArrayByKey(jsonText, key);
  const objects: string[] = [];
  let depth = 0;
  let start = -1;
  let inString = false;
  let escaped = false;
  for (let i = 0; i < arr.length; i++) {
    const ch = arr.charAt(i);
    if (escaped) {
      escaped = false;
      continue;
    }
    if (ch === '\\') {
      escaped = true;
      continue;
    }
    if (ch === '"') {
      inString = !inString;
      continue;
    }
    if (!inString) {
      if (ch === '{') {
        if (depth === 0) {
          start = i;
        }
        depth++;
      } else if (ch === '}') {
        depth--;
        if (depth === 0 && start >= 0) {
          objects.push(arr.substring(start, i + 1));
          start = -1;
        }
      }
    }
  }
  return objects;
}

function safeTitle(value: string, fallback: string): string {
  const clean = value.replace(/<[^>]+>/g, ' ').replace(/&amp;/g, '&').replace(/\s+/g, ' ').trim();
  if (clean.length > 0) {
    return clean;
  }
  return fallback;
}

function compactDesc(value: string): string {
  const clean = safeTitle(value, '');
  if (clean.length > 110) {
    return clean.substring(0, 110) + '...';
  }
  return clean;
}

function encodePathPart(value: string): string {
  return value.split('/').map((part: string) => encodeURIComponent(part)).join('/');
}

function makeArchivePseudoUrl(identifier: string): string {
  return 'archive://item/' + encodeURIComponent(identifier);
}

export function isArchivePseudoUrl(url: string): boolean {
  return url.startsWith('archive://item/');
}

export function archiveIdentifierFromUrl(url: string): string {
  if (!isArchivePseudoUrl(url)) {
    return '';
  }
  return decodeURIComponent(url.replace('archive://item/', ''));
}

function makeWikimediaPseudoUrl(imageUrl: string): string {
  return 'wikimedia://image?url=' + encodeURIComponent(imageUrl);
}

export function isWikimediaPseudoUrl(url: string): boolean {
  return url.startsWith('wikimedia://image?url=');
}

export function wikimediaImageFromUrl(url: string): string {
  if (!isWikimediaPseudoUrl(url)) {
    return '';
  }
  return decodeURIComponent(url.replace('wikimedia://image?url=', ''));
}

function makeLocPseudoUrl(imageUrl: string): string {
  return 'loc://image?url=' + encodeURIComponent(imageUrl);
}

export function isLocPseudoUrl(url: string): boolean {
  return url.startsWith('loc://image?url=');
}

export function locImageFromUrl(url: string): string {
  if (!isLocPseudoUrl(url)) {
    return '';
  }
  return decodeURIComponent(url.replace('loc://image?url=', ''));
}

function directDownloadUrl(identifier: string, filename: string): string {
  return 'https://archive.org/download/' + encodeURIComponent(identifier) + '/' + encodePathPart(filename);
}

export function buildInternetArchiveSearchUrl(keyword: string): string {
  const k = keyword.trim();
  const query = `(title:(${k}) OR description:(${k}) OR subject:(${k}) OR creator:(${k})) AND (mediatype:texts OR mediatype:image) AND (subject:comic OR subject:comics OR subject:manga OR subject:manhua OR subject:manhwa OR collection:comicbooks OR collection:manga OR title:comic OR title:manga OR description:comic OR description:manga)`;
  return 'https://archive.org/advancedsearch.php?q=' + encodeURIComponent(query) + '&fl[]=identifier&fl[]=title&fl[]=creator&fl[]=description&fl[]=year&rows=48&page=1&output=json';
}

export function buildInternetArchiveManifestUrl(identifier: string): string {
  return 'https://iiif.archive.org/iiif/' + encodeURIComponent(identifier) + '/manifest.json';
}

export function buildInternetArchiveMetadataUrl(identifier: string): string {
  return 'https://archive.org/metadata/' + encodeURIComponent(identifier);
}

export function buildWikimediaSearchUrl(keyword: string): string {
  const text = keyword.trim() + ' comic manga manhua webcomic';
  return 'https://commons.wikimedia.org/w/api.php?action=query&format=json&origin=*&generator=search&gsrnamespace=6&gsrlimit=36&gsrsearch=' + encodeURIComponent(text) + '&prop=imageinfo&iiprop=url|mime|size&iiurlwidth=480';
}

export function buildOpenLibrarySearchUrl(keyword: string): string {
  const text = keyword.trim() + ' comics manga manhua graphic novel';
  return 'https://openlibrary.org/search.json?q=' + encodeURIComponent(text) + '&fields=key,title,author_name,cover_i,ia,first_publish_year,public_scan_b,has_fulltext,subject&limit=36';
}

export function buildLibraryOfCongressSearchUrl(keyword: string): string {
  const text = keyword.trim() + ' comic OR comics OR manga OR cartoon';
  return 'https://www.loc.gov/search/?fo=json&c=36&at=results,pagination&q=' + encodeURIComponent(text) + '&fa=online-format:image';
}

export function parseInternetArchiveSearch(jsonText: string, keyword: string): SearchResultItem[] {
  const results: SearchResultItem[] = [];
  const docs = extractObjectArrayByKey(jsonText, 'docs');
  for (let i = 0; i < docs.length && i < 80; i++) {
    const block = docs[i];
    const identifier = readJsonString(block, 'identifier');
    const title = safeTitle(readJsonString(block, 'title'), identifier);
    const creator = readJsonString(block, 'creator');
    const year = readJsonString(block, 'year');
    const desc = compactDesc(readJsonString(block, 'description'));
    if (identifier.length > 0 && title.length > 0) {
      const meta = (creator.length > 0 ? creator + ' · ' : '') + (year.length > 0 ? year + ' · ' : '') + desc;
      if (!results.some((item: SearchResultItem) => item.url === makeArchivePseudoUrl(identifier))) {
        results.push({
          title: title,
          url: makeArchivePseudoUrl(identifier),
          cover: 'https://archive.org/services/img/' + encodeURIComponent(identifier),
          sourceId: IA_SOURCE_ID,
          sourceName: 'Internet Archive公开馆藏',
          isChapter: false,
          resultType: 'archive-iiif',
          groupName: title,
          description: meta.length > 0 ? meta : 'Internet Archive公开馆藏结果，点击后优先IIIF，失败后走metadata图片文件兜底。'
        });
      }
    }
  }
  return results;
}

export function parseInternetArchiveManifestImages(jsonText: string): ReaderImageItem[] {
  const images: ReaderImageItem[] = [];
  const directRegex = /https:\/\/iiif\.archive\.org\/image\/iiif\/[^"\\]+\/full\/(?:max|full|[0-9,]+)\/0\/default\.(?:jpg|jpeg|png|webp)/gim;
  let match = directRegex.exec(jsonText);
  let guard = 0;
  while (match !== null && guard < 800) {
    guard++;
    const url = jsonUnescape(match[0]);
    if (!images.some((item: ReaderImageItem) => item.url === url)) {
      images.push({ url: url, index: images.length + 1, status: 'waiting' });
    }
    if (match.index === directRegex.lastIndex) {
      directRegex.lastIndex++;
    }
    match = directRegex.exec(jsonText);
  }
  if (images.length > 0) {
    return images;
  }

  const serviceRegex = /https:\/\/iiif\.archive\.org\/image\/iiif\/([^"\\]+)\/info\.json/gim;
  match = serviceRegex.exec(jsonText);
  guard = 0;
  while (match !== null && guard < 800) {
    guard++;
    const idAndFile = jsonUnescape(match[1]);
    const url = 'https://iiif.archive.org/image/iiif/' + idAndFile + '/full/max/0/default.jpg';
    if (!images.some((item: ReaderImageItem) => item.url === url)) {
      images.push({ url: url, index: images.length + 1, status: 'waiting' });
    }
    if (match.index === serviceRegex.lastIndex) {
      serviceRegex.lastIndex++;
    }
    match = serviceRegex.exec(jsonText);
  }
  return images;
}

export function parseInternetArchiveMetadataImages(jsonText: string, identifier: string): ReaderImageItem[] {
  const images: ReaderImageItem[] = [];
  const files = extractObjectArrayByKey(jsonText, 'files');
  for (let i = 0; i < files.length && images.length < 600; i++) {
    const file = files[i];
    const name = readJsonString(file, 'name');
    const format = readJsonString(file, 'format').toLowerCase();
    const lower = name.toLowerCase();
    const isImage = /(\.jpg|\.jpeg|\.png|\.webp|\.gif)$/i.test(lower) || format.indexOf('jpeg') >= 0 || format.indexOf('png') >= 0 || format.indexOf('webp') >= 0 || format.indexOf('gif') >= 0;
    const skipThumb = lower.indexOf('_thumb') >= 0 || lower.indexOf('__ia_thumb') >= 0 || lower.indexOf('_itemimage') >= 0;
    if (name.length > 0 && isImage && !skipThumb) {
      const url = directDownloadUrl(identifier, name);
      if (!images.some((item: ReaderImageItem) => item.url === url)) {
        images.push({ url: url, index: images.length + 1, status: 'waiting' });
      }
    }
  }
  return images;
}

export function parseOpenLibrarySearch(jsonText: string, keyword: string): SearchResultItem[] {
  const results: SearchResultItem[] = [];
  const docs = extractObjectArrayByKey(jsonText, 'docs');
  for (let i = 0; i < docs.length && i < 60; i++) {
    const block = docs[i];
    const title = safeTitle(readJsonString(block, 'title'), 'Open Library条目');
    const author = readFirstArrayString(block, 'author_name');
    const year = readJsonNumber(block, 'first_publish_year');
    const coverId = readJsonNumber(block, 'cover_i');
    const ia = readFirstArrayString(block, 'ia');
    const hasFullText = /"has_fulltext"\s*:\s*true/i.test(block) || /"public_scan_b"\s*:\s*true/i.test(block);
    if (title.length > 0 && ia.length > 0 && hasFullText) {
      const cover = coverId.length > 0 ? 'https://covers.openlibrary.org/b/id/' + coverId + '-L.jpg' : 'https://archive.org/services/img/' + encodeURIComponent(ia);
      const meta = (author.length > 0 ? author + ' · ' : '') + (year.length > 0 ? year + ' · ' : '') + 'Open Library索引到Internet Archive公开可读馆藏';
      results.push({
        title: title,
        url: makeArchivePseudoUrl(ia),
        cover: cover,
        sourceId: OPEN_LIBRARY_SOURCE_ID,
        sourceName: 'Open Library公开图书索引',
        isChapter: false,
        resultType: 'openlibrary-to-archive',
        groupName: title,
        description: meta
      });
    }
  }
  return results;
}

export function parseWikimediaSearch(jsonText: string, keyword: string): SearchResultItem[] {
  const results: SearchResultItem[] = [];
  const objectRegex = /\{[\s\S]*?"title"\s*:\s*"((?:\\.|[^"\\])*)"[\s\S]*?"imageinfo"\s*:\s*\[\s*\{([\s\S]*?)\}\s*\][\s\S]*?\}/gim;
  let match = objectRegex.exec(jsonText);
  let guard = 0;
  while (match !== null && guard < 80) {
    guard++;
    const rawTitle = jsonUnescape(match[1]).replace(/^File:/i, '');
    const block = match[2];
    const imageUrl = readJsonString(block, 'thumburl').length > 0 ? readJsonString(block, 'thumburl') : readJsonString(block, 'url');
    const fullUrl = readJsonString(block, 'url').length > 0 ? readJsonString(block, 'url') : imageUrl;
    if (rawTitle.length > 0 && fullUrl.length > 0 && /\.(jpg|jpeg|png|webp|gif)(\?|$)/i.test(fullUrl)) {
      if (!results.some((item: SearchResultItem) => item.url === makeWikimediaPseudoUrl(fullUrl))) {
        results.push({
          title: rawTitle,
          url: makeWikimediaPseudoUrl(fullUrl),
          cover: imageUrl.length > 0 ? imageUrl : fullUrl,
          sourceId: WIKI_SOURCE_ID,
          sourceName: 'Wikimedia Commons公开图片',
          isChapter: true,
          resultType: 'wikimedia-image',
          groupName: rawTitle,
          description: 'Wikimedia Commons公开图片结果，点击后以单图卷轴方式阅读。'
        });
      }
    }
    if (match.index === objectRegex.lastIndex) {
      objectRegex.lastIndex++;
    }
    match = objectRegex.exec(jsonText);
  }
  return results;
}

export function parseLibraryOfCongressSearch(jsonText: string, keyword: string): SearchResultItem[] {
  const results: SearchResultItem[] = [];
  const resultBlocks = extractObjectArrayByKey(jsonText, 'results');
  for (let i = 0; i < resultBlocks.length && i < 60; i++) {
    const block = resultBlocks[i];
    const title = safeTitle(readJsonString(block, 'title'), 'Library of Congress条目');
    let image = readFirstArrayString(block, 'image_url');
    if (image.length === 0) {
      const urlMatch = /https:\/\/[^"\\]+\.(?:jpg|jpeg|png|webp)(?:\?[^"\\]*)?/i.exec(block);
      image = urlMatch ? jsonUnescape(urlMatch[0]) : '';
    }
    const date = readJsonString(block, 'date');
    const subject = readFirstArrayString(block, 'subject');
    if (title.length > 0 && image.length > 0 && /\.(jpg|jpeg|png|webp)(\?|$|\/)/i.test(image)) {
      results.push({
        title: title,
        url: makeLocPseudoUrl(image),
        cover: image,
        sourceId: LOC_SOURCE_ID,
        sourceName: 'Library of Congress公开影像',
        isChapter: true,
        resultType: 'loc-image',
        groupName: title,
        description: (date.length > 0 ? date + ' · ' : '') + (subject.length > 0 ? subject : 'LOC公开图片/图书影像结果，点击后以卷轴图片方式阅读。')
      });
    }
  }
  return results;
}

interface PepperEpisode {
  title: string;
  url: string;
  cover: string;
  images: string[];
}

const PEPPER_COVER = 'https://www.peppercarrot.com/0_sources/0ther/artworks/hi-res/2015-02-24_pepper-and-carrot_by-David-Revoy.jpg';

const PEPPER_EPISODES: PepperEpisode[] = [
  {
    title: 'Pepper&Carrot Episode 1 - Potion of Flight',
    url: 'pepper://episode/1',
    cover: PEPPER_COVER,
    images: ['https://www.peppercarrot.com/0_sources/ep01_Potion-of-Flight/lang/en/hi-res/ep01_Potion-of-Flight_by-David-Revoy_en.jpg']
  },
  {
    title: 'Pepper&Carrot Episode 2 - Rainbow Potions',
    url: 'pepper://episode/2',
    cover: PEPPER_COVER,
    images: ['https://www.peppercarrot.com/0_sources/ep02_Rainbow-potions/lang/en/hi-res/ep02_Rainbow-potions_by-David-Revoy_en.jpg']
  },
  {
    title: 'Pepper&Carrot Episode 3 - The Secret Ingredients',
    url: 'pepper://episode/3',
    cover: PEPPER_COVER,
    images: ['https://www.peppercarrot.com/0_sources/ep03_The-secret-ingredients/lang/en/hi-res/ep03_The-secret-ingredients_by-David-Revoy_en.jpg']
  },
  {
    title: 'Pepper&Carrot Episode 4 - Stroke of Genius',
    url: 'pepper://episode/4',
    cover: PEPPER_COVER,
    images: ['https://www.peppercarrot.com/0_sources/ep04_Stroke-of-genius/lang/en/hi-res/ep04_Stroke-of-genius_by-David-Revoy_en.jpg']
  }
];

export function isPepperPseudoUrl(url: string): boolean {
  return url.startsWith('pepper://episode/');
}

export function parsePepperImages(url: string): ReaderImageItem[] {
  for (let i = 0; i < PEPPER_EPISODES.length; i++) {
    const item = PEPPER_EPISODES[i];
    if (item.url === url) {
      const images: ReaderImageItem[] = [];
      for (let j = 0; j < item.images.length; j++) {
        images.push({ url: item.images[j], index: j + 1, status: 'waiting' });
      }
      return images;
    }
  }
  return [];
}

export function searchPepperCatalog(keyword: string): SearchResultItem[] {
  const key = keyword.trim().toLowerCase();
  const results: SearchResultItem[] = [];
  if (key.length === 0) {
    return results;
  }
  for (let i = 0; i < PEPPER_EPISODES.length; i++) {
    const item = PEPPER_EPISODES[i];
    if (item.title.toLowerCase().indexOf(key) >= 0 || 'pepper carrot'.indexOf(key) >= 0 || key.indexOf('pepper') >= 0 || key.indexOf('carrot') >= 0) {
      results.push({
        title: item.title,
        url: item.url,
        cover: item.cover,
        sourceId: PEPPER_SOURCE_ID,
        sourceName: 'Pepper&Carrot公开目录',
        isChapter: true,
        resultType: 'pepper-static',
        groupName: 'Pepper&Carrot',
        description: 'Creative Commons BY 4.0公开网页漫画示例源。'
      });
    }
  }
  return results;
}

export function builtinApiSourceCount(): number {
  return 5;
}

export function internetArchiveSourceId(): string {
  return IA_SOURCE_ID;
}

export function wikimediaSourceId(): string {
  return WIKI_SOURCE_ID;
}

export function pepperSourceId(): string {
  return PEPPER_SOURCE_ID;
}

export function openLibrarySourceId(): string {
  return OPEN_LIBRARY_SOURCE_ID;
}

export function libraryOfCongressSourceId(): string {
  return LOC_SOURCE_ID;
}
