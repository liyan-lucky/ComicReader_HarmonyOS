import { SearchEngineConfig, SearchResultItem } from '../model/ComicModels';
import { resolveUrl } from './UrlUtil';
import { cleanHtmlText } from './HtmlParser';

const SEARCH_UA = 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

let searchResultFilterMode: string = 'rule_filter';

export function setSearchResultFilterMode(mode: string): void {
  searchResultFilterMode = mode === 'browser' ? 'browser' : 'rule_filter';
}

interface SearchFilterConfig {
  blockedDomains: string[];
  blockedWords: string[];
  noiseTitleWords: string[];
  officialComicDomains: string[];
  preferredComicDomains: string[];
}

export const searchFilterConfig: SearchFilterConfig = {
  blockedDomains: [
    'iqiyi.com', 'youku.com', 'v.qq.com', 'sohu.com', 'v.baidu.com',
    'bilibili.com/video', 'douyin.com', 'kuaishou.com', 'zhihu.com',
    '.edu.', 'coursera', 'udemy', 'zhangmen.com', 'zhangmenbaby.com'
  ] as string[],
  blockedWords: [
    '教育', '培训', '课程', '辅导', '网课', '一对一', '考研', '公务员', '职业培训', '英语培训'
  ] as string[],
  noiseTitleWords: [] as string[],
  officialComicDomains: [
    'ac.qq.com/', 'kuaikanmanhua.com/', 'manga.bilibili.com/', 'bilibili.com/manga',
    'bilibilicomics.com/', 'u17.com/', 'manhuadao', 'dongmanmanhua.cn/', 'acg.sohu.com/'
  ] as string[],
  preferredComicDomains: [
    'ac.qq.com', 'kuaikanmanhua.com', 'manga.bilibili.com', 'bilibilicomics.com', 'u17.com', 'acg.sohu.com',
    'manhuadao.cn', 'dongmanmanhua.cn', 'soullandmanga.com', 'kaixinman.com', 'manhuaus.com', 'mangafire.to', 'mgeko.cc', 'happymh.com',
    'mangaread.org', 'mangadna.com', 'mh160mh.com', 'shenlanqiyu.cc', 'manga', 'manhua', 'comic', 'webtoon'
  ] as string[]
};

export const DEFAULT_SEARCH_ENGINES: SearchEngineConfig[] = [
  { id: 'duckduckgo_html', name: 'DuckDuckGo', description: '无 API Key 模式，读取 DuckDuckGo HTML/Lite 搜索结果；过滤短视频、百科、词典、社区和购物等非漫画结果。', engineType: 'duckduckgo-html', searchUrl: 'https://html.duckduckgo.com/html/?q={query}', requiresKey: false, enabled: true },
  { id: 'bing_web_html', name: 'Bing', description: '无 API Key 模式，读取 Bing 网页搜索结果；过滤短视频、百科、词典、社区和购物等非漫画结果。', engineType: 'bing-html', searchUrl: 'https://cn.bing.com/search?q={query}', requiresKey: false, enabled: true },
  { id: 'baidu_web_html', name: '百度', description: '中文公开网页搜索，用于补充国内漫画平台和聚合站点结果。', engineType: 'baidu-html', searchUrl: 'https://www.baidu.com/s?rn=50&wd={query}', requiresKey: false, enabled: true },
  { id: 'sogou_web_html', name: '搜狗', description: '中文公开网页搜索，用于补充书名别名和国内站点结果。', engineType: 'sogou-html', searchUrl: 'https://www.sogou.com/web?num=30&query={query}', requiresKey: false, enabled: true },
  { id: 'so_web_html', name: '360', description: '中文公开网页搜索，作为国内漫画资源召回补充。', engineType: 'so-html', searchUrl: 'https://www.so.com/s?q={query}', requiresKey: false, enabled: true },
  { id: 'google_web_html', name: 'Google', description: '读取 Google 普通网页结果页；稳定性取决于网络与搜索页是否允许直接访问。', engineType: 'google-html', searchUrl: 'https://www.google.com/search?q={query}', requiresKey: false, enabled: true },
  { id: 'yandex_web_html', name: 'Yandex', description: '读取 Yandex 网页搜索结果页，适合英文/多语言兜底检索。', engineType: 'yandex-html', searchUrl: 'https://yandex.com/search/?text={query}', requiresKey: false, enabled: true },
  { id: 'brave_search_api', name: 'Brave API', description: '官方 Brave Search API，需要在设置里填写 API Key。', engineType: 'brave-api', searchUrl: 'https://api.search.brave.com/res/v1/web/search?q={query}&count=20', requiresKey: true, enabled: false },
  { id: 'google_cse_api', name: 'Google API', description: '官方 Google Programmable Search JSON API，需要 API Key 和 CX。', engineType: 'google-cse-api', searchUrl: 'https://www.googleapis.com/customsearch/v1?key={googleKey}&cx={googleCx}&q={query}&num=10', requiresKey: true, enabled: false }
];

