export function stripQueryAndHash(url: string): string {
  let result = url;
  const hashIndex = result.indexOf('#');
  if (hashIndex >= 0) {
    result = result.substring(0, hashIndex);
  }
  const queryIndex = result.indexOf('?');
  if (queryIndex >= 0) {
    result = result.substring(0, queryIndex);
  }
  return result;
}

export function isHttpUrl(url: string): boolean {
  return /^https?:\/\//i.test(url.trim());
}

export function isUnsafeUrlScheme(url: string): boolean {
  const value = url.trim().toLowerCase();
  return value.startsWith('javascript:') ||
    value.startsWith('mailto:') ||
    value.startsWith('tel:') ||
    value.startsWith('file:') ||
    value.startsWith('data:') ||
    value.startsWith('blob:') ||
    value.startsWith('about:') ||
    value.startsWith('intent:') ||
    value.startsWith('hap:') ||
    value.startsWith('app:');
}

export function getOrigin(url: string): string {
  const match = /^(https?:\/\/[^\/]+)/i.exec(url);
  if (match && match.length > 1) {
    return match[1];
  }
  return '';
}

export function getDirectory(url: string): string {
  const clean = stripQueryAndHash(url);
  const slashIndex = clean.lastIndexOf('/');
  if (slashIndex >= 0) {
    return clean.substring(0, slashIndex + 1);
  }
  return clean + '/';
}

function normalizePath(url: string): string {
  const origin = getOrigin(url);
  if (origin.length === 0) {
    return url;
  }
  let path = url.substring(origin.length);
  const parts = path.split('/');
  const stack: string[] = [];
  for (let i = 0; i < parts.length; i++) {
    const part = parts[i];
    if (part === '' || part === '.') {
      continue;
    }
    if (part === '..') {
      if (stack.length > 0) {
        stack.pop();
      }
      continue;
    }
    stack.push(part);
  }
  return origin + '/' + stack.join('/');
}

export function resolveUrl(link: string, baseUrl: string): string {
  let value = link.trim();
  value = value.replace(/&amp;/g, '&');
  if (value.length === 0) {
    return '';
  }
  if (isUnsafeUrlScheme(value)) {
    return '';
  }
  if (/^https?:\/\//i.test(value)) {
    return value;
  }
  if (value.startsWith('//')) {
    return 'https:' + value;
  }
  const origin = getOrigin(baseUrl);
  if (origin.length === 0) {
    return '';
  }
  if (value.startsWith('/')) {
    return origin + value;
  }
  if (/^[0-9]+$/.test(value)) {
    return normalizePath(origin + '/' + value + '/');
  }
  return normalizePath(getDirectory(baseUrl) + value);
}

export function looksLikeUrl(value: string): boolean {
  const text = value.trim();
  if (isUnsafeUrlScheme(text)) {
    return false;
  }
  if (/^https?:\/\//i.test(text)) {
    return true;
  }
  if (text.indexOf(' ') >= 0) {
    return false;
  }
  return /^[a-z0-9][-a-z0-9]*\.[a-z0-9][-a-z0-9.]*\//i.test(text) || /^[a-z0-9][-a-z0-9]*\.[a-z]{2,}/i.test(text);
}

export function normalizeUserUrl(value: string): string {
  const text = value.trim();
  if (isUnsafeUrlScheme(text)) {
    return '';
  }
  if (/^https?:\/\//i.test(text)) {
    return text;
  }
  return 'https://' + text;
}
