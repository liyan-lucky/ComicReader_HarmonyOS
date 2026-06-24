import { SearchEngineConfig, SearchResultItem } from '../model/ComicModels';
import { resolveUrl } from './UrlUtil';
import { cleanHtmlText } from './HtmlParser';

const SEARCH_UA = 'Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/120.0 Mobile Safari/537.36 ComicReaderHarmony/5.0';

export const DEFAULT_SEARCH_ENGINES: SearchEngineConfig[] = [
  {
    id: 'duckduckgo_html',
    name: 'DuckDuckGo 网页结果',
    description: '无 API Key 模式，读取 DuckDuckGo HTML/Lite 公开搜索结果；不绕过验证码或访问限制。',
    engineType: 'duckduckgo-html',
    searchUrl: 'https://duckduckgo.com/html/?q={query}',
    requiresKey: false,
    enabled: true
  },
  {
    id: 'bing_web_html',
    name: 'Bing 网页结果',
    description: '读取 Bing 普通网页搜索结果页；如遇验证码/地区限制会自动失败并继续其它源。',
    engineType: 'bing-html',
    searchUrl: 'https://www.bing.com/search?q={query}',
    requiresKey: false,
    enabled: true
  },
  {
    id: 'google_web_html',
    name: 'Google 网页结果',
    description: '读取 Google 普通网页结果页；稳定性取决于网络与搜索页是否允许直接访问。',
    engineType: 'google-html',
    searchUrl: 'https://www.google.com/search?q={query}',
    requiresKey: false,
    enabled: true
  },
  {
    id: 'yandex_web_html',
    name: 'Yandex 网页结果',
    description: '读取 Yandex 网页搜索结果页，适合英文/多语言兜底检索。',
    engineType: 'yandex-html',
    searchUrl: 'https://yandex.com/search/?text={query}',
    requiresKey: false,
    enabled: true
  },
  {
    id: 'brave_search_api',
    name: 'Brave Search API',
    description: '官方 Brave Search API，需要在设置里填写 API Key。',
    engineType: 'brave-api',
    searchUrl: 'https://api.search.brave.com/res/v1/web/search?q={query}&count=20',
    requiresKey: true,
    enabled: true
  },
  {
    id: 'google_cse_api',
    name: 'Google Programmable Search API',
    description: '官方 Google Programmable Search JSON API，需要 API Key 和 CX。',
    engineType: 'google-cse-api',
    searchUrl: 'https://www.googleapis.com/customsearch/v1?key={googleKey}&cx={googleCx}&q={query}&num=10',
    requiresKey: true,
    enabled: true
  }
];

export function searchEngineUserAgent(): string {
  return SEARCH_UA;
}