export function searchEngineUserAgent(): string { return SEARCH_UA; }

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
      return Number.isFinite(value) && value > 0 ? String.fromCharCode(value) : ' ';
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
  if (keyIndex < 0) return '';
  const start = jsonText.indexOf('[', keyIndex);
  if (start < 0) return '';
  let depth = 0;
  let inString = false;
  let escaped = false;
  for (let i = start; i < jsonText.length; i++) {
    const ch = jsonText.charAt(i);
    if (escaped) { escaped = false; continue; }
    if (ch === '\\') { escaped = true; continue; }
    if (ch === '"') { inString = !inString; continue; }
    if (!inString && ch === '[') depth++;
    if (!inString && ch === ']') {
      depth--;
      if (depth === 0) return jsonText.substring(start + 1, i);
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
    if (escaped) { escaped = false; continue; }
    if (ch === '\\') { escaped = true; continue; }
    if (ch === '"') { inString = !inString; continue; }
    if (!inString && ch === '{') {
      if (depth === 0) start = i;
      depth++;
    } else if (!inString && ch === '}') {
      depth--;
      if (depth === 0 && start >= 0) {
        objects.push(arr.substring(start, i + 1));
        start = -1;
      }
    }
  }
  return objects;
}

function readJsonString(block: string, key: string): string {
  const regex = new RegExp('"' + key + '"\\s*:\\s*"((?:\\\\.|[^"\\\\])*)"', 'im');
  const match = regex.exec(block);
  return match && match.length > 1 ? jsonUnescape(match[1]) : '';
}

function stripRedirect(url: string): string {
  let next = decodeEntities(url.trim());
  if (next.startsWith('/url?') || next.indexOf('/url?q=') >= 0) {
    const q = /[?&]q=([^&]+)/.exec(next);
    if (q && q.length > 1) next = decodeURIComponent(q[1]);
  }
  const uddg = /[?&]uddg=([^&]+)/.exec(next);
  if (uddg && uddg.length > 1) next = safeDecodeUrlComponent(uddg[1]);
  // Mobile search pages expose the destination in an encoded url/pcurl
  // parameter. Keeping the tracker URL makes a valid result look like
  // another search page, so it is filtered before it reaches the UI.
  const target = /[?&](?:url|pcurl)=([^&]+)/i.exec(next);
  if (target && target.length > 1) next = safeDecodeUrlComponent(target[1]);
  // Baidu mobile redirect: m.baidu.com/from=.../url=ENCODED_TARGET
  const baiduRedirect = /m\.baidu\.com\/.*\/url=([^&]+)/i.exec(next);
  if (baiduRedirect && baiduRedirect.length > 1) {
    const decoded = safeDecodeUrlComponent(baiduRedirect[1]);
    if (decoded.startsWith('http')) next = decoded;
  }
  if (next.startsWith('//')) next = 'https:' + next;
  return next;
}

function safeDecodeUrlComponent(value: string): string {
  try {
    return decodeURIComponent(value);
  } catch (_err) {
    return value;
  }
}

