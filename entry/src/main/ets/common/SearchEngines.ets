import { SearchEngineConfig, SearchResultItem } from '../model/ComicModels';
import { resolveUrl } from './UrlUtil';
import { cleanHtmlText } from './HtmlParser';

const SEARCH_UA = 'Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/120.0 Mobile Safari/537.36 ComicReaderHarmony/5.0';

const BLOCKED_SEARCH_DOMAINS: string[] = [
  'douyin.com',
  'iesdouyin.com',
  'snssdk.com',
  'tiktok.com',
  'bilibili.com',
  'youtube.com',
  'youtu.be',
  'ixigua.com',
  'kuaishou.com',
  'ks.com',
  'xiaohongshu.com',
  'xhslink.com',
  'weibo.com',
  'tieba.baidu.com',
  'zhihu.com',
  'baike.baidu.com',
  'baike.sogou.com',
  'wikipedia.org',
  'wikiwand.com',
  'fandom.com',
  'hanyuguoxue.com',
  'zdic.net',
  'cidianwang.com',
  'chazidian.com',
  'hanziyuan.net',
  'moedict.tw',
  'facebook.com',
  'instagram.com',
  'twitter.com',
  'x.com',
  'reddit.com',
  'pinterest.com',
  'amazon.',
  'taobao.com',
  'tmall.com',
  'jd.com',
  'dangdang.com'
];

const BLOCKED_SEARCH_WORDS: string[] = [
  '抖音',
  '短视频',
  '视频',
  '动画',
  '电视剧',
  '真人版',
  '百科',
  '词条',
  '贴吧',
  '知乎',
  '小红书',
  '微博',
  '汉语',
  '国学',
  '字典',
  '词典',
  '拼音',
  '解释',
  '意思',
  '成语',
  'bilibili',
  'youtube',
  'tiktok',
  'wiki',
  'wikipedia',
  'facebook',
  'instagram',
  'reddit'
];

const PREFERRED_COMIC_DOMAINS: string[] = [
  'soullandmanga.com',
  'kaixinman.com',
  'manhuaus.com',
  'mangafire.to',
  'mgeko.cc',
  'happymh.com',
  'mangaread.org',
  'mangadna.com',
  'mh160mh.com',
  'shenlanqiyu.cc',
  'manga',
  'manhua',
  'comic',
  'webtoon'
];

