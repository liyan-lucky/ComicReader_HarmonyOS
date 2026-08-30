import { ComicSourceRule, LanguageInfo } from '../model/ComicModels';
import { HttpClient } from './HttpClient';
import { isValidPublicRule } from './RuleValidator';

export const DEFAULT_REMOTE_RULE_URL: string = 'https://raw.githubusercontent.com/liyan-lucky/ComicReader_Rules/main/generated/update_manifest.json';

const EXPECTED_RULE_SCHEMA: string = 'womh_comic_rules_index_v1';
const EXPECTED_MANIFEST_SCHEMA: string = 'comic_reader_update_manifest_v1';
// The generated zh-Hans index currently contains roughly one thousand audited
// public sources. Rejecting the whole index at 200 made every online update fail.
const MAX_REMOTE_RULES: number = 1200;

interface RemoteRuleIndex {
  schema?: string;
  version?: string;
  updatedAt?: string;
  rules?: ComicSourceRule[];
  compliance?: Record<string, string | boolean | number>;
}

interface ManifestRulesEntry {
  version?: string;
  url?: string;
  language?: LanguageInfo;
  languages?: Record<string, ManifestRulesEntry>;
}

interface ManifestCatalogEntry {
  version?: string;
  url?: string;
  language?: LanguageInfo;
  languages?: Record<string, ManifestCatalogEntry>;
}

interface UpdateManifest {
  schema?: string;
  rules?: ManifestRulesEntry;
  catalog?: ManifestCatalogEntry;
}

function isSafeRemoteRuleUrl(url: string): boolean {
  const value = url.trim().toLowerCase();
  return value.startsWith('https://') || value.startsWith('http://127.0.0.1') || value.startsWith('http://localhost');
}

function isTrustedIndex(parsed: RemoteRuleIndex): boolean {
  if (parsed.schema !== EXPECTED_RULE_SCHEMA) {
    return false;
  }
  if (parsed.rules === undefined) {
    return true;
  }
  return parsed.rules.length <= MAX_REMOTE_RULES;
}

function isTrustedManifest(parsed: UpdateManifest): boolean {
  return parsed.schema === EXPECTED_MANIFEST_SCHEMA;
}

export class RemoteRuleService {
  static async fetchRemoteRules(url: string): Promise<ComicSourceRule[]> {
    if (!isSafeRemoteRuleUrl(url)) {
      throw new Error('Remote rule URL must use HTTPS');
    }
    const text = await HttpClient.getText(url, 'Mozilla/5.0 HarmonyOS ComicReader RemoteRules/1.0', 'https://github.com/');
    const parsed = JSON.parse(text) as RemoteRuleIndex | UpdateManifest;

    if (isTrustedManifest(parsed as UpdateManifest)) {
      const manifest = parsed as UpdateManifest;
      const rulesUrl = manifest.rules?.url;
      if (!rulesUrl) {
        throw new Error('Manifest missing rules URL');
      }
      return RemoteRuleService.fetchRulesFromUrl(rulesUrl);
    }

    if (isTrustedIndex(parsed as RemoteRuleIndex)) {
      return RemoteRuleService.extractValidRules(parsed as RemoteRuleIndex);
    }

    throw new Error('Invalid remote rule index or manifest');
  }

  static async fetchRulesFromUrl(rulesUrl: string): Promise<ComicSourceRule[]> {
    if (!isSafeRemoteRuleUrl(rulesUrl)) {
      throw new Error('Rules URL must use HTTPS');
    }
    const text = await HttpClient.getText(rulesUrl, 'Mozilla/5.0 HarmonyOS ComicReader RemoteRules/1.0', 'https://github.com/');
    const parsed = JSON.parse(text) as RemoteRuleIndex;
    if (!isTrustedIndex(parsed)) {
      throw new Error('Invalid remote rule index');
    }
    return RemoteRuleService.extractValidRules(parsed);
  }

  static async fetchCatalogUrl(manifestUrl: string): Promise<string> {
    if (!isSafeRemoteRuleUrl(manifestUrl)) {
      throw new Error('Manifest URL must use HTTPS');
    }
    const text = await HttpClient.getText(manifestUrl, 'Mozilla/5.0 HarmonyOS ComicReader Catalog/1.0', 'https://github.com/');
    const manifest = JSON.parse(text) as UpdateManifest;
    if (!isTrustedManifest(manifest) || !manifest.catalog?.url) {
      throw new Error('Invalid manifest or missing catalog URL');
    }
    return manifest.catalog.url;
  }

  private static extractValidRules(parsed: RemoteRuleIndex): ComicSourceRule[] {
    const remoteRules = parsed.rules === undefined ? [] : parsed.rules;
    const validRules: ComicSourceRule[] = [];
    for (let i = 0; i < remoteRules.length; i++) {
      const rule = remoteRules[i];
      if (isValidPublicRule(rule)) {
        validRules.push(rule);
      }
    }
    return validRules;
  }

  static mergeRules(localRules: ComicSourceRule[], remoteRules: ComicSourceRule[]): ComicSourceRule[] {
    const merged: ComicSourceRule[] = [];
    const remoteLimit = Math.min(remoteRules.length, MAX_REMOTE_RULES);
    for (let i = 0; i < remoteLimit; i++) {
      if (isValidPublicRule(remoteRules[i])) {
        merged.push(remoteRules[i]);
      }
    }
    for (let j = 0; j < localRules.length; j++) {
      const local = localRules[j];
      if (isValidPublicRule(local) && !merged.some((item: ComicSourceRule) => item.id === local.id)) {
        merged.push(local);
      }
    }
    return merged;
  }
}
