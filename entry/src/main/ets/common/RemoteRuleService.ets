import { ComicSourceRule } from '../model/ComicModels';
import { HttpClient } from './HttpClient';

export const DEFAULT_REMOTE_RULE_URL: string = 'https://raw.githubusercontent.com/liyan-lucky/ComicReader_Rules/main/generated/index.json';

interface RemoteRuleIndex {
  schema?: string;
  version?: string;
  updatedAt?: string;
  rules?: ComicSourceRule[];
}

function isValidRule(item: ComicSourceRule): boolean {
  return item !== undefined &&
    item.id !== undefined && item.id.length > 0 &&
    item.name !== undefined && item.name.length > 0 &&
    item.homepage !== undefined &&
    item.readerImageRegex !== undefined &&
    item.readerImageGroups !== undefined;
}

export class RemoteRuleService {
  static async fetchRemoteRules(url: string): Promise<ComicSourceRule[]> {
    const text = await HttpClient.getText(url, 'Mozilla/5.0 HarmonyOS ComicReader RemoteRules/1.0', 'https://github.com/');
    const parsed = JSON.parse(text) as RemoteRuleIndex;
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
    for (let i = 0; i < remoteRules.length; i++) {
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