export const DEFAULT_SEARCH_ENGINES: SearchEngineConfig[] = [
  {
    id: 'bing_web_html',
    name: 'Bing 网页结果',
    description: '无 API Key 模式，读取 Bing 普通网页搜索结果页；会过滤短视频、百科、词典、社区和购物等非漫画结果。',
    engineType: 'bing-html',
    searchUrl: 'https://www.bing.com/search?q={query}',
    requiresKey: false,
    enabled: true
  },
  {
    id: 'duckduckgo_html',
    name: 'DuckDuckGo 网页结果',
    description: '无 API Key 模式，读取 DuckDuckGo HTML/Lite 公开搜索结果；会过滤短视频、百科、词典、社区和购物等非漫画结果。',
    engineType: 'duckduckgo-html',
    searchUrl: 'https://duckduckgo.com/html/?q={query}',
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
    enabled: false
  },
  {
    id: 'google_cse_api',
    name: 'Google Programmable Search API',
    description: '官方 Google Programmable Search JSON API，需要 API Key 和 CX。',
    engineType: 'google-cse-api',
    searchUrl: 'https://www.googleapis.com/customsearch/v1?key={googleKey}&cx={googleCx}&q={query}&num=10',
    requiresKey: true,
    enabled: false
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
    .replace(/&#x3D;/g, '=')
    .replace(/&#x2B;/g, '+')
    .replace(/&#x25;/g, '%')
    .replace(/&#(\d+);/g, (_m: string, code: string): string => {
      const value = Number.parseInt(code, 10);
      if (Number.isFinite(value) && value > 0) {
        return String.fromCharCode(value);
      }
      return ' ';
    })
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

function hostOf(url: string): string {
  let value = url.toLowerCase().trim();
  const protocolIndex = value.indexOf('://');
  if (protocolIndex >= 0) {
    value = value.substring(protocolIndex + 3);
  }
  const slashIndex = value.indexOf('/');
  if (slashIndex >= 0) {
    value = value.substring(0, slashIndex);
  }
  if (value.startsWith('www.')) {
    value = value.substring(4);
  }
  return value;
}

function containsAny(text: string, values: string[]): boolean {
  const lower = text.toLowerCase();
  for (let i = 0; i < values.length; i++) {
    if (lower.indexOf(values[i].toLowerCase()) >= 0) {
      return true;
    }
  }
  return false;
}

function keywordAliases(keyword: string): string[] {
  const raw = keyword.trim();
  const lower = raw.toLowerCase();
  const aliases: string[] = [];
  if (raw.length > 0) {
    aliases.push(raw);
  }
  if (raw === '斗罗' || raw === '斗罗大陆' || lower.indexOf('douluo') >= 0 || lower.indexOf('soul land') >= 0) {
    aliases.push('斗罗大陆');
    aliases.push('斗罗');
    aliases.push('Soul Land');
    aliases.push('Douluo Dalu');
  }
  return aliases;
}

function hasKeywordMatch(title: string, url: string, desc: string, keyword: string): boolean {
  const text = (title + ' ' + url + ' ' + desc).toLowerCase();
  const aliases = keywordAliases(keyword);
  for (let i = 0; i < aliases.length; i++) {
    const alias = aliases[i].toLowerCase().trim();
    if (alias.length > 0 && text.indexOf(alias) >= 0) {
      return true;
    }
  }
  return false;
}

function isPreferredComicDomain(url: string): boolean {
  const host = hostOf(url);
  return containsAny(host, PREFERRED_COMIC_DOMAINS);
}

function isBlockedSearchResult(title: string, url: string, desc: string): boolean {
  const lowerUrl = url.toLowerCase();
  const host = hostOf(url);
  const text = (title + ' ' + desc + ' ' + url).toLowerCase();
  if (containsAny(host, BLOCKED_SEARCH_DOMAINS) || containsAny(lowerUrl, BLOCKED_SEARCH_DOMAINS)) {
    return true;
  }
  if (containsAny(text, BLOCKED_SEARCH_WORDS) && !isPreferredComicDomain(url)) {
    return true;
  }
  return false;
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
  if (lower.indexOf('/aclick?') >= 0 || lower.indexOf('/ads/') >= 0 || lower.indexOf('doubleclick.net') >= 0) {
    return false;
  }
  return true;
}

function looksComicRelated(title: string, url: string, desc: string, keyword: string): boolean {
  const text = (title + ' ' + url + ' ' + desc).toLowerCase();
  if (isPreferredComicDomain(url) && hasKeywordMatch(title, url, desc, keyword)) {
    return true;
  }
  if (!hasKeywordMatch(title, url, desc, keyword)) {
    return false;
  }
  return /(comic|comics|manga|manhua|manhwa|webtoon|webcomic|graphic novel|chapter|read|reader|episode|scan|漫画|漫话|章节|在线|阅读|マンガ|漫画家|코믹|만화)/i.test(text);
}

function makeSearchItem(title: string, url: string, engine: SearchEngineConfig, keyword: string, desc: string, strict: boolean): SearchResultItem | null {
  const cleanTitle = cleanHtmlText(decodeEntities(title));
  const cleanDesc = cleanHtmlText(decodeEntities(desc));
  const cleanUrl = stripRedirect(url);
  if (cleanTitle.length === 0 || !isUsefulUrl(cleanUrl)) {
    return null;
  }
  if (isBlockedSearchResult(cleanTitle, cleanUrl, cleanDesc)) {
    return null;
  }
  if (strict && !looksComicRelated(cleanTitle, cleanUrl, cleanDesc, keyword)) {
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
    description: cleanDesc.length > 0 ? cleanDesc : '搜索引擎发现的公开漫画网页结果，点击后进入公开HTML解析链路。',
    category: '漫画'
  };
}

export function buildEngineQuery(keyword: string, extraTerms: string, languageMode: string, siteHint: string): string {
  let query = keyword.trim();
  if (query === '斗罗') {
    query = '斗罗大陆 OR "Soul Land" OR "Douluo Dalu"';
  }
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
  query += ' -抖音 -短视频 -视频 -动画 -电视剧 -百科 -词典 -字典 -汉语 -国学 -拼音 -解释 -贴吧 -知乎 -小红书 -微博 -douyin -tiktok -bilibili -youtube -wiki';
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

function addParsedItem(items: SearchResultItem[], title: string, url: string, engine: SearchEngineConfig, keyword: string, desc: string, strict: boolean): void {
  const item = makeSearchItem(title, url, engine, keyword, desc, strict);
  if (item !== null && !items.some((old: SearchResultItem) => old.url === item.url)) {
    items.push(item);
  }
}

function parseByPatterns(html: string, engine: SearchEngineConfig, keyword: string, baseUrl: string, strict: boolean): SearchResultItem[] {
  const items: SearchResultItem[] = [];
  const patterns: RegExp[] = [
    /<li[^>]+class=["'][^"']*b_algo[^"']*["'][\s\S]*?<h2[^>]*>[\s\S]*?<a[^>]+href=["']([^"']+)["'][^>]*>([\s\S]{1,360}?)<\/a>[\s\S]*?<p[^>]*>([\s\S]{0,520}?)<\/p>[\s\S]*?<\/li>/gim,
    /<li[^>]+class=["'][^"']*b_algo[^"']*["'][\s\S]*?<h2[^>]*>[\s\S]*?<a[^>]+href=["']([^"']+)["'][^>]*>([\s\S]{1,360}?)<\/a>[\s\S]*?<\/li>/gim,
    /<a[^>]+class=["'][^"']*(?:result__a|result-link|result-title|organic__url|serp-item__title-link)[^"']*["'][^>]+href=["']([^"']+)["'][^>]*>([\s\S]{1,360}?)<\/a>/gim,
    /<a[^>]+href=["']([^"']+)["'][^>]+class=["'][^"']*(?:result__a|result-link|result-title|organic__url|serp-item__title-link)[^"']*["'][^>]*>([\s\S]{1,360}?)<\/a>/gim,
    /<h2[^>]*>[\s\S]*?<a[^>]+href=["']([^"']+)["'][^>]*>([\s\S]{1,360}?)<\/a>[\s\S]*?<\/h2>/gim,
    /<h3[^>]*>[\s\S]*?<a[^>]+href=["']([^"']+)["'][^>]*>([\s\S]{1,360}?)<\/a>[\s\S]*?<\/h3>/gim,
    /<a[^>]+href=["']((?:https?:\/\/|\/url\?q=|\/l\/\?kh=|[^"']*uddg=)[^"']+)["'][^>]*>([\s\S]{1,300}?)<\/a>/gim
  ];
  for (let p = 0; p < patterns.length; p++) {
    const regex = patterns[p];
    let match = regex.exec(html);
    let guard = 0;
    while (match !== null && guard < 180) {
      guard++;
      const desc = match.length > 3 ? match[3] : '';
      addParsedItem(items, match[2], resolveUrl(match[1], baseUrl), engine, keyword, desc, strict);
      if (regex.lastIndex === match.index) {
        regex.lastIndex++;
      }
      match = regex.exec(html);
    }
  }
  return items;
}

function parseGenericHtmlResults(html: string, engine: SearchEngineConfig, keyword: string, baseUrl: string): SearchResultItem[] {
  const strictItems = parseByPatterns(html, engine, keyword, baseUrl, true);
  if (strictItems.length > 0) {
    return strictItems.slice(0, 30);
  }
  const looseItems = parseByPatterns(html, engine, keyword, baseUrl, false);
  return looseItems.slice(0, 12);
}

function parseGoogleCseResults(jsonText: string, engine: SearchEngineConfig, keyword: string): SearchResultItem[] {
  const items: SearchResultItem[] = [];
  const blocks = extractObjectArrayByKey(jsonText, 'items');
  for (let i = 0; i < blocks.length && i < 30; i++) {
    const title = readJsonString(blocks[i], 'title');
    const link = readJsonString(blocks[i], 'link');
    const snippet = readJsonString(blocks[i], 'snippet');
    addParsedItem(items, title, link, engine, keyword, snippet, true);
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
    addParsedItem(items, title, url, engine, keyword, desc, true);
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