function hostOf(url: string): string {
  let value = url.toLowerCase().trim();
  const protocolIndex = value.indexOf('://');
  if (protocolIndex >= 0) value = value.substring(protocolIndex + 3);
  const slashIndex = value.indexOf('/');
  if (slashIndex >= 0) value = value.substring(0, slashIndex);
  return value.startsWith('www.') ? value.substring(4) : value;
}

function containsAny(text: string, values: string[]): boolean {
  const lower = text.toLowerCase();
  for (let i = 0; i < values.length; i++) {
    if (lower.indexOf(values[i].toLowerCase()) >= 0) return true;
  }
  return false;
}

function keywordAliases(keyword: string): string[] {
  const raw = keyword.trim();
  const lower = raw.toLowerCase();
  const aliases: string[] = [];
  if (raw.length > 0) aliases.push(raw);
  if (raw === '斗罗' || raw === '斗罗大陆' || lower.indexOf('douluo') >= 0 || lower.indexOf('soul land') >= 0) {
    aliases.push('斗罗大陆');
    aliases.push('斗罗');
    aliases.push('Soul Land');
    aliases.push('Douluo Dalu');
  }
  return aliases;
}

function normalizedSearchText(value: string): string {
  return value.toLowerCase()
    .replace(/[\s\-_|\u2014\u2013\u00b7\u300a\u300b\u201c\u201d"'\uff0c\u3002\uff01\uff1f\u3001:\uff1a()\uff08\uff09\[\]\u3010\u3011]/g, '')
    .replace(/(?:\u6f2b\u753b|\u5168\u96c6|\u5728\u7ebf|\u514d\u8d39|\u9605\u8bfb|\u4e0b\u62c9\u5f0f)$/g, '');
}

function withinOneEdit(left: string, right: string): boolean {
  if (left === right) return true;
  if (left.length < 4 || right.length < 4 || Math.abs(left.length - right.length) > 1) return false;
  let i = 0;
  let j = 0;
  let edits = 0;
  while (i < left.length && j < right.length) {
    if (left.charAt(i) === right.charAt(j)) {
      i++;
      j++;
      continue;
    }
    edits++;
    if (edits > 1) return false;
    if (left.length > right.length) i++;
    else if (right.length > left.length) j++;
    else {
      i++;
      j++;
    }
  }
  if (i < left.length || j < right.length) edits++;
  return edits <= 1;
}

function containsWithinOneEdit(text: string, query: string): boolean {
  if (query.length < 4 || text.length < 4) return false;
  if (text.indexOf(query) >= 0) return true;
  const minimum = Math.max(4, query.length - 1);
  const maximum = Math.min(text.length, query.length + 1);
  for (let size = minimum; size <= maximum; size++) {
    for (let start = 0; start + size <= text.length; start++) {
      if (withinOneEdit(text.substring(start, start + size), query)) return true;
    }
  }
  return false;
}

function hasKeywordMatch(title: string, url: string, desc: string, keyword: string): boolean {
  const text = (title + ' ' + url + ' ' + desc).toLowerCase();
  const normalizedTitle = normalizedSearchText(title);
  const aliases = keywordAliases(keyword);
  for (let i = 0; i < aliases.length; i++) {
    const alias = aliases[i].toLowerCase().trim();
    if (alias.length > 0 && text.indexOf(alias) >= 0) return true;
    if (containsWithinOneEdit(normalizedTitle, normalizedSearchText(alias))) return true;
  }
  return false;
}

function isPreferredComicDomain(url: string): boolean { return containsAny(hostOf(url), searchFilterConfig.preferredComicDomains); }

function isBroadDiscoveryKeyword(keyword: string): boolean {
  const value = normalizedSearchText(keyword);
  return /^(恋爱|爱情|言情|玄幻|奇幻|异能|恐怖|剧情|科幻|悬疑|冒险|犯罪|动作|日常|竞技|武侠|历史|战争|校园|都市|霸总|热血|搞笑|国漫|漫画|全部)$/.test(value);
}

function isBlockedSearchResult(title: string, url: string, desc: string): boolean {
  const lowerUrl = url.toLowerCase();
  const host = hostOf(url);
  const text = (title + ' ' + desc + ' ' + url).toLowerCase();
  
  // Official comic sections remain valid search resources even when their
  // parent domain also hosts video/community content or requires login/pay.
  let officialComic = false;
  for (let i = 0; i < searchFilterConfig.officialComicDomains.length; i++) {
    if (lowerUrl.indexOf(searchFilterConfig.officialComicDomains[i]) >= 0) { officialComic = true; break; }
  }

  // 搜索引擎结果页面白名单：m.baidu.com / www.baidu.com/s? 等搜索页可能包含漫画链接，不屏蔽
  const isSearchResultPage = host === 'm.baidu.com' || host === 'www.baidu.com' ||
    lowerUrl.indexOf('cn.bing.com/search') >= 0 || lowerUrl.indexOf('www.baidu.com/s?') >= 0 ||
    lowerUrl.indexOf('m.baidu.com/from=') >= 0;
  
  if (!officialComic && !isSearchResultPage && (containsAny(host, searchFilterConfig.blockedDomains) || containsAny(lowerUrl, searchFilterConfig.blockedDomains))) return true;
  if (containsAny(text, searchFilterConfig.blockedWords) && !isPreferredComicDomain(url) && !isSearchResultPage) return true;
  
  // 智能URL模式识别：自动过滤搜索引擎内部页面
  // 匹配模式：searchengine.com/help, searchengine.com/fankui, searchengine.com/pic 等
  if (/(?:help|fankui|pic|weixin|fanyi|support|contact|about|terms|privacy|cookies|faq|sitemap|archive)\.[a-z]+\.[a-z]+(?:\/|$)/i.test(url)) return true;
  // 匹配模式：searchengine.com/search?q=..., searchengine.com/web?query=..., searchengine.com/html/?q=...
  if (/\/(?:search|web|s|html)(?:\/)?\?(?:query|q|wd|word|text|keyword)=/i.test(url) && /(?:sogou\.|baidu\.|so\.|bing\.|duckduckgo\.|google\.|yandex\.)/i.test(host)) return true;
  
  return false;
}

function isUsefulUrl(url: string): boolean {
  const lower = url.toLowerCase();
  const host = hostOf(url);
  if (!(lower.startsWith('http://') || lower.startsWith('https://'))) return false;
  if (lower.indexOf('google.') >= 0 && (lower.indexOf('/search') >= 0 || lower.indexOf('/preferences') >= 0 || lower.indexOf('/policies') >= 0)) return false;
  if (lower.indexOf('bing.com/search') >= 0 || lower.indexOf('duckduckgo.com') >= 0 || lower.indexOf('yandex.com/search') >= 0) return false;
  // Search-result redirect pages are not comic sources. Keeping them makes a
  // click parse another search page as a comic detail page, and relative
  // chapter/image links are then resolved against the wrong host.
  if (host === 'm.so.com' || host === 'so.com' || host === 'www.so.com' ||
    host === 'sogou.com' || host === 'www.sogou.com' || host === 'm.sogou.com') return false;
  if (lower.indexOf('javascript:') >= 0 || lower.indexOf('mailto:') >= 0 || lower.indexOf('tel:') >= 0) return false;
  if (lower.indexOf('/aclick?') >= 0 || lower.indexOf('/ads/') >= 0 || lower.indexOf('doubleclick.net') >= 0) return false;
  return true;
}

function canonicalSearchTitle(raw: string, keyword: string): string {
  let title = cleanHtmlText(decodeEntities(raw)).replace(/\s+/g, ' ').trim();
  const quoted = /《\s*([^》]{1,80})\s*》/.exec(title);
  if (quoted && quoted.length > 1) title = quoted[1].trim();
  title = title
    .replace(/\s*(?:[-_|—–·]\s*)?(?:漫画)?(?:全集)?(?:免费)?(?:在线)?阅读.*$/i, '')
    .replace(/\s*第\s*[0-9一二三四五六七八九十百千零〇两]+\s*(?:话|章|回|卷).*$/i, '')
    .replace(/\s*(?:腾讯动漫|快看漫画|哔哩哔哩漫画|漫画岛|看漫画)(?:官网)?\s*.*$/i, '')
    .replace(/\s+(?:图片|举报|帮助|百科|贴吧|知道|经验|视频|下载|登录|注册|关于|反馈|设置|意见|投诉|版权|免责|隐私|条款|协议).*$/i, '')
    .replace(/\s*[-_|—–·]\s*$/i, '')
    .replace(/\s+/g, ' ').trim();
  if (title.length === 0) return '';
  if (title.length > 96) return '';
  return title;
}

function containsNoiseTitleWord(title: string): boolean {
  const cleaned = title.trim();
  if (cleaned.length === 0) return true;
  for (let i = 0; i < searchFilterConfig.noiseTitleWords.length; i++) {
    const noise = searchFilterConfig.noiseTitleWords[i];
    if (cleaned === noise || cleaned.startsWith(noise) ||
        cleaned.endsWith(' ' + noise) || cleaned.endsWith('-' + noise) || cleaned.endsWith('—' + noise)) {
      return true;
    }
  }
  return false;
}

function looksComicRelated(title: string, url: string, desc: string, keyword: string): boolean {
  const text = (title + ' ' + url + ' ' + desc).toLowerCase();
  const cleanTitle = title.trim();

  // 0. 非漫画域名和屏蔽词已移至 searchFilterConfig，由 isBlockedSearchResult 统一处理

  // 1. 过滤标题中的噪音词（图片、举报、帮助、百科等非漫画内容）
  if (containsNoiseTitleWord(title)) return false;
  
  // 2. 智能过滤纯URL形式的标题（但漫画网站的URL不过滤）
  // 匹配以域名结尾的形式：https://example.com, https://example.com/page.html, example.com 等
  const isPureUrl = /^https?:\/\/[^\s]+\.(com|cn|net|org|io|co|info|biz|xyz|top|club|vip|pro|shop|store|app|site|page|web)(\/|$)/i.test(cleanTitle);
  const isPureDomain = /^[^\s]+\.(com|cn|net|org|io|co|info|biz|xyz|top|club|vip|pro|shop|store|app|site|page|web)$/i.test(cleanTitle);
  if ((isPureUrl || isPureDomain) && !isPreferredComicDomain(url)) return false;
  
  // 3. 智能过滤过短且无中文的标题
  if (cleanTitle.length < 4 && !/[\u4e00-\u9fa5]/.test(title)) return false;
  
  // 4. 智能URL模式识别：过滤搜索引擎内部页面
  if (/(?:help|fankui|pic|weixin|fanyi|support|contact|about|terms|privacy|cookies|faq|sitemap|archive)\.[a-z]+\.[a-z]+(?:\/|$)/i.test(url)) return false;
  
  // 5. 智能过滤包含明显非漫画关键词的内容（基于内容特征而非硬编码列表）
  // 过滤工具类、技术类、管理类页面
  const toolKeywords = /\b(help|support|contact|about|terms|privacy|cookies|faq|sitemap|archive|category|tag|search|filter|sort|page|pagination|load|update|save|submit|upload|print|pdf|json|xml|zip|rar|exe|app|css|js|html|react|vue|angular|node|electron|flutter)\b/i;
  const comicKeywords = /(?:comic|comics|manga|manhua|manhwa|webtoon|webcomic|chapter|read|reader|episode|scan|漫画|漫话|章节|在线阅读|在线看|阅读|下拉式|免费漫画|看漫画|动漫)/i;
  // 检查title和text，但title中的工具类关键词优先级更高
  if (toolKeywords.test(title) && !comicKeywords.test(title)) return false;
  // 5b. 过滤教育/培训等非漫画内容（但标题同时含漫画词时保留）— 使用可配置的 blockedWords
  if (containsAny(title.toLowerCase(), searchFilterConfig.blockedWords) && !comicKeywords.test(title)) return false;
  
  // 6. 基于可信度的评分系统
  if (isBroadDiscoveryKeyword(keyword)) {
    if (isPreferredComicDomain(url)) return true;
    return /(comic|comics|manga|manhua|manhwa|webtoon|webcomic|graphic novel|chapter|read|reader|episode|scan|漫画|漫话|章节|在线阅读|在线看|阅读|下拉式|免费漫画|看漫画|动漫)/i.test(text);
  }
  if (isPreferredComicDomain(url) && hasKeywordMatch(title, url, desc, keyword)) return true;
  if (!hasKeywordMatch(title, url, desc, keyword)) return false;
  return /(comic|comics|manga|manhua|manhwa|webtoon|webcomic|graphic novel|chapter|read|reader|episode|scan|漫画|漫话|章节|在线阅读|在线看|阅读|マンガ|漫画家|코믹|만화)/i.test(text);
}

export function buildDebugMatchInfo(title: string, url: string, desc: string, keyword: string): string {
  let result = '域名:' + hostOf(url);
  if (isPreferredComicDomain(url)) result += ' | ✓漫画域名';
  if (hasKeywordMatch(title, url, desc, keyword)) result += ' | ✓关键词匹配';
  else result += ' | ✗关键词不匹配';
  const comicRe = /(?:comic|comics|manga|manhua|manhwa|webtoon|webcomic|chapter|read|reader|episode|scan|漫画|漫话|章节|在线阅读|在线看|阅读|下拉式|免费漫画|看漫画|动漫|マンガ|漫画家|코믹|만화)/i;
  if (comicRe.test((title + ' ' + url + ' ' + desc).toLowerCase())) result += ' | ✓含漫画词';
  if (looksComicRelated(title, url, desc, keyword)) result += ' | ✓漫画相关';
  else result += ' | ✗非漫画相关';
  return result;
}

function makeSearchItem(title: string, url: string, engine: SearchEngineConfig, keyword: string, desc: string): SearchResultItem | null {
  const cleanTitle = canonicalSearchTitle(title, keyword);
  const cleanDesc = cleanHtmlText(decodeEntities(desc));
  const cleanUrl = stripRedirect(url);
  if (cleanTitle.length === 0 || !isUsefulUrl(cleanUrl)) return null;
  if (searchResultFilterMode !== 'browser') {
    if (isBlockedSearchResult(cleanTitle, cleanUrl, cleanDesc)) return null;
    if (!looksComicRelated(cleanTitle, cleanUrl, cleanDesc, keyword)) return null;
  }
  const debugInfo = buildDebugMatchInfo(cleanTitle, cleanUrl, cleanDesc, keyword);
  return { title: cleanTitle, url: cleanUrl, cover: '', sourceId: engine.id, sourceName: engine.name, isChapter: false, resultType: 'search-engine', groupName: cleanTitle, description: cleanDesc.length > 0 ? cleanDesc : '搜索引擎发现的公开漫画网页结果，点击后进入公开HTML解析链路。', category: '漫画', debugMatchInfo: debugInfo };
}

export function buildEngineQuery(keyword: string, extraTerms: string, languageMode: string, siteHint: string): string {
  let query = keyword.trim();
  if (extraTerms.trim().length > 0) query += ' ' + extraTerms.trim();
  if (siteHint.trim().length > 0) query += ' ' + siteHint.trim();
  return query.replace(/\s+/g, ' ').trim();
}

export function buildSearchEngineUrl(engine: SearchEngineConfig, query: string, braveKey: string, googleKey: string, googleCx: string): string {
  const encoded = encodeURIComponent(query);
  return engine.searchUrl.replace('{query}', encoded).replace('{googleKey}', encodeURIComponent(googleKey.trim())).replace('{googleCx}', encodeURIComponent(googleCx.trim())).replace('{braveKey}', encodeURIComponent(braveKey.trim()));
}

export function isEngineConfigured(engine: SearchEngineConfig, braveKey: string, googleKey: string, googleCx: string): boolean {
  if (!engine.requiresKey) return true;
  if (engine.engineType === 'brave-api') return braveKey.trim().length > 0;
  if (engine.engineType === 'google-cse-api') return googleKey.trim().length > 0 && googleCx.trim().length > 0;
  return false;
}

export function engineHeaders(engine: SearchEngineConfig, braveKey: string): Record<string, string> {
  const headers: Record<string, string> = {};
  if (engine.engineType === 'brave-api' && braveKey.trim().length > 0) { headers['X-Subscription-Token'] = braveKey.trim(); headers['Accept'] = 'application/json'; }
  return headers;
}

function addParsedItem(items: SearchResultItem[], title: string, url: string, engine: SearchEngineConfig, keyword: string, desc: string): void {
  const item = makeSearchItem(title, url, engine, keyword, desc);
  if (item !== null && !items.some((old: SearchResultItem) => old.url === item.url)) items.push(item);
}

function parseByPatterns(html: string, engine: SearchEngineConfig, keyword: string, baseUrl: string): SearchResultItem[] {
  const items: SearchResultItem[] = [];
  const patterns: RegExp[] = [
    // Bing patterns
    /<li[^>]+class=["'][^"']*b_algo[^"']*["'][\s\S]*?<h2[^>]*>[\s\S]*?<a[^>]+href=["']([^"']+)["'][^>]*>([\s\S]{1,360}?)<\/a>[\s\S]*?<p[^>]*>([\s\S]{0,520}?)<\/p>[\s\S]*?<\/li>/gim,
    /<li[^>]+class=["'][^"']*b_algo[^"']*["'][\s\S]*?<h2[^>]*>[\s\S]*?<a[^>]+href=["']([^"']+)["'][^>]*>([\s\S]{1,360}?)<\/a>[\s\S]*?<\/li>/gim,
    /<a[^>]+class=["'][^"']*(?:result__a|result-link|resultLink|result-title|organic__url|serp-item__title-link|vr-title|res-title|c-title|result_title)[^"']*["'][^>]+href=["']([^"']+)["'][^>]*>([\s\S]{1,360}?)<\/a>/gim,
    /<a[^>]+href=["']([^"']+)["'][^>]+class=["'][^"']*(?:result__a|result-link|resultLink|result-title|organic__url|serp-item__title-link|vr-title|res-title|c-title|result_title)[^"']*["'][^>]*>([\s\S]{1,360}?)<\/a>/gim,
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
      const desc = match.length > 3 ? match[3] : engine.description;
      addParsedItem(items, match[2], resolveUrl(match[1], baseUrl), engine, keyword, desc);
      if (regex.lastIndex === match.index) regex.lastIndex++;
      match = regex.exec(html);
    }
  }
  return items;
}

function parseGenericHtmlResults(html: string, engine: SearchEngineConfig, keyword: string, baseUrl: string): SearchResultItem[] {
  const items = parseByPatterns(html, engine, keyword, baseUrl);
  return items.slice(0, 30);
}

function parseGoogleCseResults(jsonText: string, engine: SearchEngineConfig, keyword: string): SearchResultItem[] {
  const items: SearchResultItem[] = [];
  const blocks = extractObjectArrayByKey(jsonText, 'items');
  for (let i = 0; i < blocks.length && i < 30; i++) addParsedItem(items, readJsonString(blocks[i], 'title'), readJsonString(blocks[i], 'link'), engine, keyword, readJsonString(blocks[i], 'snippet'));
  return items;
}

function parseBraveResults(jsonText: string, engine: SearchEngineConfig, keyword: string): SearchResultItem[] {
  const items: SearchResultItem[] = [];
  const blocks = extractObjectArrayByKey(jsonText, 'results');
  for (let i = 0; i < blocks.length && i < 50; i++) addParsedItem(items, readJsonString(blocks[i], 'title'), readJsonString(blocks[i], 'url'), engine, keyword, readJsonString(blocks[i], 'description'));
  return items;
}

export function parseSearchEngineResults(body: string, engine: SearchEngineConfig, keyword: string, searchUrl: string): SearchResultItem[] {
  if (engine.engineType === 'google-cse-api') return parseGoogleCseResults(body, engine, keyword);
  if (engine.engineType === 'brave-api') return parseBraveResults(body, engine, keyword);
  return parseGenericHtmlResults(body, engine, keyword, searchUrl);
}
