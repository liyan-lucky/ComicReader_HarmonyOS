import { ComicSourceRule, SearchResultItem, ChapterItem, ReaderImageItem } from '../model/ComicModels';
import { resolveUrl, isHttpUrl } from './UrlUtil';

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
    /\/(?:[^"'\s\]\\]+\/)+[^"'\s\]\\]+\.(?:jpg|jpeg|png|webp|gif|avif)(?:\?[^"'\s\]\\]*)?/gim
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
  if (/(第\s*\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|卷|chapter|episode|ep\.?\s*\d+|chap|comic|manga|manhua|manhwa)/i.test(text)) {
    return true;
  }
  return /\/(ch|chapter|episode|ep|read|view|comic|manga)[-_\/0-9a-z]+/i.test(url);
}

function looksLikeImage(url: string): boolean {
  const lower = url.toLowerCase();
  if (!isHttpUrl(lower)) {
    return false;
  }
  if (lower.indexOf('base64') >= 0 || lower.indexOf('data:') === 0) {
    return false;
  }
  if (/(\.jpg|\.jpeg|\.png|\.webp|\.gif|\.avif)(\?|#|$)/i.test(lower)) {
    return true;
  }
  if (lower.indexOf('/iiif/') >= 0 || lower.indexOf('/full/') >= 0) {
    return true;
  }
  return lower.indexOf('/image') >= 0 || lower.indexOf('/img') >= 0;
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
      if (url.length > 0 && looksLikeImage(url)) {
        return url;
      }
    }
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
        if (!chapters.some((item: ChapterItem) => item.url === url)) {
          chapters.push({
            title: title,
            url: url,
            index: chapters.length + 1,
            sourceId: rule.id,
            sourceName: rule.name
          });
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
  const extraUrls = extractImageUrlsFromText(html, pageUrl);
  for (let i = 0; i < extraUrls.length; i++) {
    const url = extraUrls[i];
    if (!images.some((item: ReaderImageItem) => item.url === url)) {
      images.push({ url: url, index: images.length + 1, status: 'waiting' });
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
