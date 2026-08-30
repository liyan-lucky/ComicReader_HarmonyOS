import { RemoteCatalog, CatalogCategory, CatalogItem } from '../model/ComicModels';
import { HttpClient } from './HttpClient';
import { DEFAULT_REMOTE_RULE_URL } from './RemoteRuleService';

const LEGACY_CATALOG_SCHEMA: string = 'womh_comic_catalog_v1';
const INCREMENTAL_CATALOG_SCHEMA: string = 'comic_catalog_v1';
const EXPECTED_MANIFEST_SCHEMA: string = 'comic_reader_update_manifest_v1';
// totalItems counts category memberships, so the validated catalog can exceed
// the number of unique comics by a wide margin.
const MAX_CATALOG_ITEMS: number = 20000;

interface ManifestForCatalog {
  schema?: string;
  catalog?: ManifestCatalogRef;
}

interface ManifestCatalogRef {
  version?: string;
  url?: string;
}

export interface CatalogUpdateRef {
  version: string;
  url: string;
}

function isSafeUrl(url: string): boolean {
  const value = url.trim().toLowerCase();
  return value.startsWith('https://') || value.startsWith('http://127.0.0.1') || value.startsWith('http://localhost');
}

function isTrustedCatalog(parsed: RemoteCatalog): boolean {
  if (parsed.schema !== LEGACY_CATALOG_SCHEMA && parsed.schema !== INCREMENTAL_CATALOG_SCHEMA) {
    return false;
  }
  if (parsed.totalItems !== undefined && parsed.totalItems > MAX_CATALOG_ITEMS) {
    return false;
  }
  return true;
}

export class CatalogService {
  static async fetchCatalogUpdate(manifestUrl: string = DEFAULT_REMOTE_RULE_URL): Promise<CatalogUpdateRef> {
    if (!isSafeUrl(manifestUrl)) throw new Error('Manifest URL must use HTTPS');
    let text: string;
    try {
      text = await HttpClient.getTextWithTimeout(manifestUrl,
        'Mozilla/5.0 HarmonyOS ComicReader Catalog/1.0', 'https://github.com/', 60000);
    } catch (firstError) {
      // GitHub Raw may intermittently stall before the first byte on mobile
      // networks. Retry the tiny manifest once before falling back to cache.
      text = await HttpClient.getTextWithTimeout(manifestUrl,
        'Mozilla/5.0 HarmonyOS ComicReader Catalog/1.0', 'https://github.com/', 60000);
    }
    const manifest = JSON.parse(text) as ManifestForCatalog;
    if (manifest.schema !== EXPECTED_MANIFEST_SCHEMA || !manifest.catalog?.url || !manifest.catalog?.version) {
      throw new Error('Invalid manifest or missing catalog metadata');
    }
    if (!isSafeUrl(manifest.catalog.url)) throw new Error('Catalog URL must use HTTPS');
    return { version: manifest.catalog.version, url: manifest.catalog.url };
  }

  static isNewerVersion(remoteVersion: string, localVersion?: string): boolean {
    if (!localVersion || localVersion.length === 0) return true;
    const remoteParts = remoteVersion.split(/\D+/).filter((item: string) => item.length > 0);
    const localParts = localVersion.split(/\D+/).filter((item: string) => item.length > 0);
    const length = Math.max(remoteParts.length, localParts.length);
    for (let i = 0; i < length; i++) {
      const remote = i < remoteParts.length ? Number(remoteParts[i]) : 0;
      const local = i < localParts.length ? Number(localParts[i]) : 0;
      if (remote > local) return true;
      if (remote < local) return false;
    }
    return false;
  }

  static async fetchCatalogFromUrl(catalogUrl: string,
    onProgress?: (received: number, total: number) => void): Promise<RemoteCatalog> {
    if (!isSafeUrl(catalogUrl)) throw new Error('Catalog URL must use HTTPS');
    const text = onProgress
      ? await HttpClient.getTextWithProgress(catalogUrl,
        'Mozilla/5.0 HarmonyOS ComicReader Catalog/1.0', 'https://github.com/', onProgress)
      : await HttpClient.getText(catalogUrl,
        'Mozilla/5.0 HarmonyOS ComicReader Catalog/1.0', 'https://github.com/');
    const parsed = JSON.parse(text) as RemoteCatalog;
    if (!isTrustedCatalog(parsed)) throw new Error('Invalid remote catalog');
    return parsed;
  }

  static async fetchCatalog(catalogUrl?: string): Promise<RemoteCatalog> {
    const url = catalogUrl ? catalogUrl : (await CatalogService.fetchCatalogUpdate()).url;
    return CatalogService.fetchCatalogFromUrl(url);
  }

  static getCategories(catalog: RemoteCatalog): CatalogCategory[] {
    if (!catalog.categories) {
      return [];
    }
    const result: CatalogCategory[] = [];
    const keys = Object.keys(catalog.categories);
    for (let i = 0; i < keys.length; i++) {
      const cat = catalog.categories[keys[i]];
      if (cat && cat.items && cat.items.length > 0) {
        result.push(cat);
      }
    }
    return result;
  }

  static getItemsForCategory(catalog: RemoteCatalog, categoryId: string): CatalogItem[] {
    if (!catalog.categories || !catalog.categories[categoryId]) {
      return [];
    }
    return catalog.categories[categoryId].items || [];
  }

  static getAllItems(catalog: RemoteCatalog): CatalogItem[] {
    const result: CatalogItem[] = [];
    if (!catalog.categories) return result;
    const keys = Object.keys(catalog.categories);
    for (let i = 0; i < keys.length; i++) {
      const category = catalog.categories[keys[i]];
      if (!category || !category.items) continue;
      for (let j = 0; j < category.items.length; j++) result.push(category.items[j]);
    }
    return result;
  }
}
