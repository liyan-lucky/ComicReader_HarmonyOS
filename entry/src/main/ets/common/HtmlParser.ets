import { ComicSourceRule, SearchResultItem, ChapterItem, ReaderImageItem } from '../model/ComicModels';
import { resolveUrl, isHttpUrl } from './UrlUtil';

const B64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

function decodeBase64(input: string): string {
  const cleanInput = input.replace(/[^A-Za-z0-9+/=]/g, '');
  const padding = cleanInput.endsWith('==') ? 2 : (cleanInput.endsWith('=') ? 1 : 0);
  const length = cleanInput.length - padding;
  const bytes: number[] = [];
  for (let i = 0; i < length; i += 4) {
    const c0 = B64_CHARS.indexOf(cleanInput[i]);
    const c1 = B64_CHARS.indexOf(cleanInput[i + 1]);
    const c2 = i + 2 < length ? B64_CHARS.indexOf(cleanInput[i + 2]) : 0;
    const c3 = i + 3 < length ? B64_CHARS.indexOf(cleanInput[i + 3]) : 0;
    if (c0 < 0 || c1 < 0) break;
    bytes.push((c0 << 2) | (c1 >> 4));
    if (i + 2 < length && c2 >= 0) {
      bytes.push(((c1 & 0x0F) << 4) | (c2 >> 2));
    }
    if (i + 3 < length && c3 >= 0) {
      bytes.push(((c2 & 0x03) << 6) | c3);
    }
  }
  let result = '';
  for (let i = 0; i < bytes.length; i++) {
    if (bytes[i] < 128) {
      result += String.fromCharCode(bytes[i]);
    } else if (bytes[i] < 224) {
      if (i + 1 < bytes.length) {
        result += String.fromCharCode(((bytes[i] & 0x1F) << 6) | (bytes[i + 1] & 0x3F));
        i++;
      }
    } else if (bytes[i] < 240) {
      if (i + 2 < bytes.length) {
        result += String.fromCharCode(((bytes[i] & 0x0F) << 12) | ((bytes[i + 1] & 0x3F) << 6) | (bytes[i + 2] & 0x3F));
        i += 2;
      }
    } else {
      if (i + 3 < bytes.length) {
        const codePoint = ((bytes[i] & 0x07) << 18) | ((bytes[i + 1] & 0x3F) << 12) | ((bytes[i + 2] & 0x3F) << 6) | (bytes[i + 3] & 0x3F);
        const adjusted = codePoint - 0x10000;
        result += String.fromCharCode(0xD800 + (adjusted >> 10));
        result += String.fromCharCode(0xDC00 + (adjusted & 0x3FF));
        i += 3;
      }
    }
  }
  return result;
}

