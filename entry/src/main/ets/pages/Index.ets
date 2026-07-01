import { ComicSourceRule, SearchResultItem, ChapterItem, ReaderImageItem, ReadingHistoryItem, ResultGroup, BookshelfItem, SearchEngineConfig } from '../model/ComicModels';
import { DEFAULT_SOURCES, RULE_TEMPLATE, ruleForPublicUrl, isUnverifiedPublicDomain, isOfficialOrPublicCollectionDomain, isKnownLoginOrPayDomain, isTop20AuditedPublicReadableDomain } from '../common/SourceRules';
import { HttpClient } from '../common/HttpClient';
import { parseSearchResults, parseChapters, parseImages, parseNextPageUrl } from '../common/HtmlParser';
import { looksLikeUrl, normalizeUserUrl } from '../common/UrlUtil';
import { DEFAULT_SEARCH_ENGINES, buildEngineQuery, buildSearchEngineUrl, parseSearchEngineResults, isEngineConfigured, engineHeaders, searchEngineUserAgent } from '../common/SearchEngines';
import { RemoteRuleService, DEFAULT_REMOTE_RULE_URL } from '../common/RemoteRuleService';
import { APP_VERSION, APP_VERSION_CODE, APP_BUILD_TYPE, APP_BUILD_TIME, APP_BUILD_TARGET } from '../common/BuildInfo';
import webview from '@ohos.web.webview';

import {
  buildInternetArchiveSearchUrl,
  buildInternetArchiveManifestUrl,
  buildInternetArchiveMetadataUrl,
  buildWikimediaSearchUrl,
  buildOpenLibrarySearchUrl,
  buildLibraryOfCongressSearchUrl,
  parseInternetArchiveSearch,
  parseInternetArchiveManifestImages,
  parseInternetArchiveMetadataImages,
  parseOpenLibrarySearch,
  parseWikimediaSearch,
  parseLibraryOfCongressSearch,
  searchPepperCatalog,
  parsePepperImages,
  isArchivePseudoUrl,
  archiveIdentifierFromUrl,
  isWikimediaPseudoUrl,
  wikimediaImageFromUrl,
  isLocPseudoUrl,
  locImageFromUrl,
  isPepperPseudoUrl,
  builtinApiSourceCount,
  internetArchiveSourceId,
  wikimediaSourceId,
  pepperSourceId,
  openLibrarySourceId,
  libraryOfCongressSourceId
} from '../common/ApiSources';

@Entry
@Component
struct Index {
  @State private activeTab: string = 'search';
  @State private mode: string = 'home';
  @State private queryText: string = '';
  @State private statusText: string = '输入漫画名称后，会调用当前设置的搜索引擎和公开资源源，整理成封面列表并进入卷轴阅读；开心漫等公开卷轴站点支持渲染兜底。';
  @State private selectedSourceIndex: number = 0;
  @State private rules: ComicSourceRule[] = DEFAULT_SOURCES;
  @State private remoteRuleUrl: string = DEFAULT_REMOTE_RULE_URL;
  @State private remoteRuleStatus: string = '远程规则未更新';
  @State private remoteRuleCount: number = 0;
  @State private results: SearchResultItem[] = [];
  @State private chapters: ChapterItem[] = [];
  @State private images: ReaderImageItem[] = [];
  @State private currentTitle: string = '';
  @State private currentUrl: string = '';
  @State private currentChapterTitle: string = '';
  @State private currentCover: string = '';
  @State private currentSourceId: string = '';
  @State private currentSourceName: string = '';
  @State private customRuleText: string = RULE_TEMPLATE;
  @State private history: ReadingHistoryItem[] = [];
  @State private bookshelf: BookshelfItem[] = [];
  @State private isLoading: boolean = false;
  private renderWebController: webview.WebviewController = new webview.WebviewController();
  @State private renderedReaderUrl: string = '';
  @State private renderedReaderTitle: string = '';
  @State private enableRenderedWebFallback: boolean = true;

  @State private searchEngines: SearchEngineConfig[] = DEFAULT_SEARCH_ENGINES;
  @State private selectedEngineIndex: number = 0;
  @State private searchMode: string = '混合';
  @State private searchAllEngines: boolean = false;
  @State private languageMode: string = '自动';
  @State private extraSearchTerms: string = 'comic manga manhua manhwa webcomic graphic novel 漫画 在线 阅读';
  @State private siteHint: string = '';
  @State private braveApiKey: string = '';
  @State private googleApiKey: string = '';
  @State private googleCx: string = '';

  @State private enableInternetArchive: boolean = true;
  @State private enableOpenLibrary: boolean = true;
  @State private enableLibraryOfCongress: boolean = true;
  @State private enableWikimedia: boolean = true;
  @State private enablePepper: boolean = true;
  @State private enableHtmlRules: boolean = true;
  @State private enableSearchEngines: boolean = true;
  @State private sourceFilterMode: string = '全部公开可访问';
  @State private includeUnverifiedPublicSources: boolean = true;
  @State private includeOfficialPreviewSources: boolean = true;
  @State private includeSearchEngineDiscovered: boolean = true;
  @State private excludeLoginPayResults: boolean = true;

  @State private coverOnlyMode: boolean = true;
  @State private resultColumns: number = 3;
  @State private resultViewMode: string = 'grid';
  @State private autoCoverEnabled: boolean = true;
  @State private groupByName: boolean = true;
  @State private maxSearchResults: number = 80;
  @State private maxCoverEnrich: number = 30;
  @State private readerDarkMode: boolean = true;
  @State private showImageIndex: boolean = true;
  @State private readerFitContain: boolean = true;
  @State private dedupeImages: boolean = true;
  @State private maxReaderPagesSetting: number = 8;
  @State private keepHistoryCount: number = 40;
  @State private auditText: string = '审计状态：v5.8 已拆分 App 仓库与规则仓库。App 可从 GitHub Raw 远程更新 generated/index.json 规则，规则仓库可用 GitHub Actions 自动搜索/审计/生成公开源规则。';
  @State private appTheme: string = 'light';
  @State private appLanguage: string = 'zh';
  @State private fullscreenReader: boolean = true;
  @State private floatingReaderControls: boolean = true;

  aboutToAppear(): void {
    this.queryText = '';
  }

  onBackPress(): boolean {
    if (this.mode === 'reader' || this.mode === 'rendered_reader') {
      if (this.chapters.length > 0) {
        this.mode = 'chapters';
      } else if (this.results.length > 0) {
        this.mode = 'results';
      } else {
        this.mode = 'home';
      }
      this.activeTab = 'search';
      return true;
    }
    if (this.mode === 'chapters') {
      this.mode = this.results.length > 0 ? 'results' : 'home';
      this.activeTab = 'search';
      return true;
    }
    if (this.activeTab !== 'search') {
      this.activeTab = 'search';
      this.mode = this.results.length > 0 ? 'results' : 'home';
      return true;
    }
    if (this.mode === 'results') {
      this.mode = 'home';
      return true;
    }
    return false;
  }

  private selectedRule(): ComicSourceRule {
    if (this.selectedSourceIndex < 0 || this.selectedSourceIndex >= this.rules.length) {
      return this.rules[0];
    }
    return this.rules[this.selectedSourceIndex];
  }

  private genericRule(): ComicSourceRule {
    const found = this.rules.find((item: ComicSourceRule) => item.id === 'generic_html_public');
    return found ? found : this.selectedRule();
  }

  private findRule(sourceId: string): ComicSourceRule {
    const found = this.rules.find((item: ComicSourceRule) => item.id === sourceId);
    if (found) {
      return found;
    }
    return this.genericRule();
  }

  private selectedEngine(): SearchEngineConfig {
    if (this.selectedEngineIndex < 0 || this.selectedEngineIndex >= this.searchEngines.length) {
      return this.searchEngines[0];
    }
    return this.searchEngines[this.selectedEngineIndex];
  }

  private nowText(): string {
    const date = new Date();
    const month = date.getMonth() + 1;
    const day = date.getDate();
    const hour = date.getHours();
    const minute = date.getMinutes();
    const minuteText = minute < 10 ? '0' + minute : '' + minute;
    return `${month}-${day} ${hour}:${minuteText}`;
  }

  private searchEnabledRules(): ComicSourceRule[] {
    if (!this.enableHtmlRules) {
      return [];
    }
    const enabled: ComicSourceRule[] = [];
    for (let i = 0; i < this.rules.length; i++) {
      if (this.rules[i].searchUrl.trim().length > 0) {
        enabled.push(this.rules[i]);
      }
    }
    return enabled;
  }

  private enabledApiCount(): number {
    let count = 0;
    if (this.enableInternetArchive) { count++; }
    if (this.enableOpenLibrary) { count++; }
    if (this.enableLibraryOfCongress) { count++; }
    if (this.enableWikimedia) { count++; }
    if (this.enablePepper) { count++; }
    return count;
  }

  private enabledEngineCount(): number {
    if (!this.enableSearchEngines || this.searchMode === '仅公开API') {
      return 0;
    }
    if (this.searchAllEngines) {
      let count = 0;
      for (let i = 0; i < this.searchEngines.length; i++) {
        if (this.searchEngines[i].enabled && isEngineConfigured(this.searchEngines[i], this.braveApiKey, this.googleApiKey, this.googleCx)) {
          count++;
        }
      }
      return count;
    }
    return this.selectedEngine().enabled && isEngineConfigured(this.selectedEngine(), this.braveApiKey, this.googleApiKey, this.googleCx) ? 1 : 0;
  }

  private totalSearchSourceCount(): number {
    let count = 0;
    if (this.searchMode !== '仅搜索引擎') {
      count += this.enabledApiCount();
      count += this.searchEnabledRules().length;
    }
    count += this.enabledEngineCount();
    return count;
  }