function decodeEntities(text: string): string {
  return text
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&#x27;/g, "'")
    .replace(/&#x2F;/g, '/')
    .replace(/\s+/g, ' ')
    .trim();
}

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

function readJsonString(block: string, key: string): string {
  const regex = new RegExp('"' + key + '"\\s*:\\s*"((?:\\\\.|[^"\\\\])*)"', 'im');
  const match = regex.exec(block);
  if (match && match.length > 1) {
    return jsonUnescape(match[1]);
  }
  return '';
}

function stripRedirect(url: string): string {
  let next = decodeEntities(url.trim());
  if (next.startsWith('/url?') || next.indexOf('/url?q=') >= 0) {
    const q = /[?&]q=([^&]+)/.exec(next);
    if (q && q.length > 1) {
      next = decodeURIComponent(q[1]);
    }
  }
  const uddg = /[?&]uddg=([^&]+)/.exec(next);
  if (uddg && uddg.length > 1) {
    next = decodeURIComponent(uddg[1]);
  }
  if (next.startsWith('//')) {
    next = 'https:' + next;
  }
  return next;
}

function isUsefulUrl(url: string): boolean {
  const lower = url.toLowerCase();
  if (!(lower.startsWith('http://') || lower.startsWith('https://'))) {
    return false;
  }
  if (lower.indexOf('google.') >= 0 && (lower.indexOf('/search') >= 0 || lower.indexOf('/preferences') >= 0 || lower.indexOf('/policies') >= 0)) {
    return false;
  }
  if (lower.indexOf('bing.com/search') >= 0 || lower.indexOf('duckduckgo.com') >= 0 || lower.indexOf('yandex.com/search') >= 0) {
    return false;
  }
  if (lower.indexOf('javascript:') >= 0 || lower.indexOf('mailto:') >= 0 || lower.indexOf('tel:') >= 0) {
    return false;
  }
  return true;
}

function looksComicRelated(title: string, url: string, keyword: string): boolean {
  const text = (title + ' ' + url).toLowerCase();
  const key = keyword.toLowerCase().trim();
  if (key.length > 0 && text.indexOf(key) >= 0) {
    return true;
  }
  return /(comic|comics|manga|manhua|manhwa|webtoon|webcomic|graphic novel|cartoon|chapter|read|reader|episode|scan|漫画|漫话|マンガ|漫画家|코믹|만화)/i.test(text);
}

function makeSearchItem(title: string, url: string, engine: SearchEngineConfig, keyword: string, desc: string): SearchResultItem | null {
  const cleanTitle = cleanHtmlText(decodeEntities(title));
  const cleanUrl = stripRedirect(url);
  if (cleanTitle.length === 0 || !isUsefulUrl(cleanUrl)) {
    return null;
  }
  if (!looksComicRelated(cleanTitle, cleanUrl, keyword)) {
    return null;
  }
  return {
    title: cleanTitle,
    url: cleanUrl,
    cover: '',
    sourceId: engine.id,
    sourceName: engine.name,
    isChapter: false,
    resultType: 'search-engine',
    groupName: cleanTitle,
    description: desc.length > 0 ? desc : '搜索引擎发现的公开网页结果，点击后进入公开HTML解析链路。'
  };
}

export function buildEngineQuery(keyword: string, extraTerms: string, languageMode: string, siteHint: string): string {
  let query = keyword.trim();
  if (extraTerms.trim().length > 0) {
    query += ' ' + extraTerms.trim();
  }
  if (languageMode === '中文') {
    query += ' 漫画 在线 阅读 章节';
  } else if (languageMode === '英文') {
    query += ' comic manga read online chapter';
  } else if (languageMode === '日文') {
    query += ' manga webcomic chapter';
  } else if (languageMode === '韩文') {
    query += ' manhwa webtoon episode';
  }
  if (siteHint.trim().length > 0) {
    query += ' ' + siteHint.trim();
  }
  return query.replace(/\s+/g, ' ').trim();
}

export function buildSearchEngineUrl(engine: SearchEngineConfig, query: string, braveKey: string, googleKey: string, googleCx: string): string {
  const encoded = encodeURIComponent(query);
  return engine.searchUrl
    .replace('{query}', encoded)
    .replace('{googleKey}', encodeURIComponent(googleKey.trim()))
    .replace('{googleCx}', encodeURIComponent(googleCx.trim()))
    .replace('{braveKey}', encodeURIComponent(braveKey.trim()));
}

export function isEngineConfigured(engine: SearchEngineConfig, braveKey: string, googleKey: string, googleCx: string): boolean {
  if (!engine.requiresKey) {
    return true;
  }
  if (engine.engineType === 'brave-api') {
    return braveKey.trim().length > 0;
  }
  if (engine.engineType === 'google-cse-api') {
    return googleKey.trim().length > 0 && googleCx.trim().length > 0;
  }
  return false;
}

export function engineHeaders(engine: SearchEngineConfig, braveKey: string): Record<string, string> {
  const headers: Record<string, string> = {};
  if (engine.engineType === 'brave-api' && braveKey.trim().length > 0) {
    headers['X-Subscription-Token'] = braveKey.trim();
    headers['Accept'] = 'application/json';
  }
  return headers;
}

function parseGenericHtmlResults(html: string, engine: SearchEngineConfig, keyword: string, baseUrl: string): SearchResultItem[] {
  const items: SearchResultItem[] = [];
  const patterns: RegExp[] = [
    /<a[^>]+class=["'][^"']*(?:result__a|result-link|result-title|organic__url|serp-item__title-link)[^"']*["'][^>]+href=["']([^"']+)["'][^>]*>([\s\S]{1,260}?)<\/a>/gim,
    /<h2[^>]*>[\s\S]*?<a[^>]+href=["']([^"']+)["'][^>]*>([\s\S]{1,260}?)<\/a>[\s\S]*?<\/h2>/gim,
    /<a[^>]+href=["']((?:https?:\/\/|\/url\?q=|\/l\/\?kh=|[^"']*uddg=)[^"']+)["'][^>]*>([\s\S]{1,220}?)<\/a>/gim
  ];
  for (let p = 0; p < patterns.length; p++) {
    const regex = patterns[p];
    let match = regex.exec(html);
    let guard = 0;
    while (match !== null && guard < 120) {
      guard++;
      const url = resolveUrl(match[1], baseUrl);
      const title = match[2];
      const item = makeSearchItem(title, url, engine, keyword, engine.description);
      if (item !== null && !items.some((old: SearchResultItem) => old.url === item.url)) {
        items.push(item);
      }
      if (regex.lastIndex === match.index) {
        regex.lastIndex++;
      }
      match = regex.exec(html);
    }
  }
  return items.slice(0, 50);
}

function parseGoogleCseResults(jsonText: string, engine: SearchEngineConfig, keyword: string): SearchResultItem[] {
  const items: SearchResultItem[] = [];
  const blocks = extractObjectArrayByKey(jsonText, 'items');
  for (let i = 0; i < blocks.length && i < 30; i++) {
    const title = readJsonString(blocks[i], 'title');
    const link = readJsonString(blocks[i], 'link');
    const snippet = readJsonString(blocks[i], 'snippet');
    const item = makeSearchItem(title, link, engine, keyword, snippet);
    if (item !== null && !items.some((old: SearchResultItem) => old.url === item.url)) {
      items.push(item);
    }
  }
  return items;
}

function parseBraveResults(jsonText: string, engine: SearchEngineConfig, keyword: string): SearchResultItem[] {
  const items: SearchResultItem[] = [];
  const blocks = extractObjectArrayByKey(jsonText, 'results');
  for (let i = 0; i < blocks.length && i < 50; i++) {
    const title = readJsonString(blocks[i], 'title');
    const url = readJsonString(blocks[i], 'url');
    const desc = readJsonString(blocks[i], 'description');
    const item = makeSearchItem(title, url, engine, keyword, desc);
    if (item !== null && !items.some((old: SearchResultItem) => old.url === item.url)) {
      items.push(item);
    }
  }
  return items;
}

export function parseSearchEngineResults(body: string, engine: SearchEngineConfig, keyword: string, searchUrl: string): SearchResultItem[] {
  if (engine.engineType === 'google-cse-api') {
    return parseGoogleCseResults(body, engine, keyword);
  }
  if (engine.engineType === 'brave-api') {
    return parseBraveResults(body, engine, keyword);
  }
  return parseGenericHtmlResults(body, engine, keyword, searchUrl);
}