function evaluateNonceExpr(expr: string): string {
  const t = expr.trim();
  const ternaryMatch = /^(\d+\.?\d*)<=(\d+\.?\d*)\?(\d+\.?\d*):(\d+\.?\d*)$/.exec(t);
  if (ternaryMatch) {
    return (parseFloat(ternaryMatch[1]) <= parseFloat(ternaryMatch[2]) ?
      parseFloat(ternaryMatch[3]) : parseFloat(ternaryMatch[4])).toString();
  }
  const parseIntMatch = /^parseInt\((\d+\.?\d*)\/(\d+\.?\d*)\)$/.exec(t);
  if (parseIntMatch) {
    return Math.floor(parseFloat(parseIntMatch[1]) / parseFloat(parseIntMatch[2])).toString();
  }
  const mathPowMatch = /^Math\.pow\((\d+\.?\d*),(\d+\.?\d*)\)$/.exec(t);
  if (mathPowMatch) {
    return Math.pow(parseFloat(mathPowMatch[1]), parseFloat(mathPowMatch[2])).toString();
  }
  const mathRoundPlusMatch = /^Math\.round\((\.\d+)\)\s*\+\s*~~(\d+\.?\d*)$/.exec(t);
  if (mathRoundPlusMatch) {
    return (Math.round(parseFloat(mathRoundPlusMatch[1])) +
      Math.floor(parseFloat(mathRoundPlusMatch[2]))).toString();
  }
  const mathRoundMatch = /^Math\.round\((.+)\)$/.exec(t);
  if (mathRoundMatch) {
    const inner = mathRoundMatch[1];
    const dotMatch = /^\.(\d+)$/.exec(inner);
    if (dotMatch) {
      return Math.round(1.0 / parseFloat(dotMatch[1])).toString();
    }
    const numMatch = /^(\d+\.?\d*)$/.exec(inner);
    if (numMatch) {
      return Math.round(parseFloat(numMatch[1])).toString();
    }
  }
  const tildeMatch = /^~~(\d+\.?\d*)$/.exec(t);
  if (tildeMatch) {
    return Math.floor(parseFloat(tildeMatch[1])).toString();
  }
  const doubleNotMatch = /^!!(\d+)$/.exec(t);
  if (doubleNotMatch) {
    return (parseFloat(doubleNotMatch[1]) !== 0 ? 1 : 0).toString();
  }
  const tripleNotMatch = /^!!!(\d+)$/.exec(t);
  if (tripleNotMatch) {
    return (parseFloat(tripleNotMatch[1]) !== 0 ? 0 : 1).toString();
  }
  const notMatch = /^!(\d+)$/.exec(t);
  if (notMatch) {
    return (parseFloat(notMatch[1]) !== 0 ? 0 : 1).toString();
  }
  const doubleNotMulMatch = /^!!(\d+)\*(\d+)$/.exec(t);
  if (doubleNotMulMatch) {
    return ((parseFloat(doubleNotMulMatch[1]) !== 0 ? 1 : 0) *
      parseFloat(doubleNotMulMatch[2])).toString();
  }
  const doubleNotPlusNotMatch = /^!!(\d+)\+!(\d+)\+!!(\d+)\+!!(\d+)\+(\d+)$/.exec(t);
  if (doubleNotPlusNotMatch) {
    const v = (parseFloat(doubleNotPlusNotMatch[1]) !== 0 ? 1 : 0) +
      (parseFloat(doubleNotPlusNotMatch[2]) !== 0 ? 0 : 1) +
      (parseFloat(doubleNotPlusNotMatch[3]) !== 0 ? 1 : 0) +
      (parseFloat(doubleNotPlusNotMatch[4]) !== 0 ? 1 : 0) +
      parseFloat(doubleNotPlusNotMatch[5]);
    return v.toString();
  }
  const plusTripleNotMatch = /^(\d+)\s*\+\s*!!!(\d+)$/.exec(t);
  if (plusTripleNotMatch) {
    return (parseFloat(plusTripleNotMatch[1]) +
      (parseFloat(plusTripleNotMatch[2]) !== 0 ? 0 : 1)).toString();
  }
  const bitwiseAndMatch = /^(\d+)\s*&\s*(\d+)$/.exec(t);
  if (bitwiseAndMatch) {
    return (parseFloat(bitwiseAndMatch[1]) & parseFloat(bitwiseAndMatch[2])).toString();
  }
  const charCodeAtMatch = /^'(\d+)'\.charCodeAt\(\)\s*-\s*(\d+)$/.exec(t);
  if (charCodeAtMatch) {
    return (charCodeAtMatch[1].charCodeAt(0) - parseFloat(charCodeAtMatch[2])).toString();
  }
  const substringMatch = /^'(\d+)'\.substring\((\d+)\)$/.exec(t);
  if (substringMatch) {
    return substringMatch[1].substring(parseFloat(substringMatch[2]));
  }
  const docGetElementsMatch = /^!!document\.getElementsByTagName\('html'\)$/.exec(t);
  if (docGetElementsMatch) {
    return '1';
  }
  const mulDivMatch = /^(\d+\.?\d*)\s*\*\s*(\d+\.?\d*)\s*\/\s*(\d+\.?\d*)$/.exec(t);
  if (mulDivMatch) {
    return (parseFloat(mulDivMatch[1]) * parseFloat(mulDivMatch[2]) /
      parseFloat(mulDivMatch[3])).toString();
  }
  const divPlusMatch = /^(\d+\.?\d*)\/(\d+\.?\d*)\s*\+\s*(\d+\.?\d*)\/(\d+\.?\d*)$/.exec(t);
  if (divPlusMatch) {
    return (parseFloat(divPlusMatch[1]) / parseFloat(divPlusMatch[2]) +
      parseFloat(divPlusMatch[3]) / parseFloat(divPlusMatch[4])).toString();
  }
  const simpleMathMatch = /^(\d+\.?\d*)\s*([+\-*/])\s*(\d+\.?\d*)$/.exec(t);
  if (simpleMathMatch) {
    const a = parseFloat(simpleMathMatch[1]);
    const b = parseFloat(simpleMathMatch[3]);
    const op = simpleMathMatch[2];
    if (op === '+') return (a + b).toString();
    if (op === '-') return (a - b).toString();
    if (op === '*') return (a * b).toString();
    if (op === '/') return (a / b).toString();
  }
  const numOnly = /^(\d+\.?\d*)$/.exec(t);
  if (numOnly) {
    return numOnly[1];
  }
  return '0';
}

