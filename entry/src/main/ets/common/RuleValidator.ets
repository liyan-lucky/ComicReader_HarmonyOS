import { ComicSourceRule } from '../model/ComicModels';

const MAX_RULE_TEXT_LENGTH: number = 12000;
const MAX_URL_LENGTH: number = 4096;

export function isSafeRuleText(value: string | undefined, maxLength: number = MAX_RULE_TEXT_LENGTH): boolean {
  return value !== undefined && value.length > 0 && value.length <= maxLength;
}

export function isSafeRuleUrl(value: string | undefined): boolean {
  if (value === undefined || value.length > MAX_URL_LENGTH) {
    return false;
  }
  if (value.length === 0) {
    return true;
  }
  const lower = value.toLowerCase();
  return lower.startsWith('https://') || lower.startsWith('http://');
}

export function isValidPublicRule(rule: ComicSourceRule): boolean {
  if (rule === undefined) {
    return false;
  }
  if (!isSafeRuleText(rule.id, 128) || !isSafeRuleText(rule.name, 256)) {
    return false;
  }
  if (!isSafeRuleUrl(rule.homepage) || !isSafeRuleUrl(rule.searchUrl) || !isSafeRuleUrl(rule.referer)) {
    return false;
  }
  if (!isSafeRuleText(rule.readerImageRegex) || rule.readerImageGroups === undefined || rule.readerImageGroups.length === 0 || rule.readerImageGroups.length > 8) {
    return false;
  }
  if (rule.readerNextPageRegex !== undefined && rule.readerNextPageRegex.length > MAX_RULE_TEXT_LENGTH) {
    return false;
  }
  if (rule.maxReaderPages !== undefined && (rule.maxReaderPages < 1 || rule.maxReaderPages > 30)) {
    return false;
  }
  return true;
}
