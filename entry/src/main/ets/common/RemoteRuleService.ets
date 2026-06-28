import { ComicSourceRule } from '../model/ComicModels';
import { HttpClient } from './HttpClient';

export const DEFAULT_REMOTE_RULE_URL: string = 'https://raw.githubusercontent.com/liyan-lucky/ComicReader_Rules/main/generated/index.json';

const EXPECTED_SCHEMA: string = 'womh_comic_rules_index_v1';
const MAX_REMOTE_RULES: number = 200;
const MAX_FIELD_LENGTH: number = 12000;

interface RemoteRuleIndex {
  schema?: string;
  version?: string;
  updatedAt?: string;
  rules?: ComicSourceRule[];
  compliance?: Record<string, object | string | boolean | number>;
}

function isSafeHttpUrl(url: string): boolean {
  return url.startsWith('https://') || url.startsWith('http://127.0.0.1') || url.startsWith('http://localhost');
}

function isSafeText(value: string | undefined, maxLength: number = MAX_FIELD_LENGTH): boolean {
  return value !== undefined && value.length > 0 && value.length <= maxLength;
}

function isValidRule(item: ComicSourceRule): boolean {
  return item !== undefined &&
    isSafeText(item.id, 128) &&
    isSafeText(item.name, 256) &&
    item.homepage !== undefined && item.homepage.length <= 2048 &&
    item.searchUrl !== undefined && item.searchUrl.length <= 4096 &&
    item.readerImageRegex !== undefined && item.readerImageRegex.length > 0 && item.readerImageRegex.length <= MAX_FIELD_LENGTH &&
    item.readerImageGroups !== undefined && item.readerImageGroups.length > 0 && item.readerImageGroups.length <= 8;
}

function isTrustedIndex(parsed: RemoteRuleIndex): boolean {
  if (parsed.schema !== EXPECTED_SCHEMA) {
    return false;
  }
  if (parsed.rules === undefined) {
    return true;
  }
  return parsed.rules.length <= MAX_REMOTE_RULES;
}

export class RemoteRuleService {
  static async fetchRemoteRules(url: string): Promise<ComicSourceRule[]> {
    if (!isSafeHttpUrl(url)) {
      throw new Error('Remote rule URL must use HTTPS');
    }
    const text = await HttpClient.getText(url, 'Mozilla/5.0 HarmonyOS ComicReader RemoteRules/1.0', 'https://github.com/');
    const parsed = JSON.parse(text) as RemoteRuleIndex;
    if (!isTrustedIndex(parsed)) {
      throw new Error('Invalid remote rule index');
    }
    const remoteRules = parsed.rules === undefined ? [] : parsed.rules;
    const validRules: ComicSourceRule[] = [];
    for (let i = 0; i < remoteRules.length; i++) {
      const rule = remoteRules[i];
      if (isValidRule(rule)) {
        validRules.push(rule);
      }
    }
    return validRules;
  }

  static mergeRules(localRules: ComicSourceRule[], remoteRules: ComicSourceRule[]): ComicSourceRule[] {
    const merged: ComicSourceRule[] = [];
    const remoteLimit = Math.min(remoteRules.length, MAX_REMOTE_RULES);
    for (let i = 0; i < remoteLimit; i++) {
      merged.push(remoteRules[i]);
    }
    for (let j = 0; j < localRules.length; j++) {
      const local = localRules[j];
      if (!merged.some((item: ComicSourceRule) => item.id === local.id)) {
        merged.push(local);
      }
    }
    return merged;
  }
}