function extractNonceFromCode(nonceCode: string): string {
  const eqIdx = nonceCode.indexOf('=');
  if (eqIdx < 0) return '';
  const rightSide = nonceCode.substring(eqIdx + 1).trim();
  const parts: string[] = [];
  const regex = /"([^"]*)"|\(\+eval\("([^"]*)"\)\)\.toString\(\)/g;
  let match = regex.exec(rightSide);
  while (match !== null) {
    if (match[1] !== undefined && match[1].length > 0) {
      parts.push(match[1]);
    } else if (match[2] !== undefined && match[2].length > 0) {
      parts.push(evaluateNonceExpr(match[2]));
    }
    match = regex.exec(rightSide);
  }
  return parts.join('');
}

function decodeAcQqObfuscatedData(rawData: string, nonce: string): string {
  const nonceParts = nonce.match(/\d+[a-zA-Z]+/g);
  if (nonceParts === null || nonceParts.length === 0) {
    return decodeBase64(rawData);
  }
  const chars: string[] = rawData.split('');
  for (let i = nonceParts.length - 1; i >= 0; i--) {
    const part = nonceParts[i];
    const digits = part.replace(/[a-zA-Z]/g, '');
    const letters = part.replace(/\d/g, '');
    const pos = parseInt(digits) & 0xFF;
    const removeLen = letters.length;
    if (pos >= 0 && pos < chars.length && pos + removeLen <= chars.length) {
      chars.splice(pos, removeLen);
    }
  }
  return decodeBase64(chars.join(''));
}