  private normalizeGroupKey(title: string): string {
    const value = title.toLowerCase()
      .replace(/file:/g, '')
      .replace(/\.(jpg|jpeg|png|webp|gif|avif)$/g, '')
      .replace(/[\[\]\(\)【】（）{}<>《》_\-–—:：|,，.。!！?？]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
    return value.length === 0 ? '未命名' : value;
  }

  private groupTitle(item: SearchResultItem): string {
    if (item.groupName !== undefined && item.groupName.length > 0) {
      return item.groupName;
    }
    return item.title;
  }

  private groupedResults(): ResultGroup[] {
    const groups: ResultGroup[] = [];
    for (let i = 0; i < this.results.length; i++) {
      const item = this.results[i];
      const name = this.groupByName ? this.groupTitle(item) : item.title + ' · ' + item.sourceName;
      const key = this.groupByName ? this.normalizeGroupKey(name) : item.url;
      let groupIndex = -1;
      for (let j = 0; j < groups.length; j++) {
        if (groups[j].key === key) {
          groupIndex = j;
          break;
        }
      }
      if (groupIndex < 0) {
        groups.push({ name: name, key: key, count: 1, items: [item] });
      } else {
        groups[groupIndex].items.push(item);
        groups[groupIndex].count = groups[groupIndex].items.length;
      }
    }
    return groups;
  }

  private async startSearch(): Promise<void> {
    const keyword = this.queryText.trim();
    this.activeTab = 'search';
    if (keyword.length === 0) {
      this.statusText = '请输入漫画名称。';
      return;
    }
    if (looksLikeUrl(keyword)) {
      await this.loadDetail(normalizeUserUrl(keyword), '公开URL解析', ruleForPublicUrl(normalizeUserUrl(keyword), this.genericRule()));
      return;
    }
    await this.searchKeyword(keyword);
  }

  private nextSourceFilterMode(): void {
    if (this.sourceFilterMode === '全部公开可访问') {
      this.sourceFilterMode = '官方/公共馆藏';
    } else if (this.sourceFilterMode === '官方/公共馆藏') {
      this.sourceFilterMode = '搜索发现全部';
    } else {
      this.sourceFilterMode = '全部公开可访问';
    }
  }

  private resultMatchesSourceFilter(item: SearchResultItem): boolean {
    if (this.excludeLoginPayResults && isKnownLoginOrPayDomain(item.url)) {
      return false;
    }
    if (item.resultType === 'search-engine' && !this.includeSearchEngineDiscovered) {
      return false;
    }
    const officialOrCollection = isOfficialOrPublicCollectionDomain(item.url) ||
      item.sourceId === internetArchiveSourceId() ||
      item.sourceId === openLibrarySourceId() ||
      item.sourceId === wikimediaSourceId() ||
      item.sourceId === libraryOfCongressSourceId() ||
      item.sourceId === pepperSourceId() ||
      item.sourceId === 'tencent_ac_official_catalog' ||
      item.sourceId === 'webtoon_canvas_public_access';
    const unverified = isUnverifiedPublicDomain(item.url) ||
      item.sourceId === 'kaixinman_public_access' ||
      item.sourceId === 'soullandmanga_public_access' ||
      item.sourceId === 'mgeko_public_access' ||
      item.sourceId === 'manhuagui_catalog_public_access' ||
      item.sourceId === 'douluodalu_cc_public_access' ||
      item.sourceId === 'mh160mh_public_access' ||
      item.sourceId === 'shenlanqiyu_public_access' ||
      item.sourceId === 'manhuaus_public_access' ||
      item.sourceId === 'mangafire_public_access' ||
      item.sourceId === 'mangadna_public_access' ||
      item.sourceId === 'mangaread_public_access' ||
      item.sourceId === 'mycomic_public_access';
    if (officialOrCollection && !this.includeOfficialPreviewSources) {
      return false;
    }
    if (unverified && !this.includeUnverifiedPublicSources) {
      return false;
    }
    if (this.sourceFilterMode === '官方/公共馆藏') {
      return officialOrCollection;
    }
    return true;
  }

  private ruleForItemUrl(url: string, sourceId: string): ComicSourceRule {
    const fallback = this.findRule(sourceId);
    return ruleForPublicUrl(url, fallback);
  }

  private appendResults(sourceItems: SearchResultItem[]): void {
    const next: SearchResultItem[] = [];
    for (let i = 0; i < this.results.length; i++) {
      next.push(this.results[i]);
    }
    for (let j = 0; j < sourceItems.length; j++) {
      if (next.length >= this.maxSearchResults) {
        break;
      }
      const item = sourceItems[j];
      if (!this.resultMatchesSourceFilter(item)) {
        continue;
      }
      if (!next.some((oldItem: SearchResultItem) => oldItem.url === item.url || (oldItem.sourceName === item.sourceName && oldItem.title === item.title))) {
        next.push(item);
      }
    }
    this.results = next;
  }

  private updateResultCover(url: string, cover: string): void {
    const next: SearchResultItem[] = [];
    for (let i = 0; i < this.results.length; i++) {
      const item = this.results[i];
      if (item.url === url) {
        next.push({
          title: item.title,
          url: item.url,
          cover: cover,
          sourceId: item.sourceId,
          sourceName: item.sourceName,
          isChapter: item.isChapter,
          resultType: item.resultType,
          groupName: item.groupName,
          description: item.description
        });
      } else {
        next.push(item);
      }
    }
    this.results = next;
  }

  private async searchSelectedEngines(keyword: string): Promise<void> {
    if (!this.enableSearchEngines || this.searchMode === '仅公开API') {
      return;
    }
    const query = buildEngineQuery(keyword, this.extraSearchTerms, this.languageMode, this.siteHint);
    const engines: SearchEngineConfig[] = [];
    if (this.searchAllEngines || this.searchMode === '全引擎+公开API') {
      for (let i = 0; i < this.searchEngines.length; i++) {
        if (this.searchEngines[i].enabled) {
          engines.push(this.searchEngines[i]);
        }
      }
    } else {
      if (this.selectedEngine().enabled) {
        engines.push(this.selectedEngine());
      }
    }
    let used = 0;
    for (let i = 0; i < engines.length; i++) {
      const engine = engines[i];
      if (!engine.enabled) {
        continue;
      }
      if (!isEngineConfigured(engine, this.braveApiKey, this.googleApiKey, this.googleCx)) {
        this.statusText = `${engine.name} 需要配置 API Key/CX，已跳过。`;
        continue;
      }
      try {
        const url = buildSearchEngineUrl(engine, query, this.braveApiKey, this.googleApiKey, this.googleCx);
        const body = await HttpClient.getTextWithHeaders(url, searchEngineUserAgent(), '', engineHeaders(engine, this.braveApiKey));
        const parsed = parseSearchEngineResults(body, engine, keyword, url);
        this.appendResults(parsed);
        used++;
        this.statusText = `${engine.name} 返回 ${parsed.length} 个相关公开网页，当前总数 ${this.results.length}。`;
      } catch (err) {
        this.statusText = `${engine.name} 检索失败，继续其它源。`;
      }
    }
    if (used === 0 && this.searchMode === '仅搜索引擎') {
      this.statusText = '没有可用搜索引擎：请在设置选择无Key引擎，或填写 Brave/Google API Key。';
    }
  }

  private async searchBuiltinApiSources(keyword: string): Promise<void> {
    if (this.searchMode === '仅搜索引擎') {
      return;
    }
    if (this.enablePepper) {
      const pepperItems = searchPepperCatalog(keyword);
      if (pepperItems.length > 0) {
        this.appendResults(pepperItems);
        this.statusText = `Pepper&Carrot公开目录命中 ${pepperItems.length} 个结果。`;
      }
    }

    if (this.enableInternetArchive) {
      try {
        const iaUrl = buildInternetArchiveSearchUrl(keyword);
        const iaJson = await HttpClient.getText(iaUrl, 'ComicReaderHarmony/5.0 Mozilla/5.0', 'https://archive.org/');
        const iaItems = parseInternetArchiveSearch(iaJson, keyword);
        this.appendResults(iaItems);
        this.statusText = `Internet Archive 返回 ${iaItems.length} 个结果，当前总数 ${this.results.length}。`;
      } catch (err) {
        this.statusText = 'Internet Archive公开API检索失败，继续其它公开源。';
      }
    }

    if (this.enableOpenLibrary) {
      try {
        const olUrl = buildOpenLibrarySearchUrl(keyword);
        const olJson = await HttpClient.getText(olUrl, 'ComicReaderHarmony/5.0 Mozilla/5.0', 'https://openlibrary.org/');
        const olItems = parseOpenLibrarySearch(olJson, keyword);
        this.appendResults(olItems);
        this.statusText = `Open Library 返回 ${olItems.length} 个可转Internet Archive阅读的结果，当前总数 ${this.results.length}。`;
      } catch (err) {
        this.statusText = 'Open Library公开API检索失败，继续其它公开源。';
      }
    }

    if (this.enableLibraryOfCongress) {
      try {
        const locUrl = buildLibraryOfCongressSearchUrl(keyword);
        const locJson = await HttpClient.getText(locUrl, 'ComicReaderHarmony/5.0 Mozilla/5.0', 'https://www.loc.gov/');
        const locItems = parseLibraryOfCongressSearch(locJson, keyword);
        this.appendResults(locItems);
        this.statusText = `Library of Congress 返回 ${locItems.length} 个公开影像结果，当前总数 ${this.results.length}。`;
      } catch (err) {
        this.statusText = 'Library of Congress公开API检索失败，继续其它公开源。';
      }
    }

    if (this.enableWikimedia) {
      try {
        const wikiUrl = buildWikimediaSearchUrl(keyword);
        const wikiJson = await HttpClient.getText(wikiUrl, 'ComicReaderHarmony/5.0 Mozilla/5.0', 'https://commons.wikimedia.org/');
        const wikiItems = parseWikimediaSearch(wikiJson, keyword);
        this.appendResults(wikiItems);
        this.statusText = `Wikimedia Commons 返回 ${wikiItems.length} 个图片结果，当前总数 ${this.results.length}。`;
      } catch (err) {
        this.statusText = 'Wikimedia Commons公开API检索失败，继续规则源。';
      }
    }
  }

  private async searchHtmlRuleSources(keyword: string): Promise<void> {
    if (this.searchMode === '仅搜索引擎') {
      return;
    }
    const enabledRules = this.searchEnabledRules();
    let successCount = 0;
    let failedCount = 0;
    for (let i = 0; i < enabledRules.length; i++) {
      const rule = enabledRules[i];
      const searchUrl = rule.searchUrl.replace('{keyword}', encodeURIComponent(keyword));
      try {
        const html = await HttpClient.getText(searchUrl, rule.userAgent, rule.referer.length > 0 ? rule.referer : rule.homepage);
        const parsed = parseSearchResults(html, rule, searchUrl, keyword);
        if (parsed.length > 0) {
          successCount++;
          this.appendResults(parsed);
        }
        this.statusText = `规则源整理中：总结果 ${this.results.length}，成功规则源 ${successCount} 个，失败 ${failedCount} 个。`;
      } catch (err) {
        failedCount++;
      }
    }
  }

  private async searchKeyword(keyword: string): Promise<void> {
    this.activeTab = 'search';
    this.mode = 'results';
    this.results = [];
    this.chapters = [];
    this.images = [];
    this.currentTitle = keyword;
    this.currentUrl = '';
    this.currentChapterTitle = '';
    this.currentCover = '';
    this.currentSourceId = '';
    this.currentSourceName = '';
    this.isLoading = true;
    this.statusText = `正在搜索“${keyword}”：模式 ${this.searchMode}，过滤 ${this.sourceFilterMode}，预计检索 ${this.totalSearchSourceCount()} 个源。`;

    if (this.searchMode === '仅搜索引擎') {
      await this.searchSelectedEngines(keyword);
    } else if (this.searchMode === '仅公开API') {
      await this.searchBuiltinApiSources(keyword);
      await this.searchHtmlRuleSources(keyword);
    } else {
      await this.searchSelectedEngines(keyword);
      await this.searchBuiltinApiSources(keyword);
      await this.searchHtmlRuleSources(keyword);
    }

    if (this.results.length === 0) {
      this.isLoading = false;
      this.statusText = `没有搜索到可直接解析的公开结果。已按当前设置检索搜索引擎/公开API/HTML规则；可尝试在设置里切换搜索引擎、开启全引擎、添加站点提示或填写官方API Key。`;
      return;
    }

    if (this.autoCoverEnabled) {
      this.statusText = `已找到 ${this.results.length} 个条目，正在补全封面并按名称归类...`;
      await this.enrichResultCovers(this.maxCoverEnrich);
    }
    this.isLoading = false;
    this.statusText = `搜索完成：${this.results.length} 个条目，归类为 ${this.groupedResults().length} 组。点击封面进入章节或卷轴阅读。`;
  }

  private async enrichResultCovers(maxCount: number): Promise<void> {
    const count = Math.min(maxCount, this.results.length);
    let done = 0;
    for (let i = 0; i < count; i++) {
      const item = this.results[i];
      if (item.cover.length > 0 || item.sourceId === internetArchiveSourceId() || item.sourceId === openLibrarySourceId() || item.sourceId === wikimediaSourceId() || item.sourceId === libraryOfCongressSourceId() || item.sourceId === pepperSourceId()) {
        continue;
      }
      const rule = this.ruleForItemUrl(item.url, item.sourceId);
      try {
        const html = await HttpClient.getText(item.url, rule.userAgent, rule.referer.length > 0 ? rule.referer : item.url);
        const parsedImages = parseImages(html, rule, item.url);
        if (parsedImages.length > 0) {
          this.updateResultCover(item.url, parsedImages[0].url);
          done++;
          this.statusText = `正在补全封面：已补全 ${done} 张，结果 ${this.results.length} 个。`;
        }
      } catch (err) {
      }
    }
  }

  private mergeReaderImages(base: ReaderImageItem[], incoming: ReaderImageItem[]): ReaderImageItem[] {
    const next: ReaderImageItem[] = [];
    for (let i = 0; i < base.length; i++) {
      next.push({ url: base[i].url, index: next.length + 1, status: base[i].status });
    }
    for (let j = 0; j < incoming.length; j++) {
      const image = incoming[j];
      if (!this.dedupeImages || !next.some((oldItem: ReaderImageItem) => oldItem.url === image.url)) {
        next.push({ url: image.url, index: next.length + 1, status: 'waiting' });
      }
    }
    return next;
  }

  private async fetchReaderImagesWithPagination(firstUrl: string, rule: ComicSourceRule): Promise<ReaderImageItem[]> {
    let pageUrl = firstUrl;
    let allImages: ReaderImageItem[] = [];
    const visited: string[] = [];
    const ruleMax = rule.maxReaderPages !== undefined && rule.maxReaderPages > 0 ? rule.maxReaderPages : 1;
    const maxPages = Math.min(Math.max(ruleMax, this.maxReaderPagesSetting), 30);
    for (let page = 0; page < maxPages; page++) {
      if (pageUrl.length === 0 || visited.indexOf(pageUrl) >= 0) {
        break;
      }
      visited.push(pageUrl);
      const html = await HttpClient.getText(pageUrl, rule.userAgent, rule.referer.length > 0 ? rule.referer : pageUrl);
      const pageImages = parseImages(html, rule, pageUrl);
      allImages = this.mergeReaderImages(allImages, pageImages);
      const nextUrl = parseNextPageUrl(html, rule, pageUrl);
      if (nextUrl.length === 0 || nextUrl === pageUrl) {
        break;
      }
      pageUrl = nextUrl;
      this.statusText = `正在追踪章节分页：第 ${page + 2} 页，已提取 ${allImages.length} 张图片。`;
    }
    return allImages;
  }



  private looksLikeReaderPageUrl(url: string): boolean {
    const lower = url.toLowerCase();
    return lower.indexOf('/chapter/') >= 0 ||
      lower.indexOf('/read/') >= 0 ||
      lower.indexOf('/viewer') >= 0 ||
      lower.indexOf('/kanmanhua/') >= 0 ||
      lower.indexOf('/manhua/') >= 0 ||
      lower.indexOf('/manga/') >= 0 ||
      /chapter[-_\/0-9a-z.]+/i.test(lower) ||
      /\/\d+\.html(\?|#|$)/i.test(lower);
  }

  private shouldUseRenderedReaderFallback(url: string, rule: ComicSourceRule): boolean {
    if (!this.enableRenderedWebFallback) {
      return false;
    }
    const lower = url.toLowerCase();
    if (isKnownLoginOrPayDomain(url)) {
      return false;
    }
    if (rule.id === 'kaixinman_public_access' || lower.indexOf('kaixinman.com/chapter/') >= 0) {
      return true;
    }
    if (isTop20AuditedPublicReadableDomain(url) && this.looksLikeReaderPageUrl(url)) {
      return true;
    }
    return false;
  }

  private readerCleanupScript(): string {
    return "(function(){var css='header,footer,nav,.header,.footer,.navbar,.recommend,.guess,.ads,.ad,.statement,.copyright{display:none!important;} body{margin:0!important;background:#111!important;} img{display:block!important;max-width:100%!important;width:100%!important;height:auto!important;margin:0 auto!important;}';var st=document.createElement('style');st.innerHTML=css;document.head.appendChild(st);var imgs=[].slice.call(document.images||[]);for(var i=0;i<imgs.length;i++){var im=imgs[i];var v=im.getAttribute('data-src')||im.getAttribute('data-original')||im.getAttribute('data-lazy-src')||im.getAttribute('data-url')||im.getAttribute('src');if(v){im.setAttribute('src',v);}}return document.images.length.toString();})();";
  }

  private openRenderedScrollReader(url: string, title: string, rule: ComicSourceRule): void {
    this.activeTab = 'search';
    this.mode = 'rendered_reader';
    this.images = [];
    this.currentChapterTitle = title;
    this.renderedReaderTitle = title;
    this.renderedReaderUrl = url;
    this.currentUrl = url;
    this.currentSourceId = rule.id;
    this.currentSourceName = rule.name;
    this.isLoading = false;
    this.addHistory(this.currentTitle.length > 0 ? this.currentTitle : title, title, url, rule.name);
    this.touchShelfRead(url, title);
    this.statusText = '静态HTML没有直接暴露图片，已切换到公开渲染卷轴模式：页面无地址栏打开，并注入CSS隐藏导航/页脚、保留漫画图片纵向滚动。';
  }

  private async loadArchiveItem(url: string, title: string): Promise<void> {
    const identifier = archiveIdentifierFromUrl(url);
    if (identifier.length === 0) {
      this.statusText = 'Internet Archive条目标识无效。';
      return;
    }
    this.activeTab = 'search';
    this.mode = 'reader';
    this.images = [];
    this.currentTitle = title;
    this.currentChapterTitle = title;
    this.currentUrl = url;
    this.currentSourceId = internetArchiveSourceId();
    this.currentSourceName = 'Internet Archive公开馆藏';
    this.currentCover = 'https://archive.org/services/img/' + encodeURIComponent(identifier);
    this.isLoading = true;
    this.statusText = '正在读取Internet Archive IIIF清单并生成卷轴：' + identifier;
    try {
      const manifest = await HttpClient.getText(buildInternetArchiveManifestUrl(identifier), 'ComicReaderHarmony/5.0 Mozilla/5.0', 'https://archive.org/');
      let parsedImages = parseInternetArchiveManifestImages(manifest);
      if (parsedImages.length === 0) {
        this.statusText = 'IIIF清单没有图片页，正在读取metadata文件列表做图片兜底...';
        const metadata = await HttpClient.getText(buildInternetArchiveMetadataUrl(identifier), 'ComicReaderHarmony/5.0 Mozilla/5.0', 'https://archive.org/');
        parsedImages = parseInternetArchiveMetadataImages(metadata, identifier);
      }
      this.images = parsedImages;
      this.isLoading = false;
      if (parsedImages.length === 0) {
        this.statusText = '该公开馆藏没有可直接卷轴化的图片页。';
      } else {
        this.addHistory(title, 'Internet Archive公开卷轴', url, 'Internet Archive公开馆藏');
        this.touchShelfRead(url, 'Internet Archive公开卷轴');
        this.statusText = `卷轴生成完成：${parsedImages.length} 页。`;
      }
    } catch (err) {
      this.isLoading = false;
      this.statusText = 'Internet Archive IIIF清单读取失败：' + JSON.stringify(err);
    }
  }

  private openDirectImageResult(item: SearchResultItem): void {
    let imageUrl = '';
    this.images = [];
    if (isWikimediaPseudoUrl(item.url)) {
      imageUrl = wikimediaImageFromUrl(item.url);
    } else if (isLocPseudoUrl(item.url)) {
      imageUrl = locImageFromUrl(item.url);
    } else if (isPepperPseudoUrl(item.url)) {
      const pepperImages = parsePepperImages(item.url);
      this.images = pepperImages;
      imageUrl = pepperImages.length > 0 ? pepperImages[0].url : '';
    }
    this.activeTab = 'search';
    this.mode = 'reader';
    this.chapters = [];
    this.currentTitle = item.title;
    this.currentChapterTitle = item.title;
    this.currentUrl = item.url;
    this.currentCover = item.cover.length > 0 ? item.cover : imageUrl;
    this.currentSourceId = item.sourceId;
    this.currentSourceName = item.sourceName;
    this.isLoading = false;
    if (this.images.length === 0 && imageUrl.length > 0) {
      this.images = [{ url: imageUrl, index: 1, status: 'waiting' }];
    }
    if (this.images.length === 0) {
      this.statusText = '没有可直接显示的图片。';
    } else {
      this.addHistory(item.title, item.title, item.url, item.sourceName);
      this.touchShelfRead(item.url, item.title);
      this.statusText = `卷轴生成完成：${this.images.length} 张图片。`;
    }
  }

  private async loadDetail(url: string, title: string, rule: ComicSourceRule): Promise<void> {
    if (isArchivePseudoUrl(url)) {
      await this.loadArchiveItem(url, title);
      return;
    }
    if (isWikimediaPseudoUrl(url) || isLocPseudoUrl(url) || isPepperPseudoUrl(url)) {
      this.openDirectImageResult({ title: title, url: url, cover: '', sourceId: '', sourceName: '公开图片', isChapter: true });
      return;
    }

    this.activeTab = 'search';
    this.mode = 'chapters';
    this.chapters = [];
    this.images = [];
    this.currentTitle = title.length > 0 ? title : url;
    this.currentUrl = url;
    this.currentChapterTitle = '';
    this.currentSourceId = rule.id;
    this.currentSourceName = rule.name;
    this.isLoading = true;
    this.statusText = '正在解析漫画详情/目录：' + url;
    try {
      const html = await HttpClient.getText(url, rule.userAgent, rule.referer.length > 0 ? rule.referer : url);
      const parsedChapters = parseChapters(html, rule, url);
      this.chapters = parsedChapters;
      if (parsedChapters.length > 0) {
        this.isLoading = false;
        this.statusText = `目录解析完成：${parsedChapters.length} 个章节。`;
        return;
      }
      const parsedImages = parseImages(html, rule, url);
      if (parsedImages.length > 0) {
        const fullImages = await this.fetchReaderImagesWithPagination(url, rule);
        this.images = fullImages.length > 0 ? fullImages : parsedImages;
        this.currentChapterTitle = '当前页面';
        this.mode = 'reader';
        this.addHistory(this.currentTitle, this.currentChapterTitle, url, rule.name);
        this.touchShelfRead(url, this.currentChapterTitle);
        this.isLoading = false;
        this.statusText = `未发现章节目录，已直接提取 ${this.images.length} 张图片进入卷轴阅读。`;
        return;
      }
      if (this.shouldUseRenderedReaderFallback(url, rule)) {
        this.openRenderedScrollReader(url, title.length > 0 ? title : '公开卷轴阅读', rule);
        return;
      }
      this.isLoading = false;
      this.statusText = '没有解析到章节或图片。可在设置里调整HTML规则，或切换搜索引擎/公开源。';
    } catch (err) {
      this.isLoading = false;
      this.statusText = '解析失败：' + JSON.stringify(err);
    }
  }

  private async loadChapter(chapter: ChapterItem, rule: ComicSourceRule): Promise<void> {
    await this.loadChapterByUrl(chapter.url, chapter.title, rule);
  }

  private async loadChapterByUrl(url: string, title: string, rule: ComicSourceRule): Promise<void> {
    if (isArchivePseudoUrl(url)) {
      await this.loadArchiveItem(url, title);
      return;
    }
    if (isWikimediaPseudoUrl(url) || isLocPseudoUrl(url) || isPepperPseudoUrl(url)) {
      this.openDirectImageResult({ title: title, url: url, cover: '', sourceId: '', sourceName: '公开图片', isChapter: true });
      return;
    }

    this.activeTab = 'search';
    this.mode = 'reader';
    this.images = [];
    this.currentChapterTitle = title;
    this.currentUrl = url;
    this.currentSourceId = rule.id;
    this.currentSourceName = rule.name;
    this.isLoading = true;
    this.statusText = '正在抓取章节图片：' + title;
    try {
      const parsedImages = await this.fetchReaderImagesWithPagination(url, rule);
      this.images = parsedImages;
      this.isLoading = false;
      if (parsedImages.length === 0) {
        if (this.shouldUseRenderedReaderFallback(url, rule)) {
          this.openRenderedScrollReader(url, title, rule);
          return;
        }
        this.statusText = '没有提取到图片。已尝试静态HTML、懒加载字段、内联JS图片URL和章节下一页追踪。';
      } else {
        this.addHistory(this.currentTitle.length > 0 ? this.currentTitle : title, title, url, rule.name);
        this.touchShelfRead(url, title);
        this.statusText = `卷轴生成完成：${parsedImages.length} 张图片。`;
      }
    } catch (err) {
      this.isLoading = false;
      this.statusText = '章节抓取失败：' + JSON.stringify(err);
    }
  }

  private async openSearchResult(item: SearchResultItem): Promise<void> {
    this.currentTitle = item.title;
    this.currentUrl = item.url;
    this.currentCover = item.cover;
    this.currentSourceId = item.sourceId;
    this.currentSourceName = item.sourceName;
    if (item.sourceId === internetArchiveSourceId() || item.sourceId === openLibrarySourceId() || isArchivePseudoUrl(item.url)) {
      await this.loadArchiveItem(item.url, item.title);
      return;
    }
    if (item.sourceId === wikimediaSourceId() || item.sourceId === libraryOfCongressSourceId() || item.sourceId === pepperSourceId()) {
      this.openDirectImageResult(item);
      return;
    }
    const rule = this.ruleForItemUrl(item.url, item.sourceId);
    if (item.isChapter) {
      await this.loadChapterByUrl(item.url, item.title, rule);
      return;
    }
    await this.loadDetail(item.url, item.title, rule);
  }

  private addHistory(title: string, chapterTitle: string, url: string, sourceName: string): void {
    const filtered = this.history.filter((item: ReadingHistoryItem) => item.url !== url);
    filtered.unshift({ title: title, chapterTitle: chapterTitle, url: url, sourceName: sourceName, timeText: this.nowText() });
    this.history = filtered.slice(0, this.keepHistoryCount);
  }

  private addResultToShelf(item: SearchResultItem): void {
    const filtered = this.bookshelf.filter((old: BookshelfItem) => old.url !== item.url);
    filtered.unshift({
      title: item.title,
      url: item.url,
      cover: item.cover,
      sourceId: item.sourceId,
      sourceName: item.sourceName,
      lastChapterTitle: '',
      addedTimeText: this.nowText(),
      lastReadTimeText: '',
      lastReadUrl: '',
      progressPercent: 0,
      readCount: 0
    });
    this.bookshelf = filtered;
    this.statusText = '已加入书架：' + item.title;
  }

  private addCurrentToShelf(): void {
    if (this.currentUrl.length === 0 && this.currentTitle.length === 0) {
      this.statusText = '当前没有可加入书架的条目。';
      return;
    }
    const item: SearchResultItem = {
      title: this.currentTitle.length > 0 ? this.currentTitle : this.currentChapterTitle,
      url: this.currentUrl,
      cover: this.currentCover,
      sourceId: this.currentSourceId,
      sourceName: this.currentSourceName.length > 0 ? this.currentSourceName : '公开源',
      isChapter: false
    };
    this.addResultToShelf(item);
  }

  private removeShelf(url: string): void {
    this.bookshelf = this.bookshelf.filter((item: BookshelfItem) => item.url !== url);
    this.statusText = '已从书架移除。';
  }

  private touchShelfRead(url: string, chapterTitle: string): void {
    const next: BookshelfItem[] = [];
    for (let i = 0; i < this.bookshelf.length; i++) {
      const item = this.bookshelf[i];
      if (item.url === url || item.title === this.currentTitle) {
        next.push({
          title: item.title,
          url: item.url,
          cover: item.cover.length > 0 ? item.cover : this.currentCover,
          sourceId: item.sourceId,
          sourceName: item.sourceName,
          lastChapterTitle: chapterTitle,
          addedTimeText: item.addedTimeText,
          lastReadTimeText: this.nowText(),
          lastReadUrl: this.currentUrl,
          progressPercent: this.chapters.length > 0 ? Math.min(99, Math.max(1, Math.floor((this.chapters.findIndex((chapter: ChapterItem) => chapter.title === chapterTitle) + 1) * 100 / this.chapters.length))) : (item.progressPercent !== undefined ? item.progressPercent : 12),
          readCount: item.readCount !== undefined ? item.readCount + 1 : 1
        });
      } else {
        next.push(item);
      }
    }
    this.bookshelf = next;
  }

  private async openShelf(item: BookshelfItem): Promise<void> {
    this.currentTitle = item.title;
    this.currentCover = item.cover;
    this.currentSourceId = item.sourceId;
    this.currentSourceName = item.sourceName;
    if (item.lastReadUrl !== undefined && item.lastReadUrl.length > 0) {
      await this.loadChapterByUrl(item.lastReadUrl, item.lastChapterTitle.length > 0 ? item.lastChapterTitle : item.title, this.ruleForItemUrl(item.lastReadUrl, item.sourceId));
      return;
    }
    await this.loadDetail(item.url, item.title, this.ruleForItemUrl(item.url, item.sourceId));
  }

  private runDemoSearch(): void {
    this.queryText = 'little nemo';
    this.searchKeyword('little nemo');
  }


  private async updateRemoteRules(): Promise<void> {
    const url = this.remoteRuleUrl.trim();
    if (url.length === 0) {
      this.remoteRuleStatus = '远程规则地址为空';
      return;
    }
    this.isLoading = true;
    this.remoteRuleStatus = '正在从 GitHub 更新远程规则...';
    try {
      const remoteRules = await RemoteRuleService.fetchRemoteRules(url);
      this.rules = RemoteRuleService.mergeRules(DEFAULT_SOURCES, remoteRules);
      this.remoteRuleCount = remoteRules.length;
      this.selectedSourceIndex = 0;
      this.remoteRuleStatus = '远程规则更新成功：' + remoteRules.length + ' 条；已优先合并到源列表。';
      this.statusText = this.remoteRuleStatus;
    } catch (err) {
      this.remoteRuleStatus = '远程规则更新失败：' + JSON.stringify(err);
      this.statusText = this.remoteRuleStatus;
    } finally {
      this.isLoading = false;
    }
  }

  private addCustomRule(): void {
    try {
      const parsed = JSON.parse(this.customRuleText) as ComicSourceRule;
      if (!parsed.id || !parsed.name || !parsed.readerImageRegex) {
        this.statusText = '规则缺少 id、name 或 readerImageRegex。';
        return;
      }
      const filtered = this.rules.filter((item: ComicSourceRule) => item.id !== parsed.id);
      filtered.push(parsed);
      this.rules = filtered;
      this.selectedSourceIndex = this.rules.length - 1;
      this.statusText = '已添加/替换公开源规则：' + parsed.name;
    } catch (err) {
      this.statusText = '源规则JSON解析失败：' + JSON.stringify(err);
    }
  }

  private markImage(index: number, status: string): void {
    const next: ReaderImageItem[] = [];
    for (let i = 0; i < this.images.length; i++) {
      const item = this.images[i];
      next.push(item.index === index ? { url: item.url, index: item.index, status: status } : item);
    }
    this.images = next;
  }

  private nextSearchMode(): void {
    if (this.searchMode === '混合') this.searchMode = '仅搜索引擎';
    else if (this.searchMode === '仅搜索引擎') this.searchMode = '仅公开API';
    else if (this.searchMode === '仅公开API') this.searchMode = '全引擎+公开API';
    else this.searchMode = '混合';
  }

  private nextLanguageMode(): void {
    if (this.languageMode === '自动') this.languageMode = '中文';
    else if (this.languageMode === '中文') this.languageMode = '英文';
    else if (this.languageMode === '英文') this.languageMode = '日文';
    else if (this.languageMode === '日文') this.languageMode = '韩文';
    else this.languageMode = '自动';
  }

  private cycleEngine(): void {
    this.selectedEngineIndex = (this.selectedEngineIndex + 1) % this.searchEngines.length;
  }

  private toggleEngineEnabled(index: number): void {
    const next: SearchEngineConfig[] = [];
    for (let i = 0; i < this.searchEngines.length; i++) {
      const engine = this.searchEngines[i];
      next.push({
        id: engine.id,
        name: engine.name,
        description: engine.description,
        engineType: engine.engineType,
        searchUrl: engine.searchUrl,
        requiresKey: engine.requiresKey,
        enabled: i === index ? !engine.enabled : engine.enabled
      });
    }
    this.searchEngines = next;
    this.statusText = (this.searchEngines[index].enabled ? '已启用：' : '已停用：') + this.searchEngines[index].name;
  }

  private isDarkTheme(): boolean {
    return this.appTheme === 'dark';
  }

  private t(key: string): string {
    const zh = this.appLanguage !== 'en';
    if (key === 'search') return zh ? '搜索' : 'Search';
    if (key === 'shelf') return zh ? '书架' : 'Shelf';
    if (key === 'settings') return zh ? '设置' : 'Settings';
    if (key === 'about') return zh ? '关于' : 'About';
    if (key === 'appTitle') return zh ? '漫画浏览器' : 'Comic Reader';
    if (key === 'searchPlaceholder') return zh ? '搜索漫画 / Search comics' : 'Search comics / 漫画';
    if (key === 'searchPublic') return zh ? '搜索公开漫画资源' : 'Search public comic sources';
    if (key === 'homeDesc') return zh ? '聚合公开 API、公开 HTML 源和搜索引擎结果，按名称归类并支持卷轴阅读。' : 'Aggregate public APIs, public HTML sources and search results, grouped by title with scroll reading.';
    if (key === 'theme') return zh ? '主题' : 'Theme';
    if (key === 'language') return zh ? '语言' : 'Language';
    if (key === 'light') return zh ? '明亮' : 'Light';
    if (key === 'dark') return zh ? '暗黑' : 'Dark';
    if (key === 'fullReader') return zh ? '全屏阅读' : 'Full screen reader';
    if (key === 'floatingControls') return zh ? '悬浮控制' : 'Floating controls';
    if (key === 'continueRead') return zh ? '继续阅读' : 'Continue';
    if (key === 'remove') return zh ? '移除' : 'Remove';
    return key;
  }

  private appBg(): string { return this.isDarkTheme() ? '#101418' : '#F7F8FA'; }
  private cardBg(): string { return this.isDarkTheme() ? '#1B222A' : '#FFFFFF'; }
  private glassBg(): string { return this.isDarkTheme() ? '#CC141A20' : '#EFFFFFFF'; }
  private primaryText(): string { return this.isDarkTheme() ? '#F2F5F7' : '#111111'; }
  private secondaryText(): string { return this.isDarkTheme() ? '#AAB4C0' : '#666666'; }
  private mutedText(): string { return this.isDarkTheme() ? '#7F8B96' : '#888888'; }
  private accent(): string { return '#34C759'; }
  private selectedSoftBg(): string { return this.isDarkTheme() ? '#1F34C759' : '#1434C759'; }
  private warnBg(): string { return this.isDarkTheme() ? '#332610' : '#FFF7E6'; }
  private warnText(): string { return this.isDarkTheme() ? '#F8D38D' : '#6A3A00'; }
  private okBg(): string { return this.isDarkTheme() ? '#16351F' : '#F1F8E9'; }
  private okText(): string { return this.isDarkTheme() ? '#9EE6AE' : '#33691E'; }

  private themeLabel(): string {
    return this.isDarkTheme() ? this.t('dark') : this.t('light');
  }

  private languageLabel(): string {
    return this.appLanguage === 'en' ? 'English' : '中文';
  }

  private toggleTheme(): void {
    this.appTheme = this.isDarkTheme() ? 'light' : 'dark';
    this.readerDarkMode = this.isDarkTheme();
    this.statusText = this.appLanguage === 'en' ? 'Theme updated.' : '主题已切换。';
  }

  private toggleLanguage(): void {
    this.appLanguage = 'zh';
    this.statusText = '界面语言已锁定为中文，避免误触后出现英文或中英文混排。';
  }

  private shelfProgressText(item: BookshelfItem): string {
    if (item.progressPercent !== undefined && item.progressPercent > 0) {
      return item.progressPercent + '%';
    }
    if (item.lastChapterTitle.length > 0) return this.appLanguage === 'en' ? 'In progress' : '已开始';
    return this.appLanguage === 'en' ? 'Unread' : '未读';
  }

  private progressValue(item: BookshelfItem): number {
    if (item.progressPercent !== undefined && item.progressPercent > 0) return item.progressPercent;
    return item.lastChapterTitle.length > 0 ? 12 : 0;
  }

  @Builder
  private MiniPill(text: string, selected: boolean) {
    Text(text)
      .fontSize(12)
      .fontColor(selected ? '#FFFFFF' : this.secondaryText())
      .textAlign(TextAlign.Center)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(selected ? this.accent() : (this.isDarkTheme() ? '#26313B' : '#EEF2F5'))
      .borderRadius(16)
  }

  @Builder
  private StatusCard() {
    Text(this.statusText)
      .fontSize(13)
      .fontColor(this.warnText())
      .lineHeight(19)
      .width('100%')
      .padding(10)
      .backgroundColor(this.warnBg())
      .borderRadius(14)
      .margin({ bottom: 12 })
  }

  @Builder
  private AuditCard() {
    Text(this.auditText)
      .fontSize(12)
      .fontColor(this.okText())
      .lineHeight(18)
      .width('100%')
      .padding(10)
      .backgroundColor(this.okBg())
      .borderRadius(14)
      .margin({ bottom: 12 })
  }

  @Builder
  private SearchHeader() {
    Column() {
      Row() {
        Text(this.t('appTitle'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.primaryText())
          .layoutWeight(1)
        // 搜索页只保留搜索功能，不放语言/主题/设置类入口。
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 12, bottom: 6 })

      Row() {
        TextInput({ placeholder: this.t('searchPlaceholder'), text: this.queryText })
          .height(44)
          .layoutWeight(1)
          .fontSize(15)
          .backgroundColor(this.isDarkTheme() ? '#26313B' : '#F0F3F6')
          .borderRadius(22)
          .padding({ left: 14, right: 14 })
          .onChange((value: string) => { this.queryText = value; })
          .onSubmit(() => { this.startSearch(); })
        Button(this.isLoading ? (this.appLanguage === 'en' ? 'Searching' : '搜索中') : this.t('search'))
          .height(44)
          .fontSize(15)
          .fontColor('#FFFFFF')
          .backgroundColor(this.accent())
          .borderRadius(22)
          .margin({ left: 10 })
          .enabled(!this.isLoading)
          .onClick(() => { this.startSearch(); })
      }
      .width('100%')
      .padding({ left: 14, right: 14, bottom: 8 })
    }
    .backgroundColor(this.glassBg())
    .borderRadius({ bottomLeft: 22, bottomRight: 22 })
  }

  @Builder
  private SearchHome() {
    Column() {
      Blank().layoutWeight(1)
      Column() {
        Image($r('app.media.icon'))
          .width(92)
          .height(92)
          .margin({ bottom: 18 })
        Text('漫画浏览器')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.primaryText())
        Text('输入漫画名称，开始搜索公开资源')
          .fontSize(13)
          .fontColor(this.secondaryText())
          .margin({ top: 6, bottom: 20 })
        Row() {
          TextInput({ placeholder: this.t('searchPlaceholder'), text: this.queryText })
            .height(50)
            .layoutWeight(1)
            .fontSize(15)
            .backgroundColor(this.cardBg())
            .borderRadius(25)
            .padding({ left: 16, right: 16 })
            .onChange((value: string) => { this.queryText = value; })
            .onSubmit(() => { this.startSearch(); })
          Button(this.t('search'))
            .height(50)
            .fontSize(15)
            .fontColor('#FFFFFF')
            .backgroundColor(this.accent())
            .borderRadius(25)
            .margin({ left: 10 })
            .enabled(!this.isLoading)
            .onClick(() => { this.startSearch(); })
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
        Row() {
          this.SearchChip('斗罗大陆')
          this.SearchChip('火影忍者')
          this.SearchChip('one piece')
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .margin({ top: 16 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      Blank().layoutWeight(1)
    }
    .layoutWeight(1)
    .backgroundColor(this.appBg())
  }


  @Builder
  private SearchChip(keyword: string) {
    Text(keyword)
      .fontSize(12)
      .fontColor(this.accent())
      .padding({ left: 12, right: 12, top: 7, bottom: 7 })
      .backgroundColor(this.selectedSoftBg())
      .borderRadius(16)
      .margin({ right: 8 })
      .onClick(() => { this.queryText = keyword; this.startSearch(); })
  }

  @Builder
  private StepCard(num: string, title: string, desc: string) {
    Column() {
      Text(num)
        .fontSize(18)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .backgroundColor('#34C759')
        .borderRadius(18)
      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 8 })
      Text(desc)
        .fontSize(12)
        .fontColor(this.secondaryText())
        .lineHeight(17)
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(12)
    .backgroundColor(this.cardBg())
    .borderRadius(12)
  }

  @Builder
  private CoverBox(item: SearchResultItem, heightValue: number) {
    if (item.cover.length > 0) {
      Image(item.cover)
        .width('100%')
        .height(heightValue)
        .objectFit(ImageFit.Cover)
        .backgroundColor('#EEEEEE')
    } else {
      Column() {
        Text(item.title.substring(0, 1))
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#34C759')
        Text(this.autoCoverEnabled ? '封面解析中' : '无封面')
          .fontSize(11)
          .fontColor(this.secondaryText())
          .margin({ top: 6 })
      }
      .width('100%')
      .height(heightValue)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#ECFFF1')
    }
  }

  private cleanResultTitle(raw: string): string {
    let title = raw.trim();
    while (title.indexOf('  ') >= 0) {
      title = title.replace('  ', ' ');
    }
    title = this.cleanResultTitleBySeparator(title, ' - ');
    title = this.cleanResultTitleBySeparator(title, ' | ');
    title = this.cleanResultTitleBySeparator(title, '｜');
    title = this.cleanResultTitleBySeparator(title, '_');
    title = this.cleanResultTitleBySeparator(title, '，');
    title = this.cleanResultTitleBySeparator(title, ',');
    if (title.length > 1 && title.length % 2 === 0) {
      let halfLength = title.length / 2;
      let left = title.substring(0, halfLength).trim();
      let right = title.substring(halfLength).trim();
      if (left.length > 0 && left === right) {
        title = left;
      }
    }
    let words = title.split(' ');
    if (words.length > 1) {
      let compactWords: string[] = [];
      for (let index = 0; index < words.length; index++) {
        let word = words[index].trim();
        if (word.length === 0) {
          continue;
        }
        if (compactWords.length === 0 || compactWords[compactWords.length - 1] !== word) {
          compactWords.push(word);
        }
      }
      title = compactWords.join(' ');
    }
    return title;
  }

  private cleanResultTitleBySeparator(raw: string, separator: string): string {
    if (raw.indexOf(separator) < 0) {
      return raw;
    }
    let parts = raw.split(separator);
    let compactParts: string[] = [];
    for (let index = 0; index < parts.length; index++) {
      let part = parts[index].trim();
      if (part.length === 0) {
        continue;
      }
      if (compactParts.length === 0 || compactParts[compactParts.length - 1] !== part) {
        compactParts.push(part);
      }
    }
    return compactParts.join(separator);
  }

  private resultTitle(item: SearchResultItem): string {
    return this.cleanResultTitle(item.title);
  }

  private cleanResultTitle(raw: string): string {
    let title = raw.trim();
    while (title.indexOf('  ') >= 0) {
      title = title.replace('  ', ' ');
    }
    title = this.cleanResultTitleBySeparator(title, ' - ');
    title = this.cleanResultTitleBySeparator(title, ' | ');
    title = this.cleanResultTitleBySeparator(title, '｜');
    title = this.cleanResultTitleBySeparator(title, '_');
    title = this.cleanResultTitleBySeparator(title, '，');
    title = this.cleanResultTitleBySeparator(title, ',');
    if (title.length > 1 && title.length % 2 === 0) {
      let halfLength = title.length / 2;
      let left = title.substring(0, halfLength).trim();
      let right = title.substring(halfLength).trim();
      if (left.length > 0 && left === right) {
        title = left;
      }
    }
    let words = title.split(' ');
    if (words.length > 1) {
      let compactWords: string[] = [];
      for (let index = 0; index < words.length; index++) {
        let word = words[index].trim();
        if (word.length === 0) {
          continue;
        }
        if (compactWords.length === 0 || compactWords[compactWords.length - 1] !== word) {
          compactWords.push(word);
        }
      }
      title = compactWords.join(' ');
    }
    return title;
  }

  private cleanResultTitleBySeparator(raw: string, separator: string): string {
    if (raw.indexOf(separator) < 0) {
      return raw;
    }
    let parts = raw.split(separator);
    let compactParts: string[] = [];
    for (let index = 0; index < parts.length; index++) {
      let part = parts[index].trim();
      if (part.length === 0) {
        continue;
      }
      if (compactParts.length === 0 || compactParts[compactParts.length - 1] !== part) {
        compactParts.push(part);
      }
    }
    return compactParts.join(separator);
  }

  private resultTitle(item: SearchResultItem): string {
    return this.cleanResultTitle(item.title);
  }

  @Builder
  private ResultCard(item: SearchResultItem) {
    Column() {
      this.CoverBox(item, 142)
      Text(this.resultTitle(item))
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.primaryText())
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .padding({ left: 8, right: 8, top: 8, bottom: 10 })
    }
    .width('100%')
    .clip(true)
    .backgroundColor(this.cardBg())
    .borderRadius(16)
    .shadow({ radius: 6, color: '#10000000', offsetX: 0, offsetY: 2 })
    .onClick(() => this.openSearchResult(item))
  }

  @Builder
  private ResultListCard(item: SearchResultItem) {
    Row() {
      Column() {
        this.CoverBox(item, 76)
      }
      .width(58)
      .height(76)
      .clip(true)
      .borderRadius(12)

      Column() {
        Text(this.resultTitle(item))
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.primaryText())
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(item.sourceName)
          .fontSize(11)
          .fontColor(this.secondaryText())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 6 })
          .width('100%')
      }
      .layoutWeight(1)
      .margin({ left: 12 })
    }
    .width('100%')
    .height(94)
    .padding(8)
    .backgroundColor(this.cardBg())
    .borderRadius(16)
    .margin({ bottom: 8 })
    .onClick(() => this.openSearchResult(item))
  }

  @Builder
  private ResultGroupView(group: ResultGroup) {
    Column() {
      Row() {
        Text(this.cleanResultTitle(group.name))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.primaryText())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Text(group.count + ' 个')
          .fontSize(12)
          .fontColor('#FFFFFF')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.accent())
          .borderRadius(12)
      }
      .width('100%')
      .margin({ bottom: 8 })

      if (this.resultViewMode === 'list') {
        Column() {
          ForEach(group.items, (item: SearchResultItem) => {
            this.ResultListCard(item)
          }, (item: SearchResultItem) => item.url)
        }
        .width('100%')
      } else {
        Grid() {
          ForEach(group.items, (item: SearchResultItem) => {
            GridItem() { this.ResultCard(item) }
          }, (item: SearchResultItem) => item.url)
        }
        .columnsTemplate('1fr 1fr 1fr')
        .columnsGap(10)
        .rowsGap(12)
        .width('100%')
      }
    }
    .width('100%')
    .margin({ bottom: 18 })
  }

  @Builder
  private ResultsPage() {
    Scroll() {
      Column() {
        Row() {
          Column() {
            Text(this.currentTitle.length > 0 ? '搜索：' + this.currentTitle : '漫画结果')
              .fontSize(21)
              .fontWeight(FontWeight.Bold)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
            Text('结果按名称归类显示，点封面进入阅读')
              .fontSize(12)
              .fontColor(this.secondaryText())
              .margin({ top: 3 })
          }
          .layoutWeight(1)
          if (this.results.length > 0) {
            Button('列表')
              .height(32)
              .fontSize(12)
              .fontColor(this.resultViewMode === 'list' ? '#FFFFFF' : this.secondaryText())
              .backgroundColor(this.resultViewMode === 'list' ? this.accent() : this.cardBg())
              .borderRadius(16)
              .onClick(() => { this.resultViewMode = 'list'; })
            Button('网格')
              .height(32)
              .fontSize(12)
              .fontColor(this.resultViewMode === 'grid' ? '#FFFFFF' : this.secondaryText())
              .backgroundColor(this.resultViewMode === 'grid' ? this.accent() : this.cardBg())
              .borderRadius(16)
              .margin({ left: 8 })
              .onClick(() => { this.resultViewMode = 'grid'; this.resultColumns = 3; })
          }
        }
        .width('100%')
        .margin({ bottom: 8 })

        this.StatusCard()

        if (this.results.length === 0) {
          Text(this.isLoading ? '正在搜索公开来源...' : '没有找到结果，换个关键词试试。')
            .fontSize(14)
            .fontColor(this.secondaryText())
            .width('100%')
            .padding(12)
            .backgroundColor(this.cardBg())
            .borderRadius(10)
        } else {
          ForEach(this.groupedResults(), (group: ResultGroup) => { this.ResultGroupView(group) }, (group: ResultGroup) => group.key)
        }
      }
      .width('100%')
      .padding(14)
    }
    .layoutWeight(1)
    .backgroundColor(this.appBg())
  }

  @Builder
  private ChaptersPage() {
    Column() {
      Row() {
        Button('结果')
          .height(34)
          .fontSize(12)
          .onClick(() => { this.mode = this.results.length > 0 ? 'results' : 'home'; })
        Column() {
          Text(this.currentTitle.length > 0 ? this.currentTitle : '章节目录')
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
          Text('选择章节后生成竖向卷轴')
            .fontSize(11)
            .fontColor(this.secondaryText())
            .maxLines(1)
            .margin({ top: 3 })
            .width('100%')
        }
        .layoutWeight(1)
        .margin({ left: 10 })
        Button('书架')
          .height(34)
          .fontSize(12)
          .onClick(() => this.addCurrentToShelf())
        Button('重载')
          .height(34)
          .fontSize(12)
          .margin({ left: 6 })
          .onClick(() => this.loadDetail(this.currentUrl, this.currentTitle, this.findRule(this.currentSourceId)))
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 8 })

      Column() { this.StatusCard() }.padding({ left: 14, right: 14 })

      Scroll() {
        Column() {
          if (this.chapters.length === 0) {
            Text('没有章节。可能该结果本身就是单话漫画，或目录规则不匹配。')
              .fontSize(14)
              .fontColor(this.secondaryText())
              .width('100%')
              .padding(12)
              .backgroundColor(this.cardBg())
              .borderRadius(10)
          } else {
            ForEach(this.chapters, (chapter: ChapterItem) => {
              Row() {
                Text(chapter.index + '')
                  .fontSize(13)
                  .fontColor('#FFFFFF')
                  .textAlign(TextAlign.Center)
                  .width(32)
                  .height(32)
                  .backgroundColor('#34C759')
                  .borderRadius(16)
                Text(chapter.title)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
                  .margin({ left: 10 })
              }
              .width('100%')
              .padding(12)
              .backgroundColor(this.cardBg())
              .borderRadius(10)
              .margin({ bottom: 8 })
              .onClick(() => this.loadChapter(chapter, this.findRule(chapter.sourceId)))
            }, (chapter: ChapterItem) => chapter.url)
          }
        }
        .width('100%')
        .padding({ left: 14, right: 14, bottom: 14 })
      }
      .layoutWeight(1)
    }
    .layoutWeight(1)
    .backgroundColor(this.appBg())
  }

  @Builder
  private ReaderFloatingButton(action: string) {
    Column() {
      if (action === 'back') {
        this.UiIcon('back', true, 22)
      } else if (action === 'add-shelf') {
        this.UiIcon('add-shelf', true, 22)
      } else if (action === 'refresh') {
        this.UiIcon('refresh', true, 22)
      } else {
        this.UiIcon('more', true, 22)
      }
    }
    .width(44)
    .height(44)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#88000000')
    .borderRadius(22)
  }

  @Builder
  private ReaderPage() {
    Stack() {
      if (this.mode === 'rendered_reader') {
        Web({ src: this.renderedReaderUrl, controller: this.renderWebController })
          .javaScriptAccess(true)
          .domStorageAccess(true)
          .imageAccess(true)
          .onlineImageAccess(true)
          .onPageEnd(() => {
            this.renderWebController.runJavaScript(this.readerCleanupScript());
          })
          .width('100%')
          .height('100%')
      } else if (this.images.length === 0) {
        Column() {
          this.StatusCard()
          Text(this.isLoading ? (this.appLanguage === 'en' ? 'Building scroll reader...' : '正在生成卷轴...') : (this.appLanguage === 'en' ? 'No image to show.' : '没有图片可显示。'))
            .fontSize(14)
            .fontColor(this.secondaryText())
            .width('100%')
            .padding(14)
            .backgroundColor(this.cardBg())
            .borderRadius(16)
        }
        .width('100%')
        .height('100%')
        .padding(16)
        .backgroundColor(this.appBg())
      } else {
        Scroll() {
          Column() {
            ForEach(this.images, (item: ReaderImageItem) => {
              Column() {
                if (this.showImageIndex) {
                  Text('#' + item.index + (item.status === 'error' ? ' 加载失败，点图可重试' : ''))
                    .fontSize(11)
                    .fontColor(item.status === 'error' ? '#34C759' : '#FFFFFF')
                    .width('100%')
                    .padding({ left: 8, top: 5, bottom: 5 })
                }
                Image(item.url)
                  .width('100%')
                  .objectFit(this.readerFitContain ? ImageFit.Contain : ImageFit.Cover)
                  .backgroundColor('#000000')
                  .borderRadius(8)
                  .onComplete(() => { this.markImage(item.index, 'ok'); })
                  .onError(() => { this.markImage(item.index, 'error'); })
                  .onClick(() => { this.markImage(item.index, 'waiting'); })
              }
              .width('100%')
              .margin({ bottom: 8 })
            }, (item: ReaderImageItem) => item.url + item.index)
          }
          .width('100%')
          .padding({ left: 4, right: 4, top: 72, bottom: 76 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#050607')
      }

      if (this.floatingReaderControls) {
        Row() {
          Column() {
            Text(this.currentChapterTitle.length > 0 ? this.currentChapterTitle : (this.mode === 'rendered_reader' ? this.renderedReaderTitle : '卷轴阅读'))
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
            Text(this.mode === 'rendered_reader' ? 'Rendered scroll' : (this.images.length + ' pages'))
              .fontSize(11)
              .fontColor('#DDFFFFFF')
              .margin({ top: 2 })
          }
          .layoutWeight(1)
          .padding({ left: 14, right: 14 })
          .height(48)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#66000000')
          .borderRadius(24)
          this.ReaderFloatingButton('more')
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 10 })
        .align(Alignment.Top)
      }

      if (this.floatingReaderControls) {
        Row() {
          Column() { this.ReaderFloatingButton('back') }
            .onClick(() => { this.mode = this.chapters.length > 0 ? 'chapters' : (this.results.length > 0 ? 'results' : 'home'); })
          Blank().layoutWeight(1)
          Column() { this.ReaderFloatingButton('add-shelf') }
            .onClick(() => this.addCurrentToShelf())
          Column() { this.ReaderFloatingButton('refresh') }
            .margin({ left: 10 })
            .onClick(() => this.loadChapterByUrl(this.currentUrl, this.currentChapterTitle, this.findRule(this.currentSourceId)))
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 14 })
        .align(Alignment.Bottom)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#050607')
  }

  @Builder
  private HistoryList(showAll: boolean) {
    if (this.history.length === 0) {
      Text('暂无历史。成功打开卷轴阅读后会显示在这里。')
        .fontSize(13)
        .fontColor(this.secondaryText())
        .width('100%')
        .padding(12)
        .backgroundColor(this.cardBg())
        .borderRadius(10)
    } else {
      ForEach(showAll ? this.history : this.history.slice(0, 5), (item: ReadingHistoryItem) => {
        Column() {
          Text(item.title)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
          Text(item.chapterTitle + ' · ' + item.sourceName + ' · ' + item.timeText)
            .fontSize(12)
            .fontColor(this.secondaryText())
            .margin({ top: 4 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
        .width('100%')
        .padding(12)
        .backgroundColor(this.cardBg())
        .borderRadius(10)
        .margin({ bottom: 8 })
        .onClick(() => this.loadChapterByUrl(item.url, item.chapterTitle, ruleForPublicUrl(item.url, this.genericRule())))
      }, (item: ReadingHistoryItem) => item.url + item.timeText)
    }
  }

  @Builder
  private HistoryPage() {
    Scroll() {
      Column() {
        Text('历史')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.primaryText())
          .width('100%')
          .margin({ top: 12, bottom: 6 })
        Text('观看历史、收藏记录和下载任务统一放在这里。')
          .fontSize(13)
          .fontColor(this.secondaryText())
          .lineHeight(20)
          .width('100%')
          .margin({ bottom: 12 })
        Row() {
          Text('历史 ' + this.history.length + ' 条 · 收藏 ' + this.bookshelf.length + ' 本')
            .fontSize(13)
            .fontColor(this.secondaryText())
            .layoutWeight(1)
          Button('清历史')
            .height(32)
            .fontSize(12)
            .onClick(() => { this.history = []; this.statusText = '阅读历史已清空。'; })
          Button('清收藏')
            .height(32)
            .fontSize(12)
            .margin({ left: 6 })
            .onClick(() => { this.bookshelf = []; this.statusText = '收藏记录已清空。'; })
        }
        .width('100%')
        .padding(12)
        .backgroundColor(this.cardBg())
        .borderRadius(16)
        .margin({ bottom: 12 })
        this.SettingSectionTitle('历史记录', '最近打开的章节和卷轴阅读记录。')
        this.HistoryList(true)
        this.SettingSectionTitle('收藏记录', '从结果、章节或阅读页加入书架的内容。')
        if (this.bookshelf.length === 0) {
          Text('暂无收藏。阅读页或结果卡片加入书架后会显示在这里。')
            .fontSize(14)
            .fontColor(this.secondaryText())
            .width('100%')
            .padding(14)
            .backgroundColor(this.cardBg())
            .borderRadius(16)
            .margin({ bottom: 12 })
        } else {
          ForEach(this.bookshelf, (item: BookshelfItem) => {
            Column() {
              Text(item.title)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.primaryText())
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
              Text((item.lastChapterTitle.length > 0 ? item.lastChapterTitle : '未阅读') + ' · ' + item.sourceName)
                .fontSize(12)
                .fontColor(this.secondaryText())
                .margin({ top: 5 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
              Row() {
                Button('打开')
                  .height(30)
                  .fontSize(12)
                  .layoutWeight(1)
                  .onClick(() => this.openShelf(item))
                Button('移除')
                  .height(30)
                  .fontSize(12)
                  .layoutWeight(1)
                  .margin({ left: 8 })
                  .onClick(() => this.removeShelf(item.url))
              }
              .width('100%')
              .margin({ top: 10 })
            }
            .width('100%')
            .padding(14)
            .backgroundColor(this.cardBg())
            .borderRadius(16)
            .margin({ bottom: 8 })
            .onClick(() => this.openShelf(item))
          }, (item: BookshelfItem) => item.url)
        }
        this.SettingSectionTitle('下载', '下载能力暂时保留，后续接入离线章节。')
        Text('暂无下载任务。后续下载任务、缓存章节和离线阅读入口会集中在这里。')
          .fontSize(14)
          .fontColor(this.secondaryText())
          .width('100%')
          .padding(14)
          .backgroundColor(this.cardBg())
          .borderRadius(16)
          .margin({ bottom: 18 })
      }
      .width('100%')
      .padding(14)
    }
    .layoutWeight(1)
    .backgroundColor(this.appBg())
  }

  @Builder
  private ShelfPage() {
    Scroll() {
      Column() {
        Text('热门题材')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.primaryText())
          .width('100%')
          .margin({ top: 12, bottom: 6 })
        Text('这里将自动更新热门题材推荐，点击题材后进入搜索。收藏、历史和下载已统一放到历史页。')
          .fontSize(13)
          .fontColor(this.secondaryText())
          .lineHeight(20)
          .width('100%')
          .margin({ bottom: 12 })
        Column() {
          Text('自动推荐')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.primaryText())
            .width('100%')
          Text('后续会从规则仓库热门题材索引自动更新；当前先提供常用题材入口。')
            .fontSize(13)
            .fontColor(this.secondaryText())
            .lineHeight(20)
            .width('100%')
            .margin({ top: 6 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(this.cardBg())
        .borderRadius(18)
        .margin({ bottom: 12 })
        Grid() {
          ForEach(['玄幻', '修真', '恋爱', '校园', '宫斗', '都市', '热血', '冒险', '悬疑', '科幻', '搞笑', '治愈'], (topic: string) => {
            GridItem() {
              Column() {
                Text(topic)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.accent())
                Text('点击搜索')
                  .fontSize(11)
                  .fontColor(this.secondaryText())
                  .margin({ top: 5 })
              }
              .width('100%')
              .height(82)
              .justifyContent(FlexAlign.Center)
              .backgroundColor(this.cardBg())
              .borderRadius(18)
              .onClick(() => { this.activeTab = 'search'; this.queryText = topic; this.startSearch(); })
            }
          }, (topic: string) => topic)
        }
        .columnsTemplate('1fr 1fr 1fr')
        .columnsGap(10)
        .rowsGap(10)
        .width('100%')
        Button('刷新热门题材')
          .height(42)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor(this.accent())
          .borderRadius(21)
          .margin({ top: 16, bottom: 18 })
          .onClick(() => { this.statusText = '热门题材后续将从规则仓库自动更新。'; })
      }
      .width('100%')
      .padding(14)
    }
    .layoutWeight(1)
    .backgroundColor(this.appBg())
  }

  @Builder
  private SettingCard(title: string, desc: string, value: string) {
    Column() {
      Row() {
        Column() {
          Text(title).fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.primaryText()).width('100%')
          Text(desc).fontSize(12).fontColor(this.secondaryText()).lineHeight(18).margin({ top: 4 }).width('100%')
        }.layoutWeight(1)
        Text(value)
          .fontSize(12)
          .fontColor((value === '关' || value === '停用') ? this.secondaryText() : '#FFFFFF')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor((value === '关' || value === '停用') ? (this.isDarkTheme() ? '#2A333D' : '#EEF1F4') : this.accent())
          .borderRadius(14)
      }.width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.cardBg())
    .borderRadius(16)
    .margin({ bottom: 8 })
  }

  @Builder
  private SettingSectionTitle(title: string, desc: string) {
    Column() {
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.primaryText())
        .width('100%')
      if (desc.length > 0) {
        Text(desc)
          .fontSize(12)
          .fontColor(this.secondaryText())
          .lineHeight(18)
          .width('100%')
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .padding({ left: 2, right: 2, top: 12, bottom: 8 })
  }

  @Builder
  private SettingsPage() {
    Scroll() {
      Column() {
        Text('设置')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ top: 12, bottom: 6 })
        Text('这里的选项都会直接影响搜索、列表、阅读器、书架/历史和源规则。')
          .fontSize(13)
          .fontColor(this.secondaryText())
          .lineHeight(20)
          .width('100%')
          .margin({ bottom: 12 })
        this.StatusCard()
        this.AuditCard()

        this.SettingSectionTitle('基础设置', '主题、语言与阅读页悬浮控制。')
        Column() { this.SettingCard(this.t('theme'), '明亮 / 暗黑双主题，阅读页会自动跟随。', this.themeLabel()) }.onClick(() => this.toggleTheme())
        Column() { this.SettingCard(this.t('language'), '当前支持中文 / English，后续可扩展更多语言。', this.languageLabel()) }.onClick(() => this.toggleLanguage())
        Column() { this.SettingCard(this.t('fullReader'), '阅读页默认全屏，顶部和底部使用悬浮独立按钮。', this.fullscreenReader ? '开' : '关') }.onClick(() => { this.fullscreenReader = !this.fullscreenReader; })
        Column() { this.SettingCard(this.t('floatingControls'), '隐藏传统标题栏，使用胶囊悬浮控制。', this.floatingReaderControls ? '开' : '关') }.onClick(() => { this.floatingReaderControls = !this.floatingReaderControls; })

        this.SettingSectionTitle('搜索设置', '控制默认搜索方式、语言倾向和搜索引擎。')
        Column() { this.SettingCard('搜索模式', '混合=搜索引擎+公开API+规则源；仅搜索引擎/仅公开API用于排错。', this.searchMode) }
          .onClick(() => this.nextSearchMode())
        Column() { this.SettingCard('当前搜索引擎', this.selectedEngine().description, this.selectedEngine().name) }
          .onClick(() => this.cycleEngine())
        Column() { this.SettingCard('全引擎搜索', '开启后同时调用已启用且已配置的主流搜索引擎。', this.searchAllEngines ? '开' : '关') }
          .onClick(() => { this.searchAllEngines = !this.searchAllEngines; })
        Column() { this.SettingCard('搜索语言倾向', '影响追加关键词：自动/中文/英文/日文/韩文。', this.languageMode) }
          .onClick(() => this.nextLanguageMode())
        TextInput({ placeholder: '额外搜索词，例如 comic manga 漫画 在线 阅读', text: this.extraSearchTerms })
          .height(42)
          .fontSize(13)
          .backgroundColor(this.cardBg())
          .borderRadius(10)
          .padding({ left: 10, right: 10 })
          .margin({ bottom: 8 })
          .onChange((value: string) => { this.extraSearchTerms = value; })
        TextInput({ placeholder: '站点提示：例如 site:example.com 或 public domain comic', text: this.siteHint })
          .height(42)
          .fontSize(13)
          .backgroundColor(this.cardBg())
          .borderRadius(10)
          .padding({ left: 10, right: 10 })
          .margin({ bottom: 8 })
          .onChange((value: string) => { this.siteHint = value; })
        TextInput({ placeholder: 'Brave Search API Key（可选）', text: this.braveApiKey })
          .height(42).fontSize(13).backgroundColor(this.cardBg()).borderRadius(10).padding({ left: 10, right: 10 }).margin({ bottom: 8 })
          .onChange((value: string) => { this.braveApiKey = value; })
        TextInput({ placeholder: 'Google Programmable Search API Key（可选）', text: this.googleApiKey })
          .height(42).fontSize(13).backgroundColor(this.cardBg()).borderRadius(10).padding({ left: 10, right: 10 }).margin({ bottom: 8 })
          .onChange((value: string) => { this.googleApiKey = value; })
        TextInput({ placeholder: 'Google CX / Search Engine ID（可选）', text: this.googleCx })
          .height(42).fontSize(13).backgroundColor(this.cardBg()).borderRadius(10).padding({ left: 10, right: 10 }).margin({ bottom: 14 })
          .onChange((value: string) => { this.googleCx = value; })

        this.SettingSectionTitle('公开源开关', '选择参与搜索的公开 API、馆藏和 HTML 规则源。')
        Column() { this.SettingCard('搜索引擎总开关', '关闭后只用公开API/规则源。', this.enableSearchEngines ? '开' : '关') }.onClick(() => { this.enableSearchEngines = !this.enableSearchEngines; })
        Column() { this.SettingCard('Internet Archive', '公开馆藏，IIIF/metadata卷轴。', this.enableInternetArchive ? '开' : '关') }.onClick(() => { this.enableInternetArchive = !this.enableInternetArchive; })
        Column() { this.SettingCard('Open Library', '公开书目，带IA馆藏时转卷轴。', this.enableOpenLibrary ? '开' : '关') }.onClick(() => { this.enableOpenLibrary = !this.enableOpenLibrary; })
        Column() { this.SettingCard('Library of Congress', '公开影像/图书结果。', this.enableLibraryOfCongress ? '开' : '关') }.onClick(() => { this.enableLibraryOfCongress = !this.enableLibraryOfCongress; })
        Column() { this.SettingCard('Wikimedia Commons', '公开图片资源。', this.enableWikimedia ? '开' : '关') }.onClick(() => { this.enableWikimedia = !this.enableWikimedia; })
        Column() { this.SettingCard('Pepper&Carrot', '公开网页漫画演示目录。', this.enablePepper ? '开' : '关') }.onClick(() => { this.enablePepper = !this.enablePepper; })
        Column() { this.SettingCard('HTML规则源', '开启后使用下方自定义公开源规则。', this.enableHtmlRules ? '开' : '关') }.onClick(() => { this.enableHtmlRules = !this.enableHtmlRules; })
        Column() { this.SettingCard('来源过滤模式', '全部公开可访问=只要搜索引擎/公开页可访问就显示；官方/公共馆藏=只显示官方试读与公共馆藏；搜索发现全部=最大化显示搜索发现结果。', this.sourceFilterMode) }.onClick(() => this.nextSourceFilterMode())
        Column() { this.SettingCard('未核验公开源', '开启后包含开心漫、SoulLandManga、Mgeko、漫画柜、斗罗大陆网等搜索发现的公开可访问页。', this.includeUnverifiedPublicSources ? '开' : '关') }.onClick(() => { this.includeUnverifiedPublicSources = !this.includeUnverifiedPublicSources; })
        Column() { this.SettingCard('官方公开/试读源', '开启后包含腾讯动漫、WEBTOON、起点漫画等官方公开目录或试读页面。', this.includeOfficialPreviewSources ? '开' : '关') }.onClick(() => { this.includeOfficialPreviewSources = !this.includeOfficialPreviewSources; })
        Column() { this.SettingCard('搜索引擎发现页', '开启后把搜索引擎发现的漫画页面纳入结果并按域名自动套用解析规则。', this.includeSearchEngineDiscovered ? '开' : '关') }.onClick(() => { this.includeSearchEngineDiscovered = !this.includeSearchEngineDiscovered; })
        Column() { this.SettingCard('排除登录/付费结果', '开启后自动过滤起点VIP、INKR付费、UTOON Premium、已下架/商城/百科/视频/社区等非完全公开阅读结果。', this.excludeLoginPayResults ? '开' : '关') }.onClick(() => { this.excludeLoginPayResults = !this.excludeLoginPayResults; })

        this.SettingSectionTitle('显示与阅读', '控制结果卡片、卷轴阅读器和历史保留。')
        Column() { this.SettingCard('列表样式', '搜索结果列表显示模式。', this.coverOnlyMode ? '纯封面' : '封面+名称') }.onClick(() => { this.coverOnlyMode = !this.coverOnlyMode; })
        Column() { this.SettingCard('列表列数', '结果卡片列数。', this.resultColumns === 2 ? '2列' : '3列') }.onClick(() => { this.resultColumns = this.resultColumns === 2 ? 3 : 2; })
        Column() { this.SettingCard('按名称归类', '关闭后按每个URL单独显示。', this.groupByName ? '开' : '关') }.onClick(() => { this.groupByName = !this.groupByName; })
        Column() { this.SettingCard('自动补封面', '结果没封面时访问详情页提取第一张图。', this.autoCoverEnabled ? '开' : '关') }.onClick(() => { this.autoCoverEnabled = !this.autoCoverEnabled; })
        Column() { this.SettingCard('阅读器背景', '深色适合漫画阅读，浅色适合图书影像。', this.readerDarkMode ? '深色' : '浅色') }.onClick(() => { this.readerDarkMode = !this.readerDarkMode; })
        Column() { this.SettingCard('图片适配', 'Contain完整显示，Cover填满宽度。', this.readerFitContain ? 'Contain' : 'Cover') }.onClick(() => { this.readerFitContain = !this.readerFitContain; })
        Column() { this.SettingCard('显示页码', '控制卷轴中每张图上方编号。', this.showImageIndex ? '开' : '关') }.onClick(() => { this.showImageIndex = !this.showImageIndex; })
        Column() { this.SettingCard('图片去重', '章节多页追踪时去掉重复图片URL。', this.dedupeImages ? '开' : '关') }.onClick(() => { this.dedupeImages = !this.dedupeImages; })
        Column() { this.SettingCard('渲染卷轴兜底', '开心漫、漫画160、MangaFire等公开站点若静态HTML拿不到图片，使用无地址栏Web渲染并隐藏导航，仍以卷轴阅读呈现。', this.enableRenderedWebFallback ? '开' : '关') }.onClick(() => { this.enableRenderedWebFallback = !this.enableRenderedWebFallback; })
        Column() { this.SettingCard('封面补全数量', '控制搜索后自动补封面数量，越大越慢。', this.maxCoverEnrich + '个') }.onClick(() => { this.maxCoverEnrich = this.maxCoverEnrich === 12 ? 30 : (this.maxCoverEnrich === 30 ? 60 : 12); })
        Column() { this.SettingCard('最大结果数', '控制每次搜索合并后的最大条目数。', this.maxSearchResults + '个') }.onClick(() => { this.maxSearchResults = this.maxSearchResults === 40 ? 80 : (this.maxSearchResults === 80 ? 150 : 40); })
        Column() { this.SettingCard('章节追踪页数', '控制下一页追踪上限，避免死循环。', this.maxReaderPagesSetting + '页') }.onClick(() => { this.maxReaderPagesSetting = this.maxReaderPagesSetting === 4 ? 8 : (this.maxReaderPagesSetting === 8 ? 16 : 4); })
        Column() { this.SettingCard('历史保留数', '控制阅读历史最大数量。', this.keepHistoryCount + '条') }.onClick(() => { this.keepHistoryCount = this.keepHistoryCount === 20 ? 40 : (this.keepHistoryCount === 40 ? 80 : 20); this.history = this.history.slice(0, this.keepHistoryCount); })

        this.SettingSectionTitle('搜索引擎清单', '点击卡片切换当前搜索引擎，按钮用于启用或停用。')
        ForEach(this.searchEngines, (engine: SearchEngineConfig, index: number) => {
          Column() {
            Row() {
              Text(index === this.selectedEngineIndex ? '当前' : (engine.enabled ? '启用' : '停用'))
                .fontSize(12).fontColor('#FFFFFF').textAlign(TextAlign.Center).width(42).height(24)
                .backgroundColor(index === this.selectedEngineIndex ? '#34C759' : (engine.enabled ? '#43A047' : '#777777')).borderRadius(12)
              Column() {
                Text(engine.name).fontSize(15).fontWeight(FontWeight.Medium).width('100%')
                Text(engine.description).fontSize(12).fontColor(this.secondaryText()).lineHeight(17).margin({ top: 4 }).width('100%')
              }.layoutWeight(1).margin({ left: 10 })
              Button(engine.enabled ? '停用' : '启用')
                .height(30)
                .fontSize(11)
                .margin({ left: 8 })
                .onClick(() => this.toggleEngineEnabled(index))
            }.width('100%')
          }
          .width('100%')
          .padding(12)
          .backgroundColor(this.cardBg())
          .borderRadius(10)
          .margin({ bottom: 8 })
          .onClick(() => { this.selectedEngineIndex = index; this.statusText = '当前搜索引擎：' + engine.name; })
        }, (engine: SearchEngineConfig) => engine.id)


        this.SettingSectionTitle('远程规则', '从可信 GitHub index.json 拉取公开源规则，失败时保留内置规则。')
        TextInput({ placeholder: '远程规则 index.json Raw 地址', text: this.remoteRuleUrl })
          .height(44)
          .fontSize(12)
          .width('100%')
          .backgroundColor(this.cardBg())
          .borderRadius(10)
          .padding({ left: 10, right: 10 })
          .onChange((value: string) => { this.remoteRuleUrl = value; })
        Row() {
          Button('恢复默认地址')
            .height(40)
            .layoutWeight(1)
            .fontSize(14)
            .onClick(() => { this.remoteRuleUrl = DEFAULT_REMOTE_RULE_URL; this.remoteRuleStatus = '已恢复默认 GitHub 规则仓库地址'; })
          Button('从GitHub更新规则')
            .height(40)
            .layoutWeight(1)
            .fontSize(14)
            .margin({ left: 10 })
            .onClick(() => this.updateRemoteRules())
        }
        .width('100%')
        .margin({ top: 8 })
        Text(this.remoteRuleStatus + ' · 当前远程规则 ' + this.remoteRuleCount + ' 条')
          .fontSize(12)
          .fontColor(this.secondaryText())
          .lineHeight(18)
          .width('100%')
          .margin({ top: 6, bottom: 8 })

        this.SettingSectionTitle('高级规则', '展示当前公开 HTML 源，也可以粘贴自定义 JSON 规则。')
        ForEach(this.rules, (rule: ComicSourceRule, index: number) => {
          Column() {
            Row() {
              Text(rule.searchUrl.length > 0 ? '搜' : 'URL')
                .fontSize(12).fontColor('#FFFFFF').textAlign(TextAlign.Center).width(38).height(24)
                .backgroundColor(rule.searchUrl.length > 0 ? '#34C759' : '#777777').borderRadius(12)
              Column() {
                Text(rule.name).fontSize(16).fontWeight(FontWeight.Medium).width('100%')
                Text(rule.description).fontSize(12).fontColor(this.secondaryText()).lineHeight(17).margin({ top: 4 }).width('100%')
              }.layoutWeight(1).margin({ left: 10 })
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor(this.cardBg())
          .borderRadius(10)
          .margin({ bottom: 8 })
          .onClick(() => { this.selectedSourceIndex = index; this.statusText = '已选择源：' + rule.name; })
        }, (rule: ComicSourceRule) => rule.id)

        TextArea({ placeholder: '粘贴源规则JSON', text: this.customRuleText })
          .height(240)
          .fontSize(12)
          .width('100%')
          .backgroundColor(this.cardBg())
          .borderRadius(10)
          .onChange((value: string) => { this.customRuleText = value; })
        Row() {
          Button('恢复模板')
            .height(40)
            .layoutWeight(1)
            .fontSize(14)
            .onClick(() => { this.customRuleText = RULE_TEMPLATE; })
          Button('添加规则')
            .height(40)
            .layoutWeight(1)
            .fontSize(14)
            .margin({ left: 10 })
            .onClick(() => this.addCustomRule())
        }
        .width('100%')
        .margin({ top: 10, bottom: 20 })
      }
      .width('100%')
      .padding(14)
    }
    .layoutWeight(1)
    .backgroundColor(this.appBg())
  }

  @Builder
  private AboutInfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor(this.secondaryText())
        .layoutWeight(1)
      Text(value)
        .fontSize(13)
        .fontColor(this.primaryText())
        .textAlign(TextAlign.End)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(2)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  private AboutPage() {
    Scroll() {
      Column() {
        Text(this.t('about'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.primaryText())
          .width('100%')
          .margin({ top: 12, bottom: 6 })
        Text(this.appLanguage === 'en' ? 'Public comic search and scroll reading for HarmonyOS / OpenHarmony.' : '漫画浏览器 HarmonyOS / OpenHarmony 公开漫画搜索与卷轴阅读项目。')
          .fontSize(13)
          .fontColor(this.secondaryText())
          .lineHeight(20)
          .width('100%')
          .margin({ bottom: 12 })

        Column() {
          Text(this.appLanguage === 'en' ? 'Build Info' : '构建信息')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.primaryText())
            .width('100%')
            .margin({ bottom: 8 })
          this.AboutInfoRow(this.appLanguage === 'en' ? 'Version' : '版本', APP_VERSION)
          this.AboutInfoRow(this.appLanguage === 'en' ? 'Version Rule' : '版本结构', this.appLanguage === 'en' ? 'major.full.incremental' : '主版本.全量构建号.增量构建号')
          this.AboutInfoRow('versionCode', APP_VERSION_CODE + '')
          this.AboutInfoRow(this.appLanguage === 'en' ? 'Build Type' : '构建类型', APP_BUILD_TYPE)
          this.AboutInfoRow(this.appLanguage === 'en' ? 'Build Target' : '构建目标', APP_BUILD_TARGET)
          this.AboutInfoRow(this.appLanguage === 'en' ? 'Build Time' : '构建时间', APP_BUILD_TIME)
        }
        .width('100%')
        .padding(14)
        .backgroundColor(this.cardBg())
        .borderRadius(18)
        .margin({ bottom: 12 })

        Column() {
          Text(this.appLanguage === 'en' ? 'UI Style' : '界面风格')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.primaryText())
            .width('100%')
            .margin({ bottom: 8 })
          this.AboutInfoRow(this.t('theme'), this.themeLabel())
          this.AboutInfoRow(this.t('language'), this.languageLabel())
          this.AboutInfoRow(this.t('fullReader'), this.fullscreenReader ? 'ON' : 'OFF')
        }
        .width('100%')
        .padding(14)
        .backgroundColor(this.cardBg())
        .borderRadius(18)
        .margin({ bottom: 20 })
      }
      .width('100%')
      .padding(16)
    }
    .layoutWeight(1)
    .backgroundColor(this.appBg())
  }

  @Builder
  private UiIcon(name: string, selected: boolean, size: number) {
    if (name === 'search') {
      Image($r('app.media.ic_search')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())
    } else if (name === 'shelf') {
      Image($r('app.media.ic_shelf')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())
    } else if (name === 'settings') {
      Image($r('app.media.ic_settings')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())
    } else if (name === 'history') {
      Image($r('app.media.ic_history')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())
    } else if (name === 'about') {
      Image($r('app.media.ic_about')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())
    } else if (name === 'back') {
      Image($r('app.media.ic_back')).width(size).height(size).fillColor('#FFFFFF')
    } else if (name === 'add-shelf') {
      Image($r('app.media.ic_add_shelf')).width(size).height(size).fillColor('#FFFFFF')
    } else if (name === 'refresh') {
      Image($r('app.media.ic_refresh')).width(size).height(size).fillColor('#FFFFFF')
    } else if (name === 'more') {
      Image($r('app.media.ic_more')).width(size).height(size).fillColor('#FFFFFF')
    }
  }

  @Builder
  private TabPill(tab: string, label: string) {
    Column() {
      this.UiIcon(tab, this.activeTab === tab, 20)
      Text(label)
        .fontSize(10)
        .fontColor(this.activeTab === tab ? this.accent() : this.secondaryText())
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .height(56)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.activeTab === tab ? this.selectedSoftBg() : '#00000000')
    .borderRadius(28)
    .onClick(() => {
      this.activeTab = tab;
      if (tab === 'search' && (this.mode === 'chapters' || this.mode === 'reader' || this.mode === 'rendered_reader')) {
        this.mode = this.results.length > 0 ? 'results' : 'home';
      }
    })
  }

  @Builder
  private BottomTabs() {
    Row() {
      this.TabPill('search', '搜索')
      this.TabPill('shelf', '书架')
      this.TabPill('history', '历史')
      this.TabPill('settings', '设置')
    }
    .width('92%')
    .height(68)
    .padding(6)
    .backgroundColor(this.glassBg())
    .borderRadius(34)
    .margin({ left: 16, right: 16, bottom: 10 })
  }

  build() {
    Column() {
      if (this.activeTab === 'search' && this.mode === 'results') {
        this.SearchHeader()
      }

      if (this.activeTab === 'search') {
        if (this.mode === 'home') {
          this.SearchHome()
        } else if (this.mode === 'results') {
          this.ResultsPage()
        } else if (this.mode === 'chapters') {
          this.ChaptersPage()
        } else {
          this.ReaderPage()
        }
      } else if (this.activeTab === 'shelf') {
        this.ShelfPage()
      } else if (this.activeTab === 'history') {
        this.HistoryPage()
      } else {
        this.SettingsPage()
      }

      if (this.mode !== 'reader' && this.mode !== 'rendered_reader' && this.mode !== 'chapters') {
        this.BottomTabs()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.appBg())
  }
}