export function parseAcQqAjaxResponse(response: string, pageUrl: string): ReaderImageItem[] {
  const images: ReaderImageItem[] = [];
  const lines = response.split('\n');
  if (lines.length < 2) {
    return images;
  }
  const rawData = lines[0].trim();
  const nonceCode = lines[1].trim();
  const nonce = extractNonceFromCode(nonceCode);
  const jsonStr = decodeAcQqObfuscatedData(rawData, nonce);
  try {
    const data = JSON.parse(jsonStr) as Record<string, Object>;
    const picture = data['picture'] as Object[];
    if (picture !== null && picture !== undefined) {
      for (let i = 0; i < picture.length; i++) {
        const pic = picture[i] as Record<string, string>;
        const rawUrl = pic['url'];
        if (rawUrl !== undefined && rawUrl.length > 0) {
          const cleanedUrl = rawUrl.replace(/\\\//g, '/');
          const url = resolveUrl(cleanedUrl, pageUrl);
          if (url.length > 0 && looksLikeImage(url) &&
            !images.some((item: ReaderImageItem) => item.url === url)) {
            images.push({ url: url, index: images.length + 1, status: 'waiting' });
          }
        }
      }
    }
  } catch (err) {
  }
  return images;
}

function decodeEntities(text: string): string {
  return text
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&#x2F;/g, '/')
    .replace(/&#x3D;/g, '=')
    .replace(/\s+/g, ' ')
    .trim();
}

function normalizeUrlCandidate(text: string): string {
  return decodeEntities(text)
    .replace(/\\u002F/g, '/')
    .replace(/\\\//g, '/')
    .replace(/\\&/g, '&')
    .replace(/^\s+|\s+$/g, '');
}

function extractImageUrlsFromText(text: string, pageUrl: string): string[] {
  const urls: string[] = [];
  const patterns: RegExp[] = [
    /(?:https?:)?\\\/\\\/[^"'\s\]\\]+\.(?:jpg|jpeg|png|webp|gif|avif)(?:\?[^"'\s\]\\]*)?/gim,
    /(?:https?:)?\/\/[^"'\s\]\\]+\.(?:jpg|jpeg|png|webp|gif|avif)(?:\?[^"'\s\]\\]*)?/gim,
    // Keep this expression linear. The former nested `(.../)+...` form could
    // backtrack exponentially on script-heavy pages containing many slash
    // paths but no image extension, freezing ArkTS' main thread long enough
    // for HarmonyOS to terminate the application.
    /\/[^"'\s\]\\]{1,600}\.(?:jpg|jpeg|png|webp|gif|avif)(?:\?[^"'\s\]\\]{0,300})?/gim
  ];
  for (let p = 0; p < patterns.length; p++) {
    let match = patterns[p].exec(text);
    let guard = 0;
    while (match !== null && guard < 300) {
      guard++;
      const normalized = resolveUrl(normalizeUrlCandidate(match[0]), pageUrl);
      if (normalized.length > 0 && urls.indexOf(normalized) < 0 && looksLikeImage(normalized)) {
        urls.push(normalized);
      }
      if (match.index === patterns[p].lastIndex) {
        patterns[p].lastIndex++;
      }
      match = patterns[p].exec(text);
    }
  }
  return urls;
}

export function cleanHtmlText(text: string): string {
  return decodeEntities(text.replace(/<script[\s\S]*?<\/script>/gi, '')
    .replace(/<style[\s\S]*?<\/style>/gi, '')
    .replace(/<[^>]+>/g, ' '));
}

function firstNonEmptyGroup(match: RegExpExecArray, groups: number[]): string {
  for (let i = 0; i < groups.length; i++) {
    const groupIndex = groups[i];
    if (groupIndex >= 0 && groupIndex < match.length) {
      const value = match[groupIndex];
      if (value !== undefined && value !== null && value.length > 0) {
        return value;
      }
    }
  }
  return '';
}

function safeRegExp(pattern: string): RegExp | null {
  try {
    return new RegExp(pattern, 'gim');
  } catch (err) {
    return null;
  }
}

function containsKeyword(title: string, keyword: string): boolean {
  const key = keyword.trim().toLowerCase();
  if (key.length === 0) {
    return true;
  }
  return title.toLowerCase().indexOf(key) >= 0;
}

function looksLikeChapter(title: string, url: string): boolean {
  const text = (title + ' ' + url).toLowerCase();
  if (text.length < 1) {
    return false;
  }
  const cleanTitle = title.replace(/\s+/g, ' ').trim();
  if (cleanTitle.length > 48 || /^(首页|分类|排行|排行榜|榜单|榜单中心|更新|历史|登录|注册|收藏|书架|恋爱|校园|霸总|都市|搜索|查看全部|查看更多|章节列表|章节目录|目录|内地|港台|日韩|欧美|其他)$/i.test(cleanTitle) ||
    /(阅读顺序|建议从|作品速览|相似(?:漫画|作品)?|相关推荐|全部章节|章节总数|更新信息|更多作品)/i.test(cleanTitle)) {
    return false;
  }
  if (/(免费观看|在线观看|高清完整|全集|第[0-9一二三四五六七八九十]+\s*季|动画上映|动漫|讲的是什么|是什么|免费版|txt精校版|免费全文阅读|全文阅读|免费阅读|精校版)/i.test(cleanTitle)) {
    return false;
  }
  if (/(第\s*\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|卷|chapter|episode|ep\.?\s*\d+|chap)/i.test(cleanTitle)) {
    if (/第\s*[0-9一二三四五六七八九十]+\s*季/.test(cleanTitle)) return false;
    if (/txt|精校|免费全文|全文阅读/.test(cleanTitle)) return false;
    return true;
  }
  if (/(漫画下拉式|免费阅读|我开启了|相关推荐|猜你喜欢)/i.test(cleanTitle) ||
    (cleanTitle.match(/漫画/g) ?? []).length > 1) {
    return false;
  }
  return /\/(ch|chapter|episode|ep|read|view|viewer)[-_\/0-9a-z]+/i.test(url);
}

function hasExplicitChapterNumber(title: string): boolean {
  return /(第\s*[0-9一二三四五六七八九十百千零〇两]+\s*[话章回卷]|chapter\s*\d+|episode\s*\d+|ep\.?\s*\d+)/i.test(title);
}

function looksLikeImage(url: string): boolean {
  const lower = url.toLowerCase();
  if (!isHttpUrl(lower)) {
    return false;
  }
  if (lower.indexOf('base64') >= 0 || lower.indexOf('data:') === 0) {
    return false;
  }
  if (/(\.jpg|\.jpeg|\.png|\.webp|\.gif|\.avif)(\?|#|\/|$)/i.test(lower)) {
    return true;
  }
  if (lower.indexOf('/iiif/') >= 0 || lower.indexOf('/full/') >= 0) {
    return true;
  }
  return lower.indexOf('/image') >= 0 || lower.indexOf('/img') >= 0;
}

function looksLikeReaderImage(url: string): boolean {
  const lower = url.toLowerCase();
  if (!looksLikeImage(lower)) return false;
  if (/(?:^|[\/_\-.])(logo|icon|avatar|banner|advert|ads?|loading|placeholder|spinner|emoji|favicon)(?:[\/_\-.]|$)/i.test(lower)) return false;
  if (/(?:cover|thumb|thumbnail|chaptercover|search-downlist|site-logo)/i.test(lower)) return false;
  return true;
}

function extractCoverFromBlock(block: string, pageUrl: string): string {
  const patterns: RegExp[] = [
    /<img[^>]+(?:data-original|data-src|data-lazy-src|src)=["']([^"']+)["'][^>]*>/i,
    /(?:cover|poster|thumb|thumbnail|pic|img)["']?\s*[:=]\s*["']([^"']+\.(?:jpg|jpeg|png|webp|gif)(?:\?[^"']*)?)["']/i,
    /["']((?:https?:)?\/\/[^"']+\/(?:[^"']*?)(?:cover|thumb|poster|comic|manga)[^"']*?\.(?:jpg|jpeg|png|webp|gif)(?:\?[^"']*)?)["']/i
  ];
  for (let i = 0; i < patterns.length; i++) {
    const match = patterns[i].exec(block);
    if (match && match.length > 1) {
      const url = resolveUrl(match[1], pageUrl);
      // Search/list covers commonly contain cover/thumb in their path. The
      // reader-image filter intentionally rejects those, so cover extraction
      // needs its own decorative-image check.
      if (url.length > 0 && looksLikeImage(url) &&
        !/(?:^|[\/_\-.])(logo|icon|avatar|banner|advert|ads?|loading|placeholder|spinner|emoji|favicon)(?:[\/_\-.]|$)/i.test(url)) {
        return url;
      }
    }
  }
  return '';
}

export function extractDetailCover(html: string, baseUrl: string): string {
  const ogImage = /<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']/i.exec(html);
  if (ogImage && ogImage.length > 1) {
    const u = resolveUrl(ogImage[1], baseUrl);
    if (u.length > 0 && looksLikeImage(u)) return u;
  }
  const twitterImage = /<meta[^>]+name=["']twitter:image["'][^>]+content=["']([^"']+)["']/i.exec(html);
  if (twitterImage && twitterImage.length > 1) {
    const u = resolveUrl(twitterImage[1], baseUrl);
    if (u.length > 0 && looksLikeImage(u)) return u;
  }
  const imgCover = /<img[^>]+class=["'][^"']*cover[^"']*["'][^>]+(?:data-original|data-src|src)=["']([^"']+)["']/i.exec(html);
  if (imgCover && imgCover.length > 1) {
    const u = resolveUrl(imgCover[1], baseUrl);
    if (u.length > 0 && looksLikeImage(u)) return u;
  }
  const imgCoverAlt = /<img[^>]+(?:data-original|data-src|src)=["']([^"']+)["'][^>]+class=["'][^"']*cover[^"']*["']/i.exec(html);
  if (imgCoverAlt && imgCoverAlt.length > 1) {
    const u = resolveUrl(imgCoverAlt[1], baseUrl);
    if (u.length > 0 && looksLikeImage(u)) return u;
  }
  const divCoverImg = /<div[^>]+class=["'][^"']*cover[^"']*["'][^>]*>[\s\S]{0,500}?<img[^>]+(?:data-original|data-src|src)=["']([^"']+)["']/i.exec(html);
  if (divCoverImg && divCoverImg.length > 1) {
    const u = resolveUrl(divCoverImg[1], baseUrl);
    if (u.length > 0 && looksLikeImage(u)) return u;
  }
  const divPicImg = /<div[^>]+class=["'][^"']*(?:pic|thumb|poster|book_cover|mh-cover)[^"']*["'][^>]*>[\s\S]{0,500}?<img[^>]+(?:data-original|data-src|src)=["']([^"']+)["']/i.exec(html);
  if (divPicImg && divPicImg.length > 1) {
    const u = resolveUrl(divPicImg[1], baseUrl);
    if (u.length > 0 && looksLikeImage(u)) return u;
  }
  const imgIdCover = /<img[^>]+id=["'](?:cover|poster|thumb)[^"']*["'][^>]+(?:data-original|data-src|src)=["']([^"']+)["']/i.exec(html);
  if (imgIdCover && imgIdCover.length > 1) {
    const u = resolveUrl(imgIdCover[1], baseUrl);
    if (u.length > 0 && looksLikeImage(u)) return u;
  }
  const bgImageCover = /background-image\s*:\s*url\(["']?([^"')]+)["']?\)/i.exec(html);
  if (bgImageCover && bgImageCover.length > 1) {
    const u = resolveUrl(bgImageCover[1], baseUrl);
    if (u.length > 0 && looksLikeImage(u) && !/(?:logo|icon|avatar|placeholder|loading|sprite|btn|button)/i.test(u)) return u;
  }
  const dataOrig = /<img[^>]+data-original=["']([^"']+)["']/i.exec(html);
  if (dataOrig && dataOrig.length > 1) {
    const u = resolveUrl(dataOrig[1], baseUrl);
    if (u.length > 0 && looksLikeImage(u) && !/(?:logo|icon|avatar|banner|placeholder)/i.test(u)) return u;
  }
  const dataSrc = /<img[^>]+data-src=["']([^"']+)["']/i.exec(html);
  if (dataSrc && dataSrc.length > 1) {
    const u = resolveUrl(dataSrc[1], baseUrl);
    if (u.length > 0 && looksLikeImage(u) && !/(?:logo|icon|avatar|banner|placeholder)/i.test(u)) return u;
  }
  const jsonCover = /["']?(?:cover|vertical_cover|horizontal_cover|coverUrl|cover_url|coverImage|cover_image|pic|thumb|poster)["']?\s*[:=]\s*["']([^"']+\.(?:jpg|jpeg|png|webp|gif|avif)(?:\?[^"']*)?)["']/i.exec(html);
  if (jsonCover && jsonCover.length > 1) {
    const u = resolveUrl(jsonCover[1], baseUrl);
    if (u.length > 0 && looksLikeImage(u)) return u;
  }
  return '';
}

export function parseSearchResults(html: string, rule: ComicSourceRule, pageUrl: string, keyword: string): SearchResultItem[] {
  const regex = safeRegExp(rule.searchItemRegex);
  const items: SearchResultItem[] = [];
  if (regex === null) {
    return items;
  }
  let match = regex.exec(html);
  let guard = 0;
  while (match !== null && guard < 300) {
    guard++;
    const rawTitle = firstNonEmptyGroup(match, rule.searchTitleGroups);
    const rawUrl = firstNonEmptyGroup(match, rule.searchUrlGroups);
    const rawCover = firstNonEmptyGroup(match, rule.searchCoverGroups);
    const title = cleanHtmlText(rawTitle);
    const url = resolveUrl(rawUrl, pageUrl);
    let cover = resolveUrl(normalizeUrlCandidate(rawCover), pageUrl);
    if (cover.length === 0 && match.length > 0) {
      cover = extractCoverFromBlock(match[0], pageUrl);
    }
    if (title.length > 0 && url.length > 0 && isHttpUrl(url)) {
      if (!rule.searchFilterByKeyword || containsKeyword(title, keyword)) {
        if (!items.some((item: SearchResultItem) => item.url === url)) {
          items.push({
            title: title,
            url: url,
            cover: cover,
            sourceId: rule.id,
            sourceName: rule.name,
            isChapter: rule.searchResultIsChapter,
            resultType: 'html-rule',
            groupName: title,
            description: rule.description
          });
        }
      }
    }
    if (match.index === regex.lastIndex) {
      regex.lastIndex++;
    }
    match = regex.exec(html);
  }
  return items;
}

/** Expand a discovered genre/ranking page into concrete comic details. */
export function parseComicListingResults(html: string, rule: ComicSourceRule, pageUrl: string): SearchResultItem[] {
  const items: SearchResultItem[] = [];
  const regex = /<a\b([^>]*href=["']([^"']+)["'][^>]*)>([\s\S]{0,1000}?)<\/a>/gim;
  let match = regex.exec(html);
  while (match !== null && items.length < 80) {
    const url = resolveUrl(match[2], pageUrl);
    const titleAttr = /\btitle=["']([^"']+)["']/i.exec(match[1]);
    const altAttr = /<img[^>]+\balt=["']([^"']+)["']/i.exec(match[3]);
    let title = titleAttr ? cleanHtmlText(titleAttr[1]) :
      (altAttr ? cleanHtmlText(altAttr[1]) : cleanHtmlText(match[3]));
    title = title.replace(/^(?:完结|连载|已完结|更新中)\s*/i, '')
      .replace(/\s*(?:作\s*者|作者|类\s*别|类别|更新至|更新于)\s*[:：].*$/i, '')
      .replace(/(?:漫画)?封面\s*$/i, '')
      .replace(/([\u3400-\u9fff])\s+(?=[\u3400-\u9fff])/g, '$1')
      .replace(/\s+/g, ' ').trim();
    const cover = extractCoverFromBlock(match[0], pageUrl);
    const detailUrl = /\/(comic|manhua|manga|book|detail|work|webtoon|album)\//i.test(url) ||
      /[?&](id|comic_id|book_id)=\d+/i.test(url);
    const invalidUrl = /\/(category|classify|genre|tag|rank|list|search)(\/|\?|$)/i.test(url);
    const invalidTitle = !/[A-Za-z0-9\u3400-\u9fff]/.test(title) ||
      /^(首页|漫画|更多|查看全部|作品分类|排行榜|热门|最新|完结|连载)$/i.test(title) ||
      /(漫画大全|漫画分类|漫画排行榜|官方漫画|免费在线观看|查看更多|版本更新中|原创大赛|征稿|活动专区)/i.test(title);
    if (isHttpUrl(url) && title.length >= 2 && title.length <= 64 && !invalidUrl && !invalidTitle &&
      (cover.length > 0 || detailUrl) && !items.some((item: SearchResultItem) => item.url === url)) {
      items.push({ title: title, url: url, cover: cover, sourceId: rule.id, sourceName: rule.name,
        isChapter: false, resultType: 'html-rule', groupName: title, description: '从分类页展开的具体作品' });
    }
    if (match.index === regex.lastIndex) regex.lastIndex++;
    match = regex.exec(html);
  }
  return items;
}

export function parseChapters(html: string, rule: ComicSourceRule, pageUrl: string): ChapterItem[] {
  const regex = safeRegExp(rule.detailChapterRegex);
  const chapters: ChapterItem[] = [];
  if (regex === null) {
    return chapters;
  }
  let match = regex.exec(html);
  let guard = 0;
  while (match !== null && guard < 800) {
    guard++;
    const rawTitle = firstNonEmptyGroup(match, rule.detailChapterTitleGroups);
    const rawUrl = firstNonEmptyGroup(match, rule.detailChapterUrlGroups);
    const title = cleanHtmlText(rawTitle);
    const url = resolveUrl(rawUrl, pageUrl);
    if (title.length > 0 && url.length > 0 && isHttpUrl(url)) {
      if (!rule.detailChapterFilter || looksLikeChapter(title, url)) {
        const duplicateIndex = chapters.findIndex((item: ChapterItem) => item.url === url);
        if (duplicateIndex < 0) {
          chapters.push({
            title: title,
            url: url,
            index: chapters.length + 1,
            sourceId: rule.id,
            sourceName: rule.name
          });
        } else if (hasExplicitChapterNumber(title) && !hasExplicitChapterNumber(chapters[duplicateIndex].title)) {
          chapters[duplicateIndex].title = title;
        }
      }
    }
    if (match.index === regex.lastIndex) {
      regex.lastIndex++;
    }
    match = regex.exec(html);
  }
  return chapters;
}

export function parseChaptersFallback(html: string, rule: ComicSourceRule, pageUrl: string): ChapterItem[] {
  const chapters: ChapterItem[] = [];
  const anchorRegex = /<a\b[^>]*href=["']([^"']+)["'][^>]*>([\s\S]*?)<\/a>/gi;
  let match = anchorRegex.exec(html);
  let guard = 0;
  while (match !== null && guard < 3000 && chapters.length < 800) {
    guard++;
    const title = cleanHtmlText(match[2]);
    const url = resolveUrl(normalizeUrlCandidate(match[1]), pageUrl);
    if (title.length > 0 && isHttpUrl(url) && looksLikeChapter(title, url)) {
      const duplicateIndex = chapters.findIndex((item: ChapterItem) => item.url === url);
      if (duplicateIndex < 0) {
        chapters.push({ title: title, url: url, index: chapters.length + 1,
          sourceId: rule.id, sourceName: rule.name });
      } else if (hasExplicitChapterNumber(title) && !hasExplicitChapterNumber(chapters[duplicateIndex].title)) {
        chapters[duplicateIndex].title = title;
      }
    }
    if (match.index === anchorRegex.lastIndex) anchorRegex.lastIndex++;
    match = anchorRegex.exec(html);
  }
  return chapters;
}

function extractAcQqDataImages(html: string, pageUrl: string): ReaderImageItem[] {
  const images: ReaderImageItem[] = [];
  const acimgIdx = html.indexOf('acimg.cn');
  let dataStart = -1;
  const patterns = ["data: '", "data:'"];
  for (let p = 0; p < patterns.length; p++) {
    const idx = html.indexOf(patterns[p]);
    if (idx >= 0 && (dataStart < 0 || idx < dataStart)) {
      dataStart = idx + patterns[p].length;
    }
  }
  if (dataStart < 0) {
    return images;
  }
  const dataEnd = html.indexOf("'", dataStart);
  if (dataEnd < 0 || dataEnd - dataStart < 20) {
    return images;
  }
  const b64Data = html.substring(dataStart, dataEnd);
  try {
    const jsonStr = decodeBase64(b64Data);
    const picRegex = /"url"\s*:\s*"([^"]+)"/gi;
    let picMatch = picRegex.exec(jsonStr);
    let guard = 0;
    while (picMatch !== null && guard < 200) {
      guard++;
      const rawUrl = picMatch[1].replace(/\\\//g, '/');
      const url = resolveUrl(rawUrl, pageUrl);
      if (url.length > 0 && looksLikeImage(url) &&
        !images.some((item: ReaderImageItem) => item.url === url)) {
        images.push({ url: url, index: images.length + 1, status: 'waiting' });
      }
      if (picMatch.index === picRegex.lastIndex) {
        picRegex.lastIndex++;
      }
      picMatch = picRegex.exec(jsonStr);
    }
  } catch (err) {
  }
  return images;
}

export function parseImages(html: string, rule: ComicSourceRule, pageUrl: string): ReaderImageItem[] {
  const regex = safeRegExp(rule.readerImageRegex);
  const images: ReaderImageItem[] = [];
  if (regex === null) {
    return images;
  }
  let match = regex.exec(html);
  let guard = 0;
  while (match !== null && guard < 500) {
    guard++;
    const rawUrl = firstNonEmptyGroup(match, rule.readerImageGroups);
    const url = resolveUrl(normalizeUrlCandidate(rawUrl), pageUrl);
    if (url.length > 0 && looksLikeImage(url)) {
      if (!images.some((item: ReaderImageItem) => item.url === url)) {
        images.push({ url: url, index: images.length + 1, status: 'waiting' });
      }
    }
    if (match.index === regex.lastIndex) {
      regex.lastIndex++;
    }
    match = regex.exec(html);
  }
  if (/ac\.qq\.com/i.test(pageUrl)) {
    const acQqImages = extractAcQqDataImages(html, pageUrl);
    for (let i = 0; i < acQqImages.length; i++) {
      if (!images.some((item: ReaderImageItem) => item.url === acQqImages[i].url)) {
        images.push(acQqImages[i]);
      }
    }
  }
  if (images.length < 3) {
    const extraUrls = extractImageUrlsFromText(html, pageUrl);
    for (let i = 0; i < extraUrls.length; i++) {
      const url = extraUrls[i];
      if (looksLikeReaderImage(url) && !images.some((item: ReaderImageItem) => item.url === url)) {
        images.push({ url: url, index: images.length + 1, status: 'waiting' });
      }
    }
  }
  return images;
}

export function parseNextPageUrl(html: string, rule: ComicSourceRule, pageUrl: string): string {
  if (rule.readerNextPageRegex === undefined || rule.readerNextPageRegex.length === 0) {
    return '';
  }
  const regex = safeRegExp(rule.readerNextPageRegex);
  if (regex === null) {
    return '';
  }
  const groups = rule.readerNextPageUrlGroups !== undefined && rule.readerNextPageUrlGroups.length > 0 ? rule.readerNextPageUrlGroups : [1];
  let match = regex.exec(html);
  let guard = 0;
  while (match !== null && guard < 20) {
    guard++;
    const rawUrl = firstNonEmptyGroup(match, groups);
    const url = resolveUrl(rawUrl, pageUrl);
    if (url.length > 0 && isHttpUrl(url) && url !== pageUrl) {
      return url;
    }
    if (match.index === regex.lastIndex) {
      regex.lastIndex++;
    }
    match = regex.exec(html);
  }
  return '';
}
