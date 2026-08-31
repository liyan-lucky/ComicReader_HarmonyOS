import { ComicSourceRule, SearchResultItem, ChapterItem, ReaderImageItem, ReadingHistoryItem, BookshelfItem, SearchEngineConfig, RemoteCatalog, CatalogCategory, CatalogItem, CatalogSource } from '../model/ComicModels';
import { DEFAULT_SOURCES, RULE_TEMPLATE, ruleForPublicUrl } from '../common/SourceRules';
import { HttpClient } from '../common/HttpClient';
import { parseSearchResults, parseChapters, parseChaptersFallback, parseImages, parseNextPageUrl } from '../common/HtmlParser';
import { looksLikeUrl, normalizeUserUrl } from '../common/UrlUtil';
import { DEFAULT_SEARCH_ENGINES, buildEngineQuery, buildSearchEngineUrl, parseSearchEngineResults, isEngineConfigured, engineHeaders, searchEngineUserAgent } from '../common/SearchEngines';
import { RemoteRuleService, DEFAULT_REMOTE_RULE_URL } from '../common/RemoteRuleService';
import { CatalogService } from '../common/CatalogService';
import { APP_VERSION, APP_BUILD_TIME } from '../common/BuildInfo';
import {
  buildInternetArchiveSearchUrl, parseInternetArchiveSearch,
  buildWikimediaSearchUrl, parseWikimediaSearch,
  buildOpenLibrarySearchUrl, parseOpenLibrarySearch,
  buildLibraryOfCongressSearchUrl, parseLibraryOfCongressSearch,
  searchPepperCatalog, isPepperPseudoUrl, parsePepperImages,
  isArchivePseudoUrl, archiveIdentifierFromUrl,
  buildInternetArchiveManifestUrl, parseInternetArchiveManifestImages,
  buildInternetArchiveMetadataUrl, parseInternetArchiveMetadataImages,
  isWikimediaPseudoUrl, wikimediaImageFromUrl,
  isLocPseudoUrl, locImageFromUrl
} from '../common/ApiSources';
import drawing from '@ohos.graphics.drawing';
import common from '@ohos.app.ability.common';
import window from '@ohos.window';
import dataPreferences from '@ohos.data.preferences';
import util from '@ohos.util';
import fs from '@ohos.file.fs';

function toArgbColor(color: string): number {
  const normalized = color.trim().startsWith('#') ? color.trim().substring(1) : color.trim();
  if (normalized.length === 8) return parseInt(normalized, 16);
  return 0xFF000000 + parseInt(normalized, 16);
}

function createStrokeIconColorFilter(color: string): drawing.ColorFilter {
  return drawing.ColorFilter.createBlendModeColorFilter(toArgbColor(color), drawing.BlendMode.SRC_IN);
}

@Entry
@Component
struct Index {
  @State private activeTab: string = 'search';
  @State private mode: string = 'home';
  @State private queryText: string = '';
  @State private searchTitle: string = '';
  @State @Watch('onStatusTextChanged') private statusText: string = '';
  @State private statusMessageVisible: boolean = false;
  private statusMessageTimerId: number = -1;
  @State private rules: ComicSourceRule[] = DEFAULT_SOURCES;
  @State private searchEngines: SearchEngineConfig[] = DEFAULT_SEARCH_ENGINES;
  @State private selectedEngineIndex: number = 0;
  @State private results: SearchResultItem[] = [];
  @State private chapters: ChapterItem[] = [];
  @State private images: ReaderImageItem[] = [];
  @State private history: ReadingHistoryItem[] = [];
  @State private bookshelf: BookshelfItem[] = [];
  @State private remoteCatalog: RemoteCatalog | null = null;
  @State private catalogCategories: CatalogCategory[] = [];
  @State private selectedCatalogCategory: string = '';
  @State private catalogItems: CatalogItem[] = [];
  @State private catalogLoading: boolean = false;
  @State private catalogUpdateStatus: string = '';
  @State private catalogCheckingOnline: boolean = false;
  @State private catalogUpdateAvailable: boolean = false;
  @State private catalogReceivedBytes: number = 0;
  @State private catalogTotalBytes: number = 0;
  @State private catalogProgressPercent: number = 0;
  @State private currentTitle: string = '';
  @State private currentUrl: string = '';
  @State private currentDetailUrl: string = '';
  @State private currentChapterTitle: string = '';
  @State private currentCover: string = '';
  @State private currentSourceId: string = '';
  @State private currentSourceName: string = '';
  @State private detailLoading: boolean = false;
  @State private detailReceivedBytes: number = 0;
  @State private detailTotalBytes: number = 0;
  @State @Watch('onLoadingChanged') private isLoading: boolean = false;
  @State private loadingAngle: number = 0;
  private loadingTimerId: number = -1;
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings);

  @State private searchMode: string = 'mixed';
  @State private searchAllEngines: boolean = true;
  @State private languageMode: string = 'chinese';
  // Language-specific terms are appended by buildEngineQuery. Keeping this
  // empty avoids an accidental AND query that requires Chinese pages to also
  // contain every English term (the main cause of one-result genre searches).
  @State private extraSearchTerms: string = '';
  @State private siteHint: string = '';
  @State private braveApiKey: string = '';
  @State private googleApiKey: string = '';
  @State private googleCx: string = '';
  @State private enableSearchEngines: boolean = true;
  @State private enableHtmlRules: boolean = true;
  @State private autoCoverEnabled: boolean = false;
  @State private maxSearchResults: number = 80;
  @State private maxReaderPages: number = 30;
  @State private readerRenderLimit: number = 6;
  @State private readerPaginationLoading: boolean = false;
  @State private readerChangingChapter: boolean = false;
  @State private chapterReversed: boolean = true;
  @State private showImageIndex: boolean = true;
  @State private readerDarkMode: boolean = true;
  @State private fullscreenReader: boolean = true;
  @State private floatingReaderControls: boolean = true;
  @State private iconColorMode: string = 'colorful';
  @State private readerToolsVisible: boolean = false;
  @State private readerChapterPanelVisible: boolean = false;
  @State private appTheme: string = 'light';
  @State private appLanguage: string = 'zh';
  @StorageProp('systemColorMode') private systemColorMode: string = 'light';
  @StorageProp('uiVersion') @Watch('onUiVersionChanged') private uiRefresh: number = 0;
  @State private uiVersion: number = 0;
  @State private remoteRuleUrl: string = DEFAULT_REMOTE_RULE_URL;
  @State private remoteRuleStatus: string = '';
  @State private remoteRuleCount: number = 0;
  @State private updatingCatalog: boolean = false;
  @State private updatingRules: boolean = false;
  @State private updateDialogVisible: boolean = false;
  @State private customRuleText: string = RULE_TEMPLATE;
  @State private settingsDialog: string = '';
  @State private themeDialogVisible: boolean = false;
  @State private languageDialogVisible: boolean = false;
  @State private avoidStatusBarHeight: number = 0;
  @State private bottomSafeInset: number = 28;
  @State private debugKeepScreenOn: boolean = true;
  @State private historyTab: string = 'history';
  @State private historyViewMode: string = 'list';
  @State private historyMenuVisible: boolean = false;

  private preferencesStore: dataPreferences.Preferences | null = null;
  private catalogCachePath: string = '';
  private coverCacheDir: string = '';
  private pendingCatalogVersion: string = '';
  private pendingCatalogUrl: string = '';
  private chapterScroller: Scroller = new Scroller();

  private resetChapterScroll(): void {
    // The chapters builder replaces the result list in the same page. ArkUI
    // may otherwise retain the previous Scroll offset, making an ascending
    // list appear to start halfway through a book.
    setTimeout(() => {
      this.chapterScroller.scrollEdge(Edge.Top);
    }, 0);
  }

  private async initPreferences(): Promise<void> {
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      this.coverCacheDir = context.filesDir + '/bookshelf_covers';
      try { fs.mkdirSync(this.coverCacheDir, true); } catch (e) {}
      this.preferencesStore = await dataPreferences.getPreferences(context, 'comic_reader_store');
      await this.loadPersistedData();
      this.cacheExistingBookshelfCovers();
    } catch (e) {
    }
  }

  private async loadPersistedData(): Promise<void> {
    if (this.preferencesStore === null) return;
    try {
      const historyJson = await this.preferencesStore.get('reading_history', '[]') as string;
      if (typeof historyJson === 'string' && historyJson.length > 2) {
        this.history = JSON.parse(historyJson) as ReadingHistoryItem[];
      }
      const shelfJson = await this.preferencesStore.get('bookshelf', '[]') as string;
      if (typeof shelfJson === 'string' && shelfJson.length > 2) {
        this.bookshelf = JSON.parse(shelfJson) as BookshelfItem[];
      }
      const appTheme = await this.preferencesStore.get('app_theme', 'light') as string;
      if (typeof appTheme === 'string' && appTheme.length > 0) {
        this.appTheme = appTheme;
        this.updateSystemBarColors();
      }
      const appLanguage = await this.preferencesStore.get('app_language', 'zh') as string;
      if (typeof appLanguage === 'string' && appLanguage.length > 0) {
        this.appLanguage = appLanguage;
        this.refreshCatalogLanguageFilter();
      }
      this.debugKeepScreenOn = await this.preferencesStore.get('debug_keep_screen_on', true) as boolean;
      const savedIconMode = await this.preferencesStore.get('icon_color_mode', 'colorful') as string;
      this.iconColorMode = typeof savedIconMode === 'string' && savedIconMode.length > 0 ? savedIconMode : 'colorful';
      this.chapterReversed = await this.preferencesStore.get('chapter_reversed', true) as boolean;
      this.fullscreenReader = await this.preferencesStore.get('fullscreen_reader', true) as boolean;
      this.floatingReaderControls = await this.preferencesStore.get('floating_reader_controls', true) as boolean;
      this.applyKeepScreenOn();
    } catch (e) {
    }
  }

  private async persistData(): Promise<void> {
    if (this.preferencesStore === null) return;
    try {
      await this.preferencesStore.put('reading_history', JSON.stringify(this.history));
      await this.preferencesStore.put('bookshelf', JSON.stringify(this.bookshelf));
      await this.preferencesStore.put('app_theme', this.appTheme);
      await this.preferencesStore.put('app_language', this.appLanguage);
      await this.preferencesStore.put('debug_keep_screen_on', this.debugKeepScreenOn);
      await this.preferencesStore.put('icon_color_mode', this.iconColorMode);
      await this.preferencesStore.put('chapter_reversed', this.chapterReversed);
      await this.preferencesStore.put('fullscreen_reader', this.fullscreenReader);
      await this.preferencesStore.put('floating_reader_controls', this.floatingReaderControls);
      await this.preferencesStore.flush();
    } catch (e) {
    }
  }

  aboutToAppear(): void {
    this.queryText = '';
    this.statusText = this.t('initial_status');
    this.remoteRuleStatus = this.t('remote_not_updated');
    this.avoidStatusBarHeight = 48;
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const mainWindow = context.windowStage.getMainWindowSync();
      const avoidArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const measured = px2vp(avoidArea.topRect.height);
      const bottomMeasured = px2vp(avoidArea.bottomRect.height);
      console.info(`ComicReader avoidStatusBarHeight measured=${measured} raw=${avoidArea.topRect.height} default=48`);
      if (measured > 0) this.avoidStatusBarHeight = measured;
      if (bottomMeasured > 0) this.bottomSafeInset = bottomMeasured;
    } catch (e) {
      console.error(`ComicReader avoidStatusBarHeight failed: ${JSON.stringify(e)}`);
    }
    console.info(`ComicReader avoidStatusBarHeight final=${this.avoidStatusBarHeight}`);
    this.initPreferences();
    this.loadRemoteCatalog();
  }

  private applyCatalog(catalog: RemoteCatalog): void {
    this.remoteCatalog = catalog;
    this.catalogCategories = CatalogService.getCategories(catalog);
    if (this.catalogCategories.length === 0) {
      this.selectedCatalogCategory = '';
      this.catalogItems = [];
      return;
    }
    const selectedExists = this.catalogCategories.some((cat: CatalogCategory) =>
      cat.id === this.selectedCatalogCategory);
    if (!selectedExists) this.selectedCatalogCategory = this.catalogCategories[0].id;
    this.catalogItems = this.filteredCatalogItems(catalog, this.selectedCatalogCategory);
  }

  private isChineseCatalogTitle(title: string): boolean {
    const hasHan = /[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]/.test(title);
    const hasJapaneseKana = /[\u3040-\u30FF]/.test(title);
    const hasKorean = /[\uAC00-\uD7AF]/.test(title);
    return hasHan && !hasJapaneseKana && !hasKorean;
  }

  private isCatalogNavigationTitle(title: string): boolean {
    const value = title.replace(/\s+/g, ' ').trim();
    return /^(?:作品)?分类$|^(?:查看)?全部(?:作品|漫画)?$|^(?:查看)?更多(?:[\u3400-\u9FFF]{0,8}类)?(?:作品|漫画)?$|^(?:进入|返回)(?:分类|首页)$|^(?:完结抽奖|书页|没有了|暂无更多|没有更多了?|已经到底了?|加载更多|上[一]?页|下[一]?页|首[页章]|尾页|末页|浏览历史|阅读历史|历史记录|我的历史|漫.{0,6}的历史)$/.test(value);
  }

  private isCatalogNavigationItem(item: CatalogItem): boolean {
    if (this.isCatalogNavigationTitle(item.title)) return true;
    for (let i = 0; i < item.sources.length; i++) {
      const url = (item.sources[i].detailUrl ?? '').toLowerCase();
      if (/(?:\/|[?&])(history|category|categories|genre|genres|rank|ranking|bookshelf|bookmark|login|register)(?:\/|[?&=]|$)/.test(url)) return true;
    }
    return false;
  }

  private filteredCatalogItems(catalog: RemoteCatalog, categoryId: string): CatalogItem[] {
    const items = CatalogService.getItemsForCategory(catalog, categoryId);
    if (this.appLanguage === 'en') {
      return items.filter((item: CatalogItem) => !this.isCatalogNavigationItem(item) && /[A-Za-z]/.test(item.title) &&
        !/[\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF\u3040-\u30FF\uAC00-\uD7AF]/.test(item.title));
    }
    return items.filter((item: CatalogItem) => !this.isCatalogNavigationItem(item) && this.isChineseCatalogTitle(item.title));
  }

  private refreshCatalogLanguageFilter(): void {
    if (this.remoteCatalog !== null && this.selectedCatalogCategory.length > 0) {
      this.catalogItems = this.filteredCatalogItems(this.remoteCatalog, this.selectedCatalogCategory);
    }
  }

  private loadCachedCatalog(): RemoteCatalog | null {
    try {
      if (this.catalogCachePath.length > 0 && fs.accessSync(this.catalogCachePath)) {
        return JSON.parse(fs.readTextSync(this.catalogCachePath)) as RemoteCatalog;
      }
    } catch (e) {
    }
    return null;
  }

  private saveCatalogCache(catalog: RemoteCatalog): void {
    if (this.catalogCachePath.length === 0) return;
    const tempPath = this.catalogCachePath + '.tmp';
    try {
      const output: fs.File = fs.openSync(tempPath,
        fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      try {
        fs.writeSync(output.fd, JSON.stringify(catalog));
      } finally {
        fs.closeSync(output);
      }
      if (fs.accessSync(this.catalogCachePath)) fs.unlinkSync(this.catalogCachePath);
      fs.renameSync(tempPath, this.catalogCachePath);
    } catch (e) {
      try {
        if (fs.accessSync(tempPath)) fs.unlinkSync(tempPath);
      } catch (ignored) {
      }
    }
  }

  private catalogStage(zh: string, en: string): string {
    return this.isEn() ? en : zh;
  }

  private formatBytes(bytes: number): string {
    if (bytes <= 0) return '--';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
    return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
  }

  private detailProgressText(): string {
    if (this.detailTotalBytes > 0) {
      const percent = Math.min(100, Math.floor(this.detailReceivedBytes * 100 / this.detailTotalBytes));
      return percent + '% · ' + this.formatBytes(this.detailReceivedBytes) + ' / ' + this.formatBytes(this.detailTotalBytes);
    }
    if (this.detailReceivedBytes > 0) return this.formatBytes(this.detailReceivedBytes);
    return this.t('reading_chapters');
  }

  private catalogProgressText(): string {
    if (this.catalogTotalBytes > 0) {
      return this.catalogProgressPercent + '% · ' + this.formatBytes(this.catalogReceivedBytes) +
        ' / ' + this.formatBytes(this.catalogTotalBytes);
    }
    if (this.catalogReceivedBytes > 0) return this.formatBytes(this.catalogReceivedBytes);
    return this.catalogUpdateStatus;
  }

  private async loadRemoteCatalog(): Promise<void> {
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    this.catalogCachePath = context.filesDir + '/catalog.zh-Hans.cache.json';
    this.catalogLoading = true;
    this.catalogUpdateStatus = this.catalogStage('正在读取内置目录…', 'Reading bundled catalog…');
    try {
      const rawBytes = context.resourceManager.getRawFileContentSync('catalog/catalog.zh-Hans.json');
      const decoder = new util.TextDecoder('utf-8');
      const rawStr = decoder.decodeToString(rawBytes);
      const localCatalog = JSON.parse(rawStr) as RemoteCatalog;
      if (localCatalog.categories) this.applyCatalog(localCatalog);
    } catch (e) {
    }
    this.catalogUpdateStatus = this.catalogStage('正在读取目录缓存…', 'Reading catalog cache…');
    const cachedCatalog = this.loadCachedCatalog();
    if (cachedCatalog?.categories && cachedCatalog.version &&
      CatalogService.isNewerVersion(cachedCatalog.version, this.remoteCatalog?.version)) {
      this.applyCatalog(cachedCatalog);
    }
    this.catalogLoading = this.remoteCatalog === null;
    try {
      this.catalogCheckingOnline = true;
      this.catalogUpdateStatus = this.catalogStage('正在检查线上目录版本…', 'Checking online catalog version…');
      const update = await CatalogService.fetchCatalogUpdate();
      if (CatalogService.isNewerVersion(update.version, this.remoteCatalog?.version)) {
        this.pendingCatalogVersion = update.version;
        this.pendingCatalogUrl = update.url;
        this.catalogUpdateAvailable = true;
        this.catalogUpdateStatus = this.catalogStage('发现目录更新 ' + update.version + '，请在数据更新中确认',
          'Catalog update ' + update.version + ' is available. Confirm in Data Update.');
      } else {
        this.catalogUpdateAvailable = false;
        this.catalogUpdateStatus = this.catalogStage('目录已是最新，继续使用缓存',
          'Catalog is current. Using cache.');
      }
      this.catalogLoading = false;
    } catch (e) {
      this.catalogLoading = false;
      this.catalogUpdateStatus = this.catalogStage('线上检查失败，继续使用现有缓存',
        'Online check failed. Using existing cache.');
      console.error('ComicReader catalog startup check failed: ' + JSON.stringify(e));
    } finally {
      this.catalogCheckingOnline = false;
    }
  }

  onBackPress(): boolean {
    if (this.settingsDialog.length > 0) {
      this.settingsDialog = '';
      return true;
    }
    if (this.mode === 'reader') {
      this.applyReaderFullscreen(false);
      this.mode = this.chapters.length > 0 ? 'chapters' : (this.results.length > 0 ? 'results' : 'home');
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

  private isDark(): boolean {
    if (this.appTheme === 'system') return this.systemColorMode === 'dark';
    return this.appTheme === 'dark';
  }

  private updateSystemBarColors(): void {
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const contentColor = this.isDark() ? '#FFFFFF' : '#000000';
      context.windowStage.getMainWindowSync().setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        statusBarContentColor: contentColor,
        navigationBarColor: '#00000000',
        navigationBarContentColor: contentColor
      });
    } catch (e) {
    }
  }

  private applyReaderFullscreen(enabled: boolean): void {
    this.fullscreenReader = enabled;
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const mainWindow = context.windowStage.getMainWindowSync();
      mainWindow.setWindowSystemBarEnable(enabled ? [] : ['status', 'navigation']);
      if (!enabled) this.updateSystemBarColors();
    } catch (e) {
    }
  }

  private applyKeepScreenOn(): void {
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      context.windowStage.getMainWindowSync().setWindowKeepScreenOn(this.debugKeepScreenOn);
    } catch (e) {
    }
  }

  private toggleDebugKeepScreenOn(): void {
    this.debugKeepScreenOn = !this.debugKeepScreenOn;
    this.applyKeepScreenOn();
    this.persistData();
  }

  private isEn(): boolean {
    return this.appLanguage === 'en';
  }

  private onUiVersionChanged(): void {
    this.uiVersion = this.uiRefresh;
    if (this.appTheme === 'system') this.updateSystemBarColors();
  }

  private t(key: string): string {
    this.uiVersion;
    if (this.isEn()) {
      if (key === 'app_title') return 'Comic Reader';
      if (key === 'search') return 'Search';
      if (key === 'search_placeholder') return 'Enter comic name';
      if (key === 'shelf') return 'Shelf';
      if (key === 'history') return 'History';
      if (key === 'settings') return 'Settings';
      if (key === 'no_cover') return 'No Cover';
      if (key === 'author') return 'Author: ';
      if (key === 'latest_chapter') return 'Latest: ';
      if (key === 'update_time') return 'Updated: ';
      if (key === 'comic_tag') return 'Comic';
      if (key === 'search_results') return 'Results';
      if (key === 'search_prefix') return 'Search: ';
      if (key === 'results_hint') return 'Default list view. Categories moved to shelf.';
      if (key === 'searching_sources') return 'Searching public comic sources...';
      if (key === 'no_results') return 'No results found. Try different keywords.';
      if (key === 'chapter_list') return 'Chapters';
      if (key === 'previous_chapter') return 'Previous';
      if (key === 'next_chapter') return 'Next';
      if (key === 'chapter_ascending') return 'Ascending';
      if (key === 'chapter_descending') return 'Descending';
      if (key === 'no_chapters') return 'No chapters. This may be a single chapter, or the rule doesn\'t match.';
      if (key === 'basic_settings') return 'Basic';
      if (key === 'app_settings') return 'App Settings';
      if (key === 'about') return 'About';
      if (key === 'debug_keep_screen_on') return 'Keep screen on for debugging';
      if (key === 'theme') return 'Theme';
      if (key === 'language') return 'Language';
      if (key === 'light') return 'Light';
      if (key === 'dark') return 'Dark';
      if (key === 'follow_system') return 'System';
      if (key === 'reader_fullscreen') return 'Fullscreen Reader';
      if (key === 'floating_controls') return 'Floating Controls';
      if (key === 'icon_color') return 'Icon Color';
      if (key === 'icon_color_colorful') return 'Colorful';
      if (key === 'icon_color_red') return 'Red';
      if (key === 'icon_color_orange') return 'Orange';
      if (key === 'icon_color_yellow') return 'Yellow';
      if (key === 'icon_color_green') return 'Green';
      if (key === 'icon_color_cyan') return 'Cyan';
      if (key === 'icon_color_blue') return 'Blue';
      if (key === 'icon_color_indigo') return 'Indigo';
      if (key === 'icon_color_violet') return 'Violet';
      if (key === 'icon_color_magenta') return 'Magenta';
      if (key === 'search_menu') return 'Search Menu';
      if (key === 'source_switch') return 'Source Toggle';
      if (key === 'display_reading') return 'Display & Reading';
      if (key === 'reading_settings') return 'Reading Settings';
      if (key === 'search_engine') return 'Search Engine';
      if (key === 'rule_settings') return 'Rule Settings';
      if (key === 'advanced_rules') return 'Advanced Rules';
      if (key === 'version') return 'Version';
      if (key === 'build_time') return 'Build Time';
      if (key === 'search_mode') return 'Search Mode';
      if (key === 'current_engine') return 'Current Engine';
      if (key === 'all_engines') return 'All Engines';
      if (key === 'language_pref') return 'Language Pref';
      if (key === 'extra_terms') return 'Extra Terms';
      if (key === 'site_hint') return 'Site hint site:example.com';
      if (key === 'html_rules') return 'HTML Rules';
      if (key === 'remote_rules') return 'Remote Rules';
      if (key === 'auto_cover') return 'Auto Cover';
      if (key === 'show_page_num') return 'Page Numbers';
      if (key === 'reading_bg') return 'Reading BG';
      if (key === 'dark_color') return 'Dark';
      if (key === 'light_color') return 'Light';
      if (key === 'max_results') return 'Max Results';
      if (key === 'chapter_pages') return 'Chapter Pages';
      if (key === 'remote_count') return 'Remote Count';
      if (key === 'remote_url') return 'Remote URL';
      if (key === 'custom_json') return 'Custom JSON Rules';
      if (key === 'enabled') return 'Enabled';
      if (key === 'disabled') return 'Disabled';
      if (key === 'shelf_empty') return 'Shelf is empty. Add comics after reading.';
      if (key === 'history_empty') return 'No reading history.';
      if (key === 'my_bookshelf') return 'My Bookshelf';
      if (key === 'comic_catalog') return 'Comic Catalog';
      if (key === 'catalog_loading') return 'Loading catalog...';
      if (key === 'select_category') return 'Select a category to browse';
      if (key === 'images_unit') return 'img';
      if (key === 'enter_name') return 'Please enter a comic name.';
      if (key === 'reading_chapters') return 'Reading chapter list...';
      if (key === 'chapter_failed') return 'Failed to read chapters.';
      if (key === 'generating_scroll') return 'Generating scroll...';
      if (key === 'no_images') return 'No images extracted.';
      if (key === 'scroll_failed') return 'Scroll generation failed.';
      if (key === 'added_shelf') return 'Added to shelf.';
      if (key === 'theme_switched') return 'Theme switched.';
      if (key === 'unnamed_comic') return 'Unnamed Comic';
      if (key === 'unknown_author') return 'Unknown Author';
      if (key === 'latest_pending') return 'Latest pending';
      if (key === 'update_pending') return 'Update pending';
      if (key === 'remote_not_updated') return 'Remote rules not updated';
      if (key === 'remote_updating') return 'Updating remote rules...';
      if (key === 'remote_empty') return 'Remote rules empty. Using built-in rules.';
      if (key === 'remote_failed') return 'Remote rules update failed.';
      if (key === 'data_update') return 'Data Update';
      if (key === 'update_all') return 'Update All';
      if (key === 'update_rules') return 'Update Rules';
      if (key === 'update_catalog') return 'Update Catalog';
      if (key === 'updating') return 'Updating...';
      if (key === 'url_parse') return 'Public URL Parse';
      if (key === 'initial_status') return 'Enter a comic name to search public comic sites.';
      if (key === 'mixed') return 'Mixed';
      if (key === 'engine_only') return 'Engine Only';
      if (key === 'api_only') return 'API Only';
      if (key === 'chinese') return 'Chinese';
      if (key === 'english') return 'English';
      if (key === 'auto') return 'Auto';
      if (key === 'comic') return 'Comic';
      if (key === 'items_unit') return ' items';
      if (key === 'sources_unit') return ' sources';
      if (key === 'pages_unit') return ' pages';
      if (key === 'images_unit_full') return ' images';
      if (key === 'chapters_unit') return ' chapters';
      if (key === 'rules_unit') return ' rules';
      if (key === 'searching_keyword') return 'Searching';
      if (key === 'search_complete') return 'Search complete: ';
      if (key === 'results_suffix') return ' results.';
      if (key === 'no_comic_results') return 'No comic results. Try different keywords or site hints.';
      if (key === 'found_chapters') return 'Found ';
      if (key === 'scroll_complete') return 'Scroll complete: ';
      if (key === 'tracking_pages') return 'Tracking page ';
      if (key === 'extracted_images') return ', extracted ';
      if (key === 'engine_returned') return ' returned ';
      if (key === 'engine_current') return ', current ';
      if (key === 'engine_failed') return ' search failed. Trying other sources.';
      if (key === 'rule_progress') return 'Rule sources: ';
      if (key === 'rule_succeeded') return ' succeeded, ';
      if (key === 'rule_current') return ' results.';
      if (key === 'remote_updated') return 'Remote rules updated: ';
      if (key === 'lang_zh') return 'Chinese';
      if (key === 'lang_en') return 'English';
      if (key === 'lang_auto') return 'System';
      if (key === 'theme_light') return 'Light';
      if (key === 'theme_dark') return 'Dark';
      if (key === 'theme_system') return 'System';
      if (key === 'internet_archive') return 'Internet Archive Public Collection';
      if (key === 'favorites') return 'Favorites';
      if (key === 'list_view') return 'List';
      if (key === 'grid_view') return 'Grid';
      return key;
    }
    if (key === 'app_title') return '漫画浏览器';
    if (key === 'search') return '搜索';
    if (key === 'search_placeholder') return '输入漫画名称';
    if (key === 'shelf') return '书架';
    if (key === 'history') return '历史';
    if (key === 'settings') return '设置';
    if (key === 'no_cover') return '无封面';
    if (key === 'author') return '作者：';
    if (key === 'latest_chapter') return '最新章节：';
    if (key === 'update_time') return '更新时间：';
    if (key === 'comic_tag') return '漫画';
    if (key === 'search_results') return '漫画结果';
    if (key === 'search_prefix') return '搜索：';
    if (key === 'results_hint') return '默认列表显示，分类推荐已移动到书架。';
    if (key === 'searching_sources') return '正在搜索公开漫画来源...';
    if (key === 'no_results') return '没有找到结果，换个关键词试试。';
    if (key === 'chapter_list') return '章节目录';
    if (key === 'previous_chapter') return '上一章';
    if (key === 'next_chapter') return '下一章';
    if (key === 'chapter_ascending') return '正序';
    if (key === 'chapter_descending') return '倒序';
    if (key === 'no_chapters') return '没有章节。可能该结果本身就是单话漫画，或目录规则不匹配。';
    if (key === 'basic_settings') return '基础设置';
    if (key === 'app_settings') return 'APP设置';
    if (key === 'about') return '关于';
    if (key === 'debug_keep_screen_on') return '调试时屏幕常亮';
    if (key === 'theme') return '主题';
    if (key === 'language') return '语言';
    if (key === 'light') return '明亮';
    if (key === 'dark') return '暗黑';
    if (key === 'follow_system') return '跟随系统';
    if (key === 'reader_fullscreen') return '阅读页全屏';
    if (key === 'floating_controls') return '悬浮控制';
    if (key === 'icon_color') return '图标颜色';
    if (key === 'icon_color_colorful') return '多彩';
    if (key === 'icon_color_red') return '红色';
    if (key === 'icon_color_orange') return '橙色';
    if (key === 'icon_color_yellow') return '黄色';
    if (key === 'icon_color_green') return '绿色';
    if (key === 'icon_color_cyan') return '青色';
    if (key === 'icon_color_blue') return '蓝色';
    if (key === 'icon_color_indigo') return '靛色';
    if (key === 'icon_color_violet') return '紫色';
    if (key === 'icon_color_magenta') return '洋红';
    if (key === 'search_menu') return '搜索菜单';
    if (key === 'source_switch') return '源开关';
    if (key === 'display_reading') return '显示与阅读';
    if (key === 'reading_settings') return '阅读设置';
    if (key === 'search_engine') return '搜索引擎';
    if (key === 'rule_settings') return '规则设置';
    if (key === 'advanced_rules') return '高级规则';
    if (key === 'version') return '版本号';
    if (key === 'build_time') return '构建时间';
    if (key === 'search_mode') return '搜索模式';
    if (key === 'current_engine') return '当前搜索引擎';
    if (key === 'all_engines') return '全引擎搜索';
    if (key === 'language_pref') return '语言倾向';
    if (key === 'extra_terms') return '额外搜索词';
    if (key === 'site_hint') return '站点提示 site:example.com';
    if (key === 'html_rules') return 'HTML规则源';
    if (key === 'remote_rules') return '远程规则';
    if (key === 'auto_cover') return '自动补封面';
    if (key === 'show_page_num') return '显示页码';
    if (key === 'reading_bg') return '阅读背景';
    if (key === 'dark_color') return '深色';
    if (key === 'light_color') return '浅色';
    if (key === 'max_results') return '最大结果数';
    if (key === 'chapter_pages') return '章节追踪页数';
    if (key === 'remote_count') return '远程规则数量';
    if (key === 'remote_url') return '远程规则地址';
    if (key === 'custom_json') return '自定义 JSON 规则';
    if (key === 'enabled') return '已启用';
    if (key === 'disabled') return '已关闭';
    if (key === 'shelf_empty') return '书架为空。阅读章节后可加入书架。';
    if (key === 'history_empty') return '暂无阅读历史。';
    if (key === 'my_bookshelf') return '我的书架';
    if (key === 'comic_catalog') return '漫画目录';
    if (key === 'catalog_loading') return '加载目录中...';
    if (key === 'select_category') return '选择分类浏览漫画';
    if (key === 'images_unit') return '图';
    if (key === 'enter_name') return '请输入漫画名称。';
    if (key === 'reading_chapters') return '正在读取章节目录...';
    if (key === 'chapter_failed') return '章节读取失败。';
    if (key === 'generating_scroll') return '正在生成卷轴...';
    if (key === 'no_images') return '没有提取到图片。';
    if (key === 'scroll_failed') return '卷轴生成失败。';
    if (key === 'added_shelf') return '已加入书架。';
    if (key === 'theme_switched') return '主题已切换。';
    if (key === 'unnamed_comic') return '未命名漫画';
    if (key === 'unknown_author') return '未知作者';
    if (key === 'latest_pending') return '最新章节待获取';
    if (key === 'update_pending') return '更新时间待获取';
    if (key === 'remote_not_updated') return '远程规则未更新';
    if (key === 'remote_updating') return '正在更新远程规则...';
    if (key === 'remote_empty') return '远程规则为空，继续使用内置规则。';
    if (key === 'remote_failed') return '远程规则更新失败。';
    if (key === 'data_update') return '数据更新';
    if (key === 'update_all') return '全部更新';
    if (key === 'update_rules') return '更新规则';
    if (key === 'update_catalog') return '更新目录';
    if (key === 'updating') return '更新中...';
    if (key === 'url_parse') return '公开URL解析';
    if (key === 'initial_status') return '输入漫画名称后搜索公开漫画网页。';
    if (key === 'mixed') return '混合';
    if (key === 'engine_only') return '仅搜索引擎';
    if (key === 'api_only') return '仅公开API';
    if (key === 'chinese') return '中文';
    if (key === 'english') return '英文';
    if (key === 'auto') return '自动';
    if (key === 'comic') return '漫画';
    if (key === 'items_unit') return ' 个';
    if (key === 'sources_unit') return ' 个源';
    if (key === 'pages_unit') return ' 页';
    if (key === 'images_unit_full') return ' 张图片';
    if (key === 'chapters_unit') return ' 个章节';
    if (key === 'rules_unit') return ' 条';
    if (key === 'searching_keyword') return '正在搜索';
    if (key === 'search_complete') return '搜索完成：';
    if (key === 'results_suffix') return ' 个漫画相关条目。';
    if (key === 'no_comic_results') return '没有找到漫画相关结果，换个关键词或站点提示试试。';
    if (key === 'found_chapters') return '已找到 ';
    if (key === 'scroll_complete') return '卷轴生成完成：';
    if (key === 'tracking_pages') return '正在追踪章节分页：第 ';
    if (key === 'extracted_images') return '，已提取 ';
    if (key === 'engine_returned') return ' 返回 ';
    if (key === 'engine_current') return ' 个漫画相关网页，当前 ';
    if (key === 'engine_failed') return ' 检索失败，继续其它源。';
    if (key === 'rule_progress') return '规则源整理中：成功 ';
    if (key === 'rule_succeeded') return ' 个源，当前 ';
    if (key === 'rule_current') return ' 个结果。';
    if (key === 'remote_updated') return '远程规则已更新：';
    if (key === 'lang_zh') return '中文';
    if (key === 'lang_en') return 'English';
    if (key === 'lang_auto') return '跟随系统';
    if (key === 'theme_light') return '明亮';
    if (key === 'theme_dark') return '暗黑';
    if (key === 'theme_system') return '跟随系统';
    if (key === 'internet_archive') return 'Internet Archive公开馆藏';
    if (key === 'favorites') return '收藏';
    if (key === 'list_view') return '列表';
    if (key === 'grid_view') return '网格';
    return key;
  }

  private searchModeDisplay(): string {
    if (this.searchMode === 'mixed') return this.t('mixed');
    if (this.searchMode === 'engine_only') return this.t('engine_only');
    return this.t('api_only');
  }

  private languageModeDisplay(): string {
    if (this.languageMode === 'chinese') return this.t('chinese');
    if (this.languageMode === 'english') return this.t('english');
    return this.t('auto');
  }

  private themeDisplay(): string {
    if (this.appTheme === 'light') return this.t('theme_light');
    if (this.appTheme === 'dark') return this.t('theme_dark');
    return this.t('theme_system');
  }

  private languageDisplay(): string {
    if (this.appLanguage === 'zh') return this.t('lang_zh');
    if (this.appLanguage === 'en') return this.t('lang_en');
    return this.t('lang_auto');
  }

  private appBg(): string { return this.isDark() ? '#111318' : '#F6F8FA'; }
  private cardBg(): string { return this.isDark() ? '#1E232F' : '#FFFFFF'; }
  private accent(): string { return '#34C759'; }
  private primaryText(): string { return this.isDark() ? '#E8ECF4' : '#111827'; }
  private secondaryText(): string { return this.isDark() ? '#B6BFCC' : '#667085'; }
  private iconColor(icon: string): string {
    if (this.iconColorMode !== 'colorful') return this.iconModeColor(this.iconColorMode);
    if (icon === 'ic_search' || icon === 'ic_globe' || icon === 'ic_web') return '#0A84FF';
    if (icon === 'ic_shelf' || icon === 'ic_book' || icon === 'ic_add_shelf') return '#FF9500';
    if (icon === 'ic_history' || icon === 'ic_clock') return '#AF52DE';
    if (icon === 'ic_settings' || icon === 'ic_tune') return '#34C759';
    if (icon === 'ic_refresh' || icon === 'ic_engine') return '#00C7BE';
    if (icon === 'ic_rule' || icon === 'ic_code') return '#5856D6';
    if (icon === 'ic_language' || icon === 'ic_filter') return '#F5C400';
    if (icon === 'ic_reader' || icon === 'ic_reading' || icon === 'ic_layout' || icon === 'ic_fullscreen') return '#FF2D92';
    return '#FF3B30';
  }
  private iconModeColor(mode: string): string {
    if (mode === 'red') return '#FF3B30';
    if (mode === 'orange') return '#FF9500';
    if (mode === 'yellow') return '#F5C400';
    if (mode === 'green') return '#34C759';
    if (mode === 'cyan') return '#00C7BE';
    if (mode === 'blue') return '#0A84FF';
    if (mode === 'indigo') return '#5856D6';
    if (mode === 'violet') return '#AF52DE';
    if (mode === 'magenta') return '#FF2D92';
    return this.accent();
  }
  private colorfulValue(key: string): string {
    if (this.iconColorMode !== 'colorful') return this.iconModeColor(this.iconColorMode);
    const palette: string[] = ['#FF3B30', '#FF9500', '#F5C400', '#34C759', '#00C7BE', '#0A84FF', '#5856D6', '#AF52DE', '#FF2D92'];
    let value = 0;
    for (let i = 0; i < key.length; i++) value = (value + key.charCodeAt(i) * (i + 1)) % palette.length;
    return palette[value];
  }
  private searchActionColor(): string {
    return this.colorfulValue('search-' + this.activeTab + '-' + this.mode + '-' + this.selectedEngineIndex);
  }
  private iconColorModeDisplay(): string { return this.t('icon_color_' + this.iconColorMode); }
  private tabIconKey(name: string): string {
    if (name === 'search') return 'ic_search';
    if (name === 'shelf') return 'ic_shelf';
    if (name === 'history') return 'ic_history';
    return 'ic_settings';
  }
  private actionBg(): string { return '#167A36'; }
  private warnBg(): string { return this.isDark() ? '#2A2210' : '#FFF7E8'; }
  private warnText(): string { return this.isDark() ? '#F0C060' : '#8A5A12'; }
  private selectedSoftBg(): string { return this.isDark() ? '#1A3020' : '#E9FFF0'; }
  private glassBg(): string { return this.isDark() ? '#AA1E232F' : '#FFFFFFEE'; }
  private borderSubtle(): string { return this.isDark() ? '#2A2E3A' : '#F0F0F0'; }
  private dialogOverlay(): string { return this.isDark() ? '#88000000' : '#66000000'; }
  private inputBg(): string { return this.isDark() ? '#2A2E3A' : '#F2F4F7'; }
  private searchInputBg(): string { return this.isDark() ? '#2A2E3A' : '#F0F3F6'; }
  private coverPlaceholderBg(): string { return this.isDark() ? '#1A3020' : '#ECFFF1'; }
  private readerBarBg(): string { return this.isDark() ? '#1E232F' : '#FFFFFF'; }

  private selectedEngine(): SearchEngineConfig {
    if (this.selectedEngineIndex < 0 || this.selectedEngineIndex >= this.searchEngines.length) return this.searchEngines[0];
    return this.searchEngines[this.selectedEngineIndex];
  }

  private genericRule(): ComicSourceRule {
    const found = this.rules.find((item: ComicSourceRule) => item.id === 'generic_html_public');
    return found ? found : this.rules[0];
  }

  private findRule(sourceId: string): ComicSourceRule {
    const found = this.rules.find((item: ComicSourceRule) => item.id === sourceId);
    return found ? found : this.genericRule();
  }

  private ruleForItemUrl(url: string, sourceId: string): ComicSourceRule {
    return ruleForPublicUrl(url, this.findRule(sourceId));
  }

  private findRuleByUrl(url: string): ComicSourceRule {
    const targetHost = this.hostOf(url).toLowerCase();
    // Remote rules are merged into this.rules at runtime.  Match those rules
    // before falling back to the compile-time public rule table; otherwise a
    // newly published catalog domain can never use its newly published rule.
    for (let i = 0; i < this.rules.length; i++) {
      const ruleHost = this.hostOf(this.rules[i].homepage).toLowerCase();
      if (ruleHost.length > 0 && (targetHost === ruleHost || targetHost.endsWith('.' + ruleHost))) {
        return this.rules[i];
      }
    }
    for (let i = 0; i < this.rules.length; i++) {
      const domains = this.rules[i].domainApplicabilityList;
      if (!domains) continue;
      for (let j = 0; j < domains.length; j++) {
        const domain = this.hostOf(domains[j]).toLowerCase();
        if (domain.length > 0 && (targetHost === domain || targetHost.endsWith('.' + domain))) {
          return this.rules[i];
        }
      }
    }
    return ruleForPublicUrl(url, this.genericRule());
  }

  private nowText(): string {
    const date = new Date();
    const minute = date.getMinutes();
    return `${date.getMonth() + 1}-${date.getDate()} ${date.getHours()}:${minute < 10 ? '0' + minute : minute}`;
  }

  private hostOf(url: string): string {
    let host = url;
    const protocolIndex = host.indexOf('://');
    if (protocolIndex >= 0) host = host.substring(protocolIndex + 3);
    const slashIndex = host.indexOf('/');
    if (slashIndex >= 0) host = host.substring(0, slashIndex);
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  private cleanTitle(raw: string): string {
    let title = raw.trim().replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
    return title.length > 0 ? title : this.t('unnamed_comic');
  }

  private resultAuthor(item: SearchResultItem): string {
    return item.author !== undefined && item.author.length > 0 ? item.author : this.t('unknown_author');
  }

  private resultLatest(item: SearchResultItem): string {
    if (item.latestChapter !== undefined && item.latestChapter.length > 0) return item.latestChapter;
    if (item.isChapter) return this.cleanTitle(item.title);
    return this.t('latest_pending');
  }

  private resultUpdate(item: SearchResultItem): string {
    return item.updateTime !== undefined && item.updateTime.length > 0 ? item.updateTime : this.t('update_pending');
  }

  private enrich(item: SearchResultItem): SearchResultItem {
    return {
      title: this.cleanTitle(item.title),
      url: item.url,
      cover: item.cover,
      sourceId: item.sourceId,
      sourceName: item.sourceName,
      isChapter: item.isChapter,
      resultType: item.resultType,
      groupName: item.groupName,
      description: item.description,
      author: item.author,
      latestChapter: item.latestChapter,
      updateTime: item.updateTime,
      category: item.category !== undefined ? item.category : this.t('comic')
    };
  }

  private appendResults(sourceItems: SearchResultItem[]): void {
    const next: SearchResultItem[] = [];
    for (let i = 0; i < this.results.length; i++) next.push(this.results[i]);
    for (let j = 0; j < sourceItems.length; j++) {
      if (next.length >= this.maxSearchResults) break;
      const item = this.enrich(sourceItems[j]);
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
      next.push(item.url === url ? this.enrich({
        title: item.title,
        url: item.url,
        cover: cover,
        sourceId: item.sourceId,
        sourceName: item.sourceName,
        isChapter: item.isChapter,
        resultType: item.resultType,
        groupName: item.groupName,
        description: item.description,
        author: item.author,
        latestChapter: item.latestChapter,
        updateTime: item.updateTime,
        category: item.category
      }) : item);
    }
    this.results = next;
  }

  private resetSearchState(keyword: string): void {
    this.activeTab = 'search';
    this.mode = 'results';
    this.searchTitle = keyword;
    this.currentTitle = '';
    this.currentUrl = '';
    this.currentDetailUrl = '';
    this.currentChapterTitle = '';
    this.currentCover = '';
    this.currentSourceId = '';
    this.currentSourceName = '';
    this.results = [];
    this.chapters = [];
    this.images = [];
    this.statusText = this.t('searching_keyword') + ' "' + keyword + '"...';
  }

  private async startSearch(): Promise<void> {
    const keyword = this.queryText.trim();
    if (keyword.length === 0) {
      this.statusText = this.t('enter_name');
      return;
    }
    if (this.isLoading) return;
    if (looksLikeUrl(keyword)) {
      this.resetSearchState(keyword);
      this.isLoading = true;
      await this.loadDetail(normalizeUserUrl(keyword), this.t('url_parse'), ruleForPublicUrl(normalizeUserUrl(keyword), this.genericRule()));
      this.isLoading = false;
      return;
    }
    await this.searchKeyword(keyword);
  }

  private async searchKeyword(keyword: string): Promise<void> {
    this.resetSearchState(keyword);
    this.isLoading = true;
    try {
      this.searchLocalCatalog(keyword);
      // Local replay-validated entries appear immediately. Web search is a
      // discovery function: official, paid, login-gated or partially free
      // resources remain valid matches. Readability is evaluated only after a
      // result is opened and must not hide Tencent/Kuaikan/etc. search hits.
      if (this.searchMode !== 'api_only') await this.searchSelectedEngines(keyword);
      if (this.searchMode !== 'engine_only') {
        await this.searchHtmlRuleSources(keyword);
        if (this.appLanguage === 'en') await this.searchApiSources(keyword);
      }
      if (this.autoCoverEnabled) await this.enrichResultCovers(8);
    } finally {
      this.isLoading = false;
      this.statusText = this.results.length > 0 ? this.t('search_complete') + this.results.length + this.t('results_suffix') : this.t('no_comic_results');
    }
  }

  private searchLocalCatalog(keyword: string): void {
    if (this.remoteCatalog === null) return;
    const expected = keyword.toLowerCase().replace(/\s+/g, '');
    if (expected.length === 0) return;
    const categories = CatalogService.getCategories(this.remoteCatalog);
    for (let i = 0; i < categories.length; i++) {
      const categoryName = categories[i].name.toLowerCase().replace(/\s+/g, '');
      const categoryId = categories[i].id.toLowerCase().replace(/\s+/g, '');
      const categoryMatched = categoryName.indexOf(expected) >= 0 || categoryId.indexOf(expected) >= 0;
      const items = CatalogService.getItemsForCategory(this.remoteCatalog, categories[i].id);
      for (let j = 0; j < items.length; j++) {
        const item = items[j];
        // Search must never advertise legacy entries that were accepted by the
        // old decorative-image heuristic.
        if (item.validationPolicy !== 'readability-v4') continue;
        const titleMatched = item.title.toLowerCase().replace(/\s+/g, '').indexOf(expected) >= 0;
        if (!titleMatched && !categoryMatched) continue;
        const source = this.preferredCatalogSource(item);
        if (source === null || !source.detailUrl || source.detailUrl.length === 0) continue;
        if (!source.chapters || source.chapters.length !== (item.verifiedChapterCount ?? 0)) continue;
        this.appendResults([{
          title: item.title,
          url: source.detailUrl,
          cover: source.coverUrl ?? '',
          sourceId: this.findRuleByUrl(source.detailUrl).id,
          sourceName: source.domain,
          isChapter: false,
          resultType: 'catalog',
          groupName: item.title,
          description: categories[i].name + ' · ' + (item.verifiedChapterCount ?? 0) + this.t('chapters_unit'),
          category: categories[i].name
        }]);
      }
    }
    if (this.results.length > 0) {
      this.statusText = this.t('search_complete') + this.results.length + this.t('results_suffix');
    }
  }

  private async searchSelectedEngines(keyword: string): Promise<void> {
    if (!this.enableSearchEngines) return;
    const query = buildEngineQuery(keyword, this.extraSearchTerms, this.languageMode, this.siteHint);
    const engines: SearchEngineConfig[] = [];
    if (this.searchAllEngines) {
      for (let i = 0; i < this.searchEngines.length; i++) {
        if (this.searchEngines[i].enabled) engines.push(this.searchEngines[i]);
      }
    } else if (this.selectedEngine().enabled) {
      engines.push(this.selectedEngine());
    }
    const pending: Promise<SearchResultItem[]>[] = [];
    for (let i = 0; i < engines.length; i++) {
      if (isEngineConfigured(engines[i], this.braveApiKey, this.googleApiKey, this.googleCx)) {
        pending.push(this.fetchSearchEngineResults(engines[i], keyword, query));
      }
    }
    // HTML search providers frequently block or time out independently. Run
    // enabled engines concurrently so a failed DuckDuckGo request neither
    // produces a false zero-result search nor forces the user to wait through
    // several serial 20-second timeouts.
    const batches = await Promise.all(pending);
    for (let i = 0; i < batches.length; i++) {
      this.appendResults(batches[i]);
    }
    this.statusText = this.t('engine_returned') + this.results.length + this.t('items_unit');
  }

  private async fetchSearchEngineResults(engine: SearchEngineConfig, keyword: string,
    query: string): Promise<SearchResultItem[]> {
    try {
      const url = buildSearchEngineUrl(engine, query, this.braveApiKey, this.googleApiKey, this.googleCx);
      const body = await HttpClient.getTextWithHeaders(url, searchEngineUserAgent(), '',
        engineHeaders(engine, this.braveApiKey));
      return parseSearchEngineResults(body, engine, keyword, url);
    } catch (err) {
      return [];
    }
  }

  private async searchHtmlRuleSources(keyword: string): Promise<void> {
    if (!this.enableHtmlRules) return;
    let success = 0;
    let failed = 0;
    let attempted = 0;
    const pending: Promise<SearchResultItem[]>[] = [];
    for (let i = 0; i < this.rules.length; i++) {
      const rule = this.rules[i];
      if (rule.searchUrl.trim().length === 0) continue;
      // url-only rules parse links discovered elsewhere; they are not search
      // endpoints. Trying all generated rules here caused 1000+ serial HTTP
      // requests and made normal search appear frozen.
      if (rule.searchMethod === 'url-only') continue;
      // Direct site endpoints are a secondary supplement after web discovery.
      // Keep the foreground search bounded; unreachable legacy sources must
      // not make an otherwise complete result page look permanently busy.
      if (attempted >= 8) break;
      attempted++;
      pending.push(this.fetchHtmlRuleResults(rule, keyword));
    }
    const batches = await Promise.all(pending);
    for (let batchIndex = 0; batchIndex < batches.length; batchIndex++) {
      const parsed = batches[batchIndex];
      if (parsed.length > 0) {
        success++;
        this.appendResults(parsed);
        this.statusText = this.t('rule_progress') + success + this.t('rule_succeeded') + this.results.length + this.t('rule_current');
      } else {
        failed++;
      }
    }
    if (failed > 0 && success === 0) {
      this.statusText = this.t('chapter_failed');
    }
  }

  private async fetchHtmlRuleResults(rule: ComicSourceRule, keyword: string): Promise<SearchResultItem[]> {
    try {
      const searchUrl = rule.searchUrl.replace('{keyword}', encodeURIComponent(keyword));
      const html = await HttpClient.getTextWithTimeout(searchUrl, rule.userAgent,
        rule.referer.length > 0 ? rule.referer : rule.homepage, 8000);
      return parseSearchResults(html, rule, searchUrl, keyword).filter((item: SearchResultItem) => {
        const expected = keyword.toLowerCase().replace(/\s+/g, '');
        const actual = (item.title + ' ' + (item.description ?? '')).toLowerCase().replace(/\s+/g, '');
        return expected.length > 0 && actual.indexOf(expected) >= 0;
      });
    } catch (err) {
      return [];
    }
  }

  private async searchApiSources(keyword: string): Promise<void> {
    try {
      const iaUrl = buildInternetArchiveSearchUrl(keyword);
      const iaBody = await HttpClient.getText(iaUrl, 'Mozilla/5.0 HarmonyOS ComicReader/1.0', '');
      const iaResults = parseInternetArchiveSearch(iaBody, keyword);
      if (iaResults.length > 0) this.appendResults(iaResults);
    } catch (err) {
    }
    try {
      const wikiUrl = buildWikimediaSearchUrl(keyword);
      const wikiBody = await HttpClient.getText(wikiUrl, 'Mozilla/5.0 HarmonyOS ComicReader/1.0', '');
      const wikiResults = parseWikimediaSearch(wikiBody, keyword);
      if (wikiResults.length > 0) this.appendResults(wikiResults);
    } catch (err) {
    }
    try {
      const olUrl = buildOpenLibrarySearchUrl(keyword);
      const olBody = await HttpClient.getText(olUrl, 'Mozilla/5.0 HarmonyOS ComicReader/1.0', '');
      const olResults = parseOpenLibrarySearch(olBody, keyword);
      if (olResults.length > 0) this.appendResults(olResults);
    } catch (err) {
    }
    try {
      const locUrl = buildLibraryOfCongressSearchUrl(keyword);
      const locBody = await HttpClient.getText(locUrl, 'Mozilla/5.0 HarmonyOS ComicReader/1.0', '');
      const locResults = parseLibraryOfCongressSearch(locBody, keyword);
      if (locResults.length > 0) this.appendResults(locResults);
    } catch (err) {
    }
    const pepperResults = searchPepperCatalog(keyword);
    if (pepperResults.length > 0) this.appendResults(pepperResults);
  }

  private async enrichResultCovers(maxCount: number): Promise<void> {
    const count = Math.min(maxCount, this.results.length);
    for (let i = 0; i < count; i++) {
      const item = this.results[i];
      if (item.cover.length > 0) continue;
      const rule = this.ruleForItemUrl(item.url, item.sourceId);
      try {
        const html = await HttpClient.getText(item.url, rule.userAgent, rule.referer.length > 0 ? rule.referer : item.url);
        const parsedImages = parseImages(html, rule, item.url);
        if (parsedImages.length > 0) this.updateResultCover(item.url, parsedImages[0].url);
      } catch (err) {
      }
    }
  }

  private async loadDetail(url: string, title: string, rule: ComicSourceRule): Promise<void> {
    this.activeTab = 'search';
    this.currentUrl = url;
    this.currentDetailUrl = url;
    this.currentTitle = this.cleanTitle(title);
    this.currentSourceId = rule.id;
    this.currentSourceName = rule.name;
    this.chapters = [];
    this.images = [];
    this.mode = 'chapters';
    this.resetChapterScroll();
    this.statusText = this.t('reading_chapters');
    this.detailLoading = true;
    this.detailReceivedBytes = 0;
    this.detailTotalBytes = 0;
    try {
      // The release pipeline already replayed every published chapter URL.
      // Prefer that exact manifest over parsing the site again with a generic
      // regex; this keeps device behaviour equivalent to the online audit.
      const manifestItems = this.remoteCatalog !== null ? CatalogService.getAllItems(this.remoteCatalog) : this.catalogItems;
      for (let catalogIndex = 0; catalogIndex < manifestItems.length; catalogIndex++) {
        const sources = manifestItems[catalogIndex].sources;
        for (let sourceIndex = 0; sourceIndex < sources.length; sourceIndex++) {
          const source = sources[sourceIndex];
          if (source.detailUrl !== url || !source.chapters || source.chapters.length === 0) continue;
          this.chapters = source.chapters.map((chapter, index: number): ChapterItem => {
            return { title: chapter.title, url: chapter.url, index: index + 1,
              sourceId: rule.id, sourceName: rule.name };
          });
          this.statusText = this.t('found_chapters') + this.chapters.length + this.t('chapters_unit') + '.';
          return;
        }
      }
      if (isArchivePseudoUrl(url)) {
        await this.loadArchiveDetail(archiveIdentifierFromUrl(url), title);
        return;
      }
      if (isWikimediaPseudoUrl(url)) {
        const imageUrl = wikimediaImageFromUrl(url);
        this.images = [{ url: imageUrl, index: 1, status: 'waiting' }];
        this.mode = 'reader';
        this.statusText = this.t('scroll_complete') + '1' + this.t('images_unit_full') + '.';
        this.addHistory({ title: title, url: url, index: 1, sourceId: rule.id, sourceName: rule.name }, 1);
        return;
      }
      if (isLocPseudoUrl(url)) {
        const imageUrl = locImageFromUrl(url);
        this.images = [{ url: imageUrl, index: 1, status: 'waiting' }];
        this.mode = 'reader';
        this.statusText = this.t('scroll_complete') + '1' + this.t('images_unit_full') + '.';
        this.addHistory({ title: title, url: url, index: 1, sourceId: rule.id, sourceName: rule.name }, 1);
        return;
      }
      if (isPepperPseudoUrl(url)) {
        const pepperImages = parsePepperImages(url);
        if (pepperImages.length > 0) {
          this.images = pepperImages;
          this.mode = 'reader';
          this.currentChapterTitle = title;
          this.statusText = this.t('scroll_complete') + pepperImages.length + this.t('images_unit_full') + '.';
          this.addHistory({ title: title, url: url, index: 1, sourceId: rule.id, sourceName: rule.name }, pepperImages.length);
        } else {
          this.statusText = this.t('no_images');
        }
        return;
      }
      let html = '';
      try {
        html = await HttpClient.getTextWithProgressTimeout(url, rule.userAgent,
          rule.referer.length > 0 ? rule.referer : url,
          (received: number, total: number) => {
            this.detailReceivedBytes = received;
            this.detailTotalBytes = total;
          }, 60000);
      } catch (firstError) {
        this.statusText = this.t('loading_chapters') + ' · ' + this.t('retry');
        html = await HttpClient.getTextWithProgressTimeout(url, rule.userAgent,
          rule.referer.length > 0 ? rule.referer : url,
          (received: number, total: number) => {
            this.detailReceivedBytes = received;
            this.detailTotalBytes = total;
          }, 60000);
      }
      let parsedChapters = parseChapters(html, rule, url);
      if (parsedChapters.length === 0) parsedChapters = parseChaptersFallback(html, rule, url);
      // Some comic sites intermittently return a recommendation/challenge
      // shell with HTTP 200. A single parse must not replace a real directory
      // with one unrelated link, so retry suspiciously small manifests and
      // keep whichever response yields the most chapter-like entries.
      for (let retryIndex = 0; retryIndex < 2 && parsedChapters.length < 3; retryIndex++) {
        try {
          this.statusText = this.t('loading_chapters') + ' · ' + this.t('retry') + ' ' + (retryIndex + 1) + '/2';
          const retryHtml = await HttpClient.getTextWithProgressTimeout(url, rule.userAgent,
            rule.referer.length > 0 ? rule.referer : url,
            (received: number, total: number) => {
              this.detailReceivedBytes = received;
              this.detailTotalBytes = total;
            }, 30000);
          let retryChapters = parseChapters(retryHtml, rule, url);
          if (retryChapters.length === 0) retryChapters = parseChaptersFallback(retryHtml, rule, url);
          if (retryChapters.length > parsedChapters.length) parsedChapters = retryChapters;
        } catch (retryError) {
          // Preserve the best successful response. A failed reliability retry
          // must not turn a legitimate one-shot chapter into a request error.
        }
      }
      this.chapters = parsedChapters;
      if (parsedChapters.length === 0) {
        this.statusText = this.t('no_chapters');
        console.error('ComicReader no chapters matched: rule=' + rule.id + ', url=' + url +
          ', htmlLength=' + html.length);
      } else {
        this.statusText = this.t('found_chapters') + parsedChapters.length + this.t('chapters_unit') + '.';
      }
    } catch (err) {
      this.statusText = this.t('chapter_failed');
      console.error('ComicReader detail request failed: rule=' + rule.id + ', url=' + url +
        ', error=' + JSON.stringify(err));
    } finally {
      this.detailLoading = false;
    }
  }

  private async loadArchiveDetail(identifier: string, title: string): Promise<void> {
    try {
      const manifestUrl = buildInternetArchiveManifestUrl(identifier);
      const manifestBody = await HttpClient.getText(manifestUrl, 'Mozilla/5.0 HarmonyOS ComicReader/1.0', 'https://archive.org/');
      let images = parseInternetArchiveManifestImages(manifestBody);
      if (images.length === 0) {
        const metadataUrl = buildInternetArchiveMetadataUrl(identifier);
        const metadataBody = await HttpClient.getText(metadataUrl, 'Mozilla/5.0 HarmonyOS ComicReader/1.0', 'https://archive.org/');
        images = parseInternetArchiveMetadataImages(metadataBody, identifier);
      }
      if (images.length > 0) {
        this.images = images;
        this.mode = 'reader';
        this.statusText = this.t('scroll_complete') + images.length + this.t('images_unit_full') + '.';
        this.addHistory({ title: title, url: 'archive://item/' + encodeURIComponent(identifier), index: 1, sourceId: 'internet_archive_iiif_api', sourceName: this.t('internet_archive') }, images.length);
      } else {
        this.chapters = [];
        this.statusText = this.t('no_images');
      }
    } catch (err) {
      this.statusText = this.t('chapter_failed');
    }
  }

  private mergeReaderImages(base: ReaderImageItem[], incoming: ReaderImageItem[]): ReaderImageItem[] {
    const next: ReaderImageItem[] = [];
    for (let i = 0; i < base.length && next.length < 500; i++) next.push({ url: base[i].url, index: next.length + 1, status: base[i].status });
    for (let j = 0; j < incoming.length && next.length < 500; j++) {
      const image = incoming[j];
      if (!next.some((oldItem: ReaderImageItem) => oldItem.url === image.url)) next.push({ url: image.url, index: next.length + 1, status: 'waiting' });
    }
    return next;
  }

  private async fetchReaderImagesWithPagination(firstUrl: string, rule: ComicSourceRule): Promise<ReaderImageItem[]> {
    let pageUrl = firstUrl;
    let allImages: ReaderImageItem[] = [];
    const visited: string[] = [];
    const rulePages = rule.maxReaderPages !== undefined && rule.maxReaderPages > 0 ? rule.maxReaderPages : 1;
    const maxPages = Math.max(rulePages, this.maxReaderPages);
    for (let page = 0; page < maxPages; page++) {
      if (pageUrl.length === 0 || visited.indexOf(pageUrl) >= 0) break;
      visited.push(pageUrl);
      const html = await HttpClient.getText(pageUrl, rule.userAgent, rule.referer.length > 0 ? rule.referer : pageUrl);
      const pageImages = parseImages(html, rule, pageUrl);
      allImages = this.mergeReaderImages(allImages, pageImages);
      // Render each successfully parsed page immediately. Long chapters should
      // not remain black while the following pagination requests are running.
      this.images = allImages;
      const nextUrl = parseNextPageUrl(html, rule, pageUrl);
      if (nextUrl.length === 0 || nextUrl === pageUrl) break;
      pageUrl = nextUrl;
      this.statusText = this.t('tracking_pages') + (page + 2) + this.t('pages_unit') + this.t('extracted_images') + allImages.length + this.t('images_unit_full') + '.';
    }
    // A normal comic chapter should contain more than a cover and placeholder.
    // Do not present two decorative assets as a successfully loaded chapter.
    if (allImages.length < 8) return [];
    return allImages;
  }

  private async loadChapter(chapter: ChapterItem, rule: ComicSourceRule): Promise<void> {
    this.activeTab = 'search';
    this.mode = 'reader';
    this.currentChapterTitle = chapter.title;
    this.currentUrl = chapter.url;
    this.currentSourceId = chapter.sourceId;
    this.currentSourceName = chapter.sourceName;
    this.images = [];
    this.readerRenderLimit = 6;
    this.readerPaginationLoading = true;
    this.readerToolsVisible = false;
    this.readerChapterPanelVisible = false;
    this.applyReaderFullscreen(this.fullscreenReader);
    this.statusText = this.t('generating_scroll');
    try {
      const parsedImages = await this.fetchReaderImagesWithPagination(chapter.url, rule);
      this.images = parsedImages;
      this.statusText = parsedImages.length > 0 ? this.t('scroll_complete') + parsedImages.length + this.t('images_unit_full') + '.' : this.t('no_images');
      this.addHistory(chapter, parsedImages.length);
    } catch (err) {
      this.statusText = this.t('scroll_failed');
    } finally {
      this.readerPaginationLoading = false;
    }
  }

  private displayedReaderImages(): ReaderImageItem[] {
    return this.images.slice(0, Math.min(this.images.length, this.readerRenderLimit));
  }

  private chapterNumber(title: string): number {
    // Several official catalogs prefix the stable episode sequence before the
    // display title, e.g. `221 - 第131回（上）`. The leading 221 is the real
    // reading order; using 131 groups split parts incorrectly and moves the
    // first 220 episodes behind them.
    const leading = /^\s*(\d+)\s*[-—–.:：]/.exec(title);
    if (leading && leading[1].length > 0) return Number(leading[1]);
    const match = /第\s*(\d+)\s*[话章回卷]|(?:chapter\s*|episode\s*|ep\.?\s*)(\d+)/i.exec(title);
    if (!match) return -1;
    if (match[1] !== undefined && match[1].length > 0) return Number(match[1]);
    return match[2] !== undefined && match[2].length > 0 ? Number(match[2]) : -1;
  }

  private chaptersInReadingOrder(): ChapterItem[] {
    const ordered = [...this.chapters];
    ordered.sort((left: ChapterItem, right: ChapterItem): number => {
      const leftNumber = this.chapterNumber(left.title);
      const rightNumber = this.chapterNumber(right.title);
      if (leftNumber >= 0 && rightNumber >= 0) return leftNumber - rightNumber;
      if (leftNumber >= 0) return -1;
      if (rightNumber >= 0) return 1;
      return 0;
    });
    return ordered;
  }

  private currentImagesFinished(): boolean {
    if (this.images.length === 0 || this.readerRenderLimit < this.images.length) return false;
    return !this.images.some((item: ReaderImageItem) => item.status === 'waiting');
  }

  private async loadNextChapterIfReady(): Promise<void> {
    if (this.readerChangingChapter || this.readerPaginationLoading || !this.currentImagesFinished()) return;
    const ordered = this.chaptersInReadingOrder();
    const currentIndex = ordered.findIndex((item: ChapterItem) => item.url === this.currentUrl);
    if (currentIndex < 0 || currentIndex + 1 >= ordered.length) return;
    const nextChapter = ordered[currentIndex + 1];
    this.readerChangingChapter = true;
    try {
      await this.loadChapter(nextChapter, this.findRule(nextChapter.sourceId));
    } finally {
      this.readerChangingChapter = false;
    }
  }

  private async loadRelativeChapter(offset: number): Promise<void> {
    if (this.readerChangingChapter || this.readerPaginationLoading) return;
    const ordered = this.chaptersInReadingOrder();
    const currentIndex = ordered.findIndex((item: ChapterItem) => item.url === this.currentUrl);
    const targetIndex = currentIndex + offset;
    if (currentIndex < 0 || targetIndex < 0 || targetIndex >= ordered.length) return;
    this.readerChangingChapter = true;
    try {
      await this.loadChapter(ordered[targetIndex], this.findRule(ordered[targetIndex].sourceId));
    } finally {
      this.readerChangingChapter = false;
    }
  }

  private hasRelativeChapter(offset: number): boolean {
    const ordered = this.chaptersInReadingOrder();
    const currentIndex = ordered.findIndex((item: ChapterItem) => item.url === this.currentUrl);
    return currentIndex >= 0 && currentIndex + offset >= 0 && currentIndex + offset < ordered.length;
  }

  private displayedChapters(): ChapterItem[] {
    const source = [...this.chapters];
    source.sort((left: ChapterItem, right: ChapterItem): number => {
      const leftNumber = this.chapterNumber(left.title);
      const rightNumber = this.chapterNumber(right.title);
      if (leftNumber >= 0 && rightNumber >= 0 && leftNumber !== rightNumber) {
        return this.chapterReversed ? leftNumber - rightNumber : rightNumber - leftNumber;
      }
      if (leftNumber >= 0 && rightNumber < 0) return -1;
      if (leftNumber < 0 && rightNumber >= 0) return 1;
      return 0;
    });
    const displayed: ChapterItem[] = [];
    for (let i = 0; i < source.length; i++) {
      displayed.push({ title: source[i].title, url: source[i].url, index: i + 1,
        sourceId: source[i].sourceId, sourceName: source[i].sourceName });
    }
    return displayed;
  }

  private readerPanelChapters(): ChapterItem[] {
    const displayed = this.displayedChapters();
    if (displayed.length > 0) return displayed;
    if (this.currentUrl.length === 0) return [];
    return [{ title: this.currentChapterTitle, url: this.currentUrl, index: 1,
      sourceId: this.currentSourceId, sourceName: this.currentSourceName }];
  }

  private markImage(index: number, status: string): void {
    let changed = false;
    const next: ReaderImageItem[] = [];
    for (let i = 0; i < this.images.length; i++) {
      const item = this.images[i];
      if (item.index === index && item.status !== status) {
        changed = true;
        next.push({ url: item.url, index: item.index, status: status });
      } else {
        next.push(item);
      }
    }
    if (changed) {
      this.images = next;
      if (this.readerRenderLimit < this.images.length) this.readerRenderLimit++;
    }
  }

  private openSearchResult(item: SearchResultItem): void {
    const rule = this.ruleForItemUrl(item.url, item.sourceId);
    if (item.isChapter) {
      this.currentDetailUrl = '';
      this.loadChapter({ title: item.title, url: item.url, index: 1, sourceId: item.sourceId, sourceName: item.sourceName }, rule);
    }
    else this.loadDetail(item.url, item.title, rule);
  }

  private addHistory(chapter: ChapterItem, imageCount: number): void {
    const item: ReadingHistoryItem = {
      title: this.currentTitle.length > 0 ? this.currentTitle : chapter.title,
      url: chapter.url,
      detailUrl: this.currentDetailUrl,
      chapterTitle: chapter.title,
      sourceId: chapter.sourceId,
      sourceName: chapter.sourceName,
      cover: this.currentCover,
      lastReadAt: this.nowText(),
      imageCount: imageCount,
      progressPercent: imageCount > 0 ? 100 : 0
    };
    const next = [item];
    for (let i = 0; i < this.history.length && next.length < 40; i++) {
      if (this.history[i].url !== item.url) next.push(this.history[i]);
    }
    this.history = next;
    this.persistData();
  }

  private async openHistoryItem(item: ReadingHistoryItem): Promise<void> {
    if (item.detailUrl && item.detailUrl.length > 0 && item.detailUrl !== item.url) {
      await this.loadDetail(item.detailUrl, item.title, this.findRule(item.sourceId));
      const chapter = this.chapters.find((candidate: ChapterItem) => candidate.url === item.url);
      if (chapter) {
        await this.loadChapter(chapter, this.findRule(chapter.sourceId));
        return;
      }
    }
    this.chapters = [{ title: item.chapterTitle, url: item.url, index: 1,
      sourceId: item.sourceId, sourceName: item.sourceName }];
    await this.loadChapter(this.chapters[0], this.findRule(item.sourceId));
  }

  private coverCacheName(url: string): string {
    let hash = 7;
    for (let i = 0; i < url.length; i++) hash = (hash * 31 + url.charCodeAt(i)) % 2147483647;
    const lower = url.toLowerCase();
    let extension = '.img';
    if (/\.png(?:\?|$)/.test(lower)) extension = '.png';
    else if (/\.webp(?:\?|$)/.test(lower)) extension = '.webp';
    else if (/\.gif(?:\?|$)/.test(lower)) extension = '.gif';
    else if (/\.jpe?g(?:\?|$)/.test(lower)) extension = '.jpg';
    return hash.toString() + extension;
  }

  private async cacheBookshelfCover(itemUrl: string, remoteCover: string): Promise<void> {
    if (this.coverCacheDir.length === 0 || !/^https?:\/\//i.test(remoteCover)) return;
    const localPath = this.coverCacheDir + '/' + this.coverCacheName(remoteCover);
    try {
      if (!fs.accessSync(localPath)) {
        const rule = this.findRuleByUrl(itemUrl);
        const bytes = await HttpClient.getBytes(remoteCover, rule.userAgent,
          rule.referer.length > 0 ? rule.referer : itemUrl);
        const file = fs.openSync(localPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
        fs.writeSync(file.fd, bytes);
        fs.closeSync(file);
      }
      const next: BookshelfItem[] = [];
      for (let i = 0; i < this.bookshelf.length; i++) {
        const old = this.bookshelf[i];
        if (old.url === itemUrl) {
          next.push({
            title: old.title, url: old.url, cover: 'file://' + localPath, remoteCover: remoteCover,
            sourceId: old.sourceId, sourceName: old.sourceName,
            lastChapterTitle: old.lastChapterTitle, lastChapterUrl: old.lastChapterUrl,
            addedAt: old.addedAt, lastReadAt: old.lastReadAt,
            imageCount: old.imageCount, progressPercent: old.progressPercent, readCount: old.readCount
          });
        } else {
          next.push(old);
        }
      }
      this.bookshelf = next;
      this.persistData();
    } catch (e) {
      console.error('ComicReader cover cache failed: ' + JSON.stringify(e));
    }
  }

  private cacheExistingBookshelfCovers(): void {
    for (let i = 0; i < this.bookshelf.length; i++) {
      const item = this.bookshelf[i];
      const remote = item.remoteCover && item.remoteCover.length > 0 ? item.remoteCover : item.cover;
      if (/^https?:\/\//i.test(remote)) this.cacheBookshelfCover(item.url, remote);
    }
  }

  private addCurrentToShelf(): void {
    if (this.currentUrl.length === 0) return;
    const item: BookshelfItem = {
      title: this.currentTitle.length > 0 ? this.currentTitle : this.t('unnamed_comic'),
      url: this.currentDetailUrl.length > 0 ? this.currentDetailUrl : this.currentUrl,
      sourceId: this.currentSourceId,
      sourceName: this.currentSourceName,
      cover: this.currentCover,
      remoteCover: this.currentCover,
      lastChapterTitle: this.currentChapterTitle,
      lastChapterUrl: this.currentUrl,
      addedAt: this.nowText(),
      lastReadAt: this.nowText(),
      imageCount: this.images.length,
      progressPercent: this.images.length > 0 ? 100 : 0
    };
    const next = [item];
    for (let i = 0; i < this.bookshelf.length && next.length < 100; i++) {
      if (this.bookshelf[i].url !== item.url) next.push(this.bookshelf[i]);
    }
    this.bookshelf = next;
    this.statusText = this.t('added_shelf');
    this.persistData();
    this.cacheBookshelfCover(item.url, this.currentCover);
  }

  private isCurrentFavorite(): boolean {
    return this.bookshelf.some((item: BookshelfItem) => item.title === this.currentTitle &&
      (this.currentSourceId.length === 0 || item.sourceId === this.currentSourceId));
  }

  private toggleCurrentFavorite(): void {
    if (this.isCurrentFavorite()) {
      this.bookshelf = this.bookshelf.filter((item: BookshelfItem) => !(item.title === this.currentTitle &&
        (this.currentSourceId.length === 0 || item.sourceId === this.currentSourceId)));
      this.statusText = this.isEn() ? 'Removed from favorites.' : '已取消收藏。';
      this.persistData();
      return;
    }
    this.addCurrentToShelf();
  }

  private cycleEngine(): void {
    this.selectedEngineIndex = (this.selectedEngineIndex + 1) % this.searchEngines.length;
  }

  private nextSearchMode(): void {
    if (this.searchMode === 'mixed') this.searchMode = 'engine_only';
    else if (this.searchMode === 'engine_only') this.searchMode = 'api_only';
    else this.searchMode = 'mixed';
  }

  private nextLanguageMode(): void {
    if (this.languageMode === 'chinese') this.languageMode = 'english';
    else if (this.languageMode === 'english') this.languageMode = 'auto';
    else this.languageMode = 'chinese';
  }

  private applyCustomRule(): void {
    try {
      const parsed = JSON.parse(this.customRuleText) as ComicSourceRule;
      if (parsed.id !== undefined && parsed.id.length > 0 && parsed.readerImageRegex !== undefined && parsed.readerImageRegex.length > 0) {
        const exists = this.rules.findIndex((item: ComicSourceRule) => item.id === parsed.id);
        if (exists >= 0) {
          const next = [...this.rules];
          next[exists] = parsed;
          this.rules = next;
        } else {
          this.rules = [parsed, ...this.rules];
        }
        this.statusText = this.t('added_shelf');
      } else {
        this.statusText = this.t('chapter_failed');
      }
    } catch (err) {
      this.statusText = this.t('chapter_failed');
    }
  }

  private toggleTheme(): void {
    this.appTheme = this.appTheme === 'light' ? 'dark' : 'light';
    this.updateSystemBarColors();
    this.statusText = this.t('theme_switched');
    this.persistData();
  }

  private async updateRemoteRules(): Promise<void> {
    this.remoteRuleStatus = this.t('remote_updating');
    this.updatingRules = true;
    try {
      const loaded = await RemoteRuleService.fetchRemoteRules(this.remoteRuleUrl);
      if (loaded.length > 0) {
        this.rules = RemoteRuleService.mergeRules(DEFAULT_SOURCES, loaded);
        this.remoteRuleCount = loaded.length;
        this.remoteRuleStatus = this.t('remote_updated') + loaded.length + this.t('rules_unit');
      } else {
        this.remoteRuleStatus = this.t('remote_empty');
      }
    } catch (err) {
      this.remoteRuleStatus = this.t('remote_failed');
    }
    this.updatingRules = false;
  }

  private async updateCatalog(): Promise<void> {
    if (this.updatingCatalog) return;
    this.updatingCatalog = true;
    this.catalogReceivedBytes = 0;
    this.catalogTotalBytes = 0;
    this.catalogProgressPercent = 0;
    try {
      this.catalogUpdateStatus = this.catalogStage('正在检查线上目录版本…', 'Checking online catalog version…');
      const update = await CatalogService.fetchCatalogUpdate();
      if (CatalogService.isNewerVersion(update.version, this.remoteCatalog?.version)) {
        this.catalogUpdateStatus = this.catalogStage('发现新版本，正在下载目录…', 'New version found. Downloading catalog…');
        this.pendingCatalogVersion = update.version;
        this.pendingCatalogUrl = update.url;
        const catalog = await CatalogService.fetchCatalogFromUrl(update.url,
          (received: number, total: number) => {
            this.catalogReceivedBytes = received;
            this.catalogTotalBytes = total;
            this.catalogProgressPercent = total > 0 ? Math.min(100, Math.floor(received * 100 / total)) : 0;
          });
        if (catalog.version === update.version) {
          this.catalogUpdateStatus = this.catalogStage('下载完成，正在校验并写入缓存…', 'Download complete. Validating and caching…');
          this.saveCatalogCache(catalog);
          this.applyCatalog(catalog);
          this.catalogProgressPercent = 100;
          this.catalogUpdateAvailable = false;
          this.catalogUpdateStatus = this.catalogStage('目录已更新至 ' + update.version,
            'Catalog updated to ' + update.version);
        }
      } else {
        this.catalogUpdateStatus = this.catalogStage('目录已是最新，继续使用缓存',
          'Catalog is current. Using cache.');
      }
    } catch (err) {
      this.catalogUpdateStatus = this.catalogStage('线上检查失败，继续使用现有缓存',
        'Online check failed. Using existing cache.');
      console.error('ComicReader catalog manual update failed: ' + JSON.stringify(err));
    }
    this.updatingCatalog = false;
  }

  private async updateAll(): Promise<void> {
    await Promise.all([this.updateRemoteRules(), this.updateCatalog()]);
  }

  private onStatusTextChanged(): void {
    if (this.statusMessageTimerId !== -1) clearTimeout(this.statusMessageTimerId);
    this.statusMessageVisible = this.statusText.trim().length > 0;
    if (!this.statusMessageVisible) return;
    this.statusMessageTimerId = setTimeout(() => {
      this.statusMessageVisible = false;
      this.statusMessageTimerId = -1;
    }, 3000) as number;
  }

  @Builder
  private StatusMessageOverlay() {
    Text(this.statusText)
      .fontSize(12).fontColor(this.warnText()).lineHeight(16).maxLines(2)
      .padding({ left: 13, right: 13, top: 7, bottom: 7 })
      .backgroundColor(this.isDark() ? '#B82A2210' : '#D8FFF7E8')
      .backgroundBlurStyle(BlurStyle.Thin, { colorMode: this.isDark() ? ThemeColorMode.DARK : ThemeColorMode.LIGHT })
      .border({ width: 1, color: this.isDark() ? '#55F0C060' : '#558A5A12' })
      .borderRadius(15).margin({ left: 36, right: 36 })
  }

  private onLoadingChanged(): void {
    if (this.isLoading) {
      this.startLoadingAnimation();
    } else {
      this.stopLoadingAnimation();
    }
  }

  private startLoadingAnimation(): void {
    this.loadingAngle = 0;
    this.loadingTimerId = setInterval(() => {
      this.loadingAngle = (this.loadingAngle + 4) % 3600;
      this.drawLoadingStroke();
    }, 16) as number;
  }

  private stopLoadingAnimation(): void {
    if (this.loadingTimerId !== -1) {
      clearInterval(this.loadingTimerId);
      this.loadingTimerId = -1;
    }
  }

  private getPathPoint(dist: number, ox: number, oy: number, w: number, h: number, r: number): number[] {
    const topLen = w - 2 * r;
    const rightArcLen = Math.PI * r;
    const bottomLen = w - 2 * r;
    const leftArcLen = Math.PI * r;
    const totalLen = topLen + rightArcLen + bottomLen + leftArcLen;
    let d = ((dist % totalLen) + totalLen) % totalLen;
    if (d <= topLen) {
      return [ox + r + d, oy];
    }
    d -= topLen;
    if (d <= rightArcLen) {
      const angle = -Math.PI / 2 + d / r;
      return [ox + w - r + r * Math.cos(angle), oy + r + r * Math.sin(angle)];
    }
    d -= rightArcLen;
    if (d <= bottomLen) {
      return [ox + w - r - d, oy + h];
    }
    d -= bottomLen;
    const angle2 = Math.PI / 2 + d / r;
    return [ox + r + r * Math.cos(angle2), oy + r + r * Math.sin(angle2)];
  }

  private drawLoadingStroke(): void {
    const ctx = this.canvasCtx;
    const w = ctx.width;
    const h = ctx.height;
    if (w <= 0 || h <= 0) return;
    ctx.clearRect(0, 0, w, h);
    const pad = 2;
    const rw = w - 2 * pad;
    const rh = h - 2 * pad;
    const r = rh / 2;
    const totalLen = 2 * (rw - 2 * r) + 2 * Math.PI * r;
    const visibleRatio = 0.7;
    const visibleLen = totalLen * visibleRatio;
    const segments = 120;
    const segLen = visibleLen / segments;
    const offset = (this.loadingAngle / 3600) * totalLen;
    ctx.lineWidth = 3;
    ctx.lineCap = 'butt';
    for (let i = 0; i < segments; i++) {
      const t = i / segments;
      const alpha = 1.0 - 2.0 * Math.abs(t - 0.5);
      if (alpha <= 0.02) continue;
      const startDist = offset + i * segLen;
      const endDist = offset + (i + 1) * segLen;
      const p1 = this.getPathPoint(startDist, pad, pad, rw, rh, r);
      const p2 = this.getPathPoint(endDist, pad, pad, rw, rh, r);
      ctx.beginPath();
      ctx.moveTo(p1[0], p1[1]);
      ctx.lineTo(p2[0], p2[1]);
      const a = Math.round(alpha * 255);
      const aHex = a.toString(16).padStart(2, '0');
      const segmentColor = this.colorfulValue('loading-' + Math.floor(i / 14));
      ctx.strokeStyle = '#' + aHex + segmentColor.substring(1);
      ctx.stroke();
    }
  }

  @Builder
  private SearchActionButton(heightValue: number) {
    Stack() {
      Button(this.t('search'))
        .width(76)
        .height(heightValue)
        .fontSize(15)
        .fontColor('#FFFFFF')
        .backgroundColor(this.searchActionColor())
        .borderRadius(heightValue / 2)
        .padding({ left: 20, right: 20 })
        .enabled(!this.isLoading)
        .onClick(() => { this.startSearch(); })
      if (this.isLoading) {
        Canvas(this.canvasCtx)
          .width(76)
          .height(heightValue)
          .hitTestBehavior(HitTestMode.Transparent)
          .onReady(() => {
            this.drawLoadingStroke();
          })
      }
    }
  }

  private headerGradientColors(): Array<[string, number]> {
    return this.isDark()
      ? [['#BB111318', 0.0], ['#AA111318', 0.05], ['#99111318', 0.12], ['#88111318', 0.22], ['#77111318', 0.35], ['#66111318', 0.52], ['#55111318', 0.72], ['#33111318', 0.88], ['#00111318', 1.0]] as Array<[string, number]>
      : [['#C0F6F8FA', 0.0], ['#B0F6F8FA', 0.05], ['#A0F6F8FA', 0.12], ['#90F6F8FA', 0.22], ['#80F6F8FA', 0.35], ['#70F6F8FA', 0.52], ['#50F6F8FA', 0.72], ['#30F6F8FA', 0.88], ['#00F6F8FA', 1.0]] as Array<[string, number]>;
  }

  private readerControlGradient(): Array<[string, number]> {
    return this.isDark()
      ? [['#681E232F', 0.0], ['#401E232F', 0.55], ['#24111318', 1.0]] as Array<[string, number]>
      : [['#82FFFFFF', 0.0], ['#52FFFFFF', 0.55], ['#28F6F8FA', 1.0]] as Array<[string, number]>;
  }

  private readerPanelGradient(): Array<[string, number]> {
    return this.isDark()
      ? [['#881E232F', 0.0], ['#601E232F', 0.45], ['#28111318', 1.0]] as Array<[string, number]>
      : [['#A8FFFFFF', 0.0], ['#78FFFFFF', 0.45], ['#38F6F8FA', 1.0]] as Array<[string, number]>;
  }

  @Builder
  private SearchHeader() {
    Column() {
      Column() {
        Row() {
          Stack() {
            TextInput({ placeholder: this.t('search_placeholder'), text: this.queryText })
              .height(44)
              .fontSize(15)
              .fontColor(this.primaryText())
              .placeholderColor(this.secondaryText())
              .backgroundColor(Color.Transparent)
              .borderRadius(22)
              .border({ width: 1, color: this.secondaryText() })
              .padding({ left: 14, right: this.queryText.length > 0 ? 40 : 14 })
              .onChange((value: string) => { this.queryText = value; })
              .onSubmit(() => { this.startSearch(); })
            if (this.queryText.length > 0) {
              Row() {
                Column() {
                  Image($rawfile('ic_x.svg')).width(14).height(14).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_x')))
                }.width(32).height(32).justifyContent(FlexAlign.Center).margin({ right: 6 })
                  .onClick(() => { this.isLoading = false; this.queryText = ''; this.results = []; this.mode = 'home'; })
              }.width('100%').justifyContent(FlexAlign.End)
            }
          }.layoutWeight(1)
          Column() { this.SearchActionButton(44) }
            .margin({ left: 8 })
        }
        .width('100%')
        .padding({ left: 14, right: 14, bottom: 8 })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ top: this.avoidStatusBarHeight })
    .linearGradient({ angle: 180, colors: this.headerGradientColors() })
  }

  @Builder
  private SearchHome() {
    Scroll() {
      Column() {
        Blank().height(this.contentTopInset())
        Blank().layoutWeight(1)
        Image($r('app.media.app_icon')).width(220).height(180).objectFit(ImageFit.Contain).margin({ bottom: 24 })
        Row() {
          Stack() {
            TextInput({ placeholder: this.t('search_placeholder'), text: this.queryText })
              .height(52).fontSize(15).fontColor(this.primaryText()).placeholderColor(this.secondaryText())
              .backgroundColor(Color.Transparent).borderRadius(26).border({ width: 1, color: this.secondaryText() })
              .padding({ left: 18, right: this.queryText.length > 0 ? 44 : 18 })
              .onChange((value: string) => { this.queryText = value; }).onSubmit(() => { this.startSearch(); })
            if (this.queryText.length > 0) {
              Row() {
                Column() { Image($rawfile('ic_x.svg')).width(16).height(16).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_x'))) }
                  .width(36).height(36).justifyContent(FlexAlign.Center).margin({ right: 8 })
                  .onClick(() => { this.isLoading = false; this.queryText = ''; this.results = []; this.mode = 'home'; })
              }.width('100%').justifyContent(FlexAlign.End)
            }
          }.layoutWeight(1)
          Column() { this.SearchActionButton(52) }.margin({ left: 10 })
        }.width('100%').padding({ left: 22, right: 22 })
        Blank().layoutWeight(1)
        Blank().height(this.contentBottomInset())
      }.width('100%').height('100%').alignItems(HorizontalAlign.Center)
    }
    .layoutWeight(1)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .backgroundColor(this.appBg())
  }

  @Builder
  private CoverBox(item: SearchResultItem, heightValue: number) {
    if (item.cover.length > 0) {
      Image(item.cover)
        .width('100%')
        .height(heightValue)
        .objectFit(ImageFit.Cover)
    } else {
      Column() {
        Text(item.title.substring(0, 1))
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.accent())
        Text(this.t('no_cover'))
          .fontSize(11)
          .fontColor(this.secondaryText())
          .margin({ top: 6 })
      }
      .width('100%')
      .height(heightValue)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.coverPlaceholderBg())
    }
  }

  @Builder
  private ResultListCard(item: SearchResultItem) {
    Row() {
      Column() { this.CoverBox(item, 104) }.width(76).height(104).clip(true).borderRadius(12)
      Column() {
        Text(this.cleanTitle(item.title)).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
        Text(this.t('author') + this.resultAuthor(item)).fontSize(12).fontColor(this.secondaryText()).margin({ top: 5 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.t('latest_chapter') + this.resultLatest(item)).fontSize(12).fontColor(this.secondaryText()).margin({ top: 4 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.t('update_time') + this.resultUpdate(item)).fontSize(12).fontColor(this.secondaryText()).margin({ top: 4 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row() {
          Text(this.t('comic_tag')).fontSize(11).fontColor('#FFFFFF').padding({ left: 8, right: 8, top: 3, bottom: 3 }).backgroundColor(this.actionBg()).borderRadius(10)
          Text(this.hostOf(item.url)).fontSize(11).fontColor(this.secondaryText()).layoutWeight(1).margin({ left: 8 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }.width('100%').margin({ top: 7 })
      }.layoutWeight(1).margin({ left: 12 })
    }
    .width('100%')
    .height(124)
    .padding(10)
    .backgroundColor(this.cardBg())
    .borderRadius(16)
    .margin({ bottom: 10 })
    .onClick(() => this.openSearchResult(item))
  }

  @Builder
  private ResultsPage() {
    Scroll() {
      Column() {
        Blank().height(this.contentTopInset())
        if (this.results.length === 0) {
          Text(this.isLoading ? this.t('searching_sources') : this.t('no_results'))
            .fontSize(14)
            .fontColor(this.secondaryText())
            .width('100%')
            .padding(12)
            .backgroundColor(this.cardBg())
            .borderRadius(10)
        } else {
          ForEach(this.results, (item: SearchResultItem) => { this.ResultListCard(item) }, (item: SearchResultItem) => item.url)
        }
        Blank().height(this.contentBottomInset())
      }.width('100%').padding({ left: 14, right: 14 })
    }
    .layoutWeight(1)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .backgroundColor(this.appBg())
  }

  @Builder
  private ChaptersPage() {
    Stack() {
      Scroll(this.chapterScroller) {
        Column() {
          Blank().height(this.headerOverlayHeight())
          if (this.detailLoading) {
            Column({ space: 6 }) {
              Progress({ value: this.detailTotalBytes > 0
                ? Math.min(100, Math.floor(this.detailReceivedBytes * 100 / this.detailTotalBytes)) : 0,
                total: 100, type: ProgressType.Linear }).width('100%').height(6).color(this.accent())
              Text(this.detailProgressText()).fontSize(12).fontColor(this.secondaryText()).width('100%')
            }.width('100%').padding({ left: 14, right: 14, bottom: 10 })
          }
          if (this.chapters.length === 0) {
            Text(this.t('no_chapters')).fontSize(14).fontColor(this.secondaryText()).width('100%').padding(12).backgroundColor(this.cardBg()).borderRadius(10)
          } else {
            ForEach(this.displayedChapters(), (chapter: ChapterItem) => {
              Row() {
                Text(chapter.title.trim().length > 0 ? chapter.title : this.t('chapter_list') + ' ' + chapter.index)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.primaryText())
                  .layoutWeight(1)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .padding(12)
              .backgroundColor(this.cardBg())
              .borderRadius(10)
              .margin({ bottom: 8 })
              .onClick(() => this.loadChapter(chapter, this.findRule(chapter.sourceId)))
            }, (chapter: ChapterItem) => chapter.url)
          }
        }.width('100%').padding({ left: 14, right: 14, bottom: 14 })
      }.width('100%').height('100%').edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })

      Column() {
        Blank().height(this.avoidStatusBarHeight)
        Row() {
          Column() { Image($rawfile('ic_back.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_back'))) }
            .padding({ left: 12, right: 8, top: 6, bottom: 6 }).onClick(() => { this.mode = 'results'; })
          Text(this.currentTitle.length > 0 ? this.currentTitle : this.t('chapter_list'))
            .fontSize(19).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).layoutWeight(1)
            .margin({ left: 6 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.chapterReversed ? this.t('chapter_ascending') : this.t('chapter_descending'))
            .fontSize(13).fontColor(this.accent()).padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .border({ width: 1, color: this.accent() }).borderRadius(14)
            .onClick(() => { this.chapterReversed = !this.chapterReversed; this.persistData(); })
          Column() { Image($rawfile('ic_add_shelf.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_add_shelf'))) }
            .padding({ left: 8, right: 12, top: 6, bottom: 6 }).onClick(() => this.addCurrentToShelf())
        }.width('100%').padding({ left: 4, right: 4, top: 10, bottom: 8 })
      }.width('100%').height(this.headerOverlayHeight())
        .position({ x: 0, y: 0 })
        .linearGradient({ angle: 180, colors: this.headerGradientColors() })
    }
    .width('100%').height('100%')
    .backgroundColor(this.appBg())
  }

  @Builder
  private ReaderPage() {
    Stack() {
      Scroll() {
        Column() {
          ForEach(this.displayedReaderImages(), (item: ReaderImageItem) => {
            Column() {
              if (this.showImageIndex && item.status === 'error') {
                Text('#' + item.index + ' · ' + this.t('image_failed'))
                  .fontSize(11)
                  .fontColor(this.secondaryText())
                  .padding({ top: 4, bottom: 4 })
              }
              Image(item.url)
                .width('100%')
                .objectFit(ImageFit.Contain)
                .backgroundColor(this.readerDarkMode ? '#111111' : '#FFFFFF')
                .onComplete(() => this.markImage(item.index, 'ok'))
                .onError(() => this.markImage(item.index, 'error'))
            }.width('100%')
          }, (item: ReaderImageItem) => item.url + item.index)
        }.width('100%')
      }
      .layoutWeight(1)
      .backgroundColor(this.readerDarkMode ? '#050505' : this.appBg())
      .onReachEnd(() => { this.loadNextChapterIfReady(); })
      .onClick(() => {
        if (this.floatingReaderControls) this.readerToolsVisible = !this.readerToolsVisible;
      })

      if (!this.fullscreenReader) {
        Column() {}
          .width('100%').height(this.avoidStatusBarHeight + 58)
          .position({ x: 0, y: 0 })
          .linearGradient({ angle: 180, colors: this.headerGradientColors() })
          .hitTestBehavior(HitTestMode.Transparent)
      }

      if (this.readerToolsVisible && this.floatingReaderControls) {
        Column() {
          Row() {
            Column() {
              Image($rawfile('ic_back.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_back')))
            }.width(42).height(42).justifyContent(FlexAlign.Center).borderRadius(21)
              .hitTestBehavior(HitTestMode.Block)
              .backgroundColor(this.isDark() ? '#481E232F' : '#5AFFFFFF')
              .linearGradient({ angle: 145, colors: this.readerControlGradient() })
              .border({ width: 1, color: this.borderSubtle() })
              .shadow({ radius: 8, color: '#28000000', offsetY: 3 })
              .onClick(() => { this.applyReaderFullscreen(false); this.mode = this.chapters.length > 0 ? 'chapters' : 'results'; })
            Text(this.currentChapterTitle.length > 0 ? this.currentChapterTitle : this.currentTitle)
              .fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).layoutWeight(1)
              .margin({ left: 10, right: 10 }).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
            Column() {
              Image($rawfile('ic_fullscreen.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_fullscreen')))
            }.width(42).height(42).justifyContent(FlexAlign.Center).borderRadius(21)
              .hitTestBehavior(HitTestMode.Block)
              .backgroundColor(this.isDark() ? '#481E232F' : '#5AFFFFFF')
              .linearGradient({ angle: 145, colors: this.readerControlGradient() })
              .border({ width: 1, color: this.borderSubtle() })
              .shadow({ radius: 8, color: '#28000000', offsetY: 3 })
              .onClick(() => this.applyReaderFullscreen(!this.fullscreenReader))
          }
          .width('100%').padding({ left: 10, right: 10, top: this.avoidStatusBarHeight + 8 })

          Blank()

          Row({ space: 8 }) {
            Text(this.t('previous_chapter')).fontSize(13).fontColor(this.hasRelativeChapter(-1) ? this.iconColor('ic_back') : this.secondaryText()).layoutWeight(1).textAlign(TextAlign.Center).padding({ top: 11, bottom: 11 }).borderRadius(20).border({ width: 1, color: this.hasRelativeChapter(-1) ? this.iconColor('ic_back') : this.borderSubtle() }).backgroundColor(this.isDark() ? '#381E232F' : '#48FFFFFF').linearGradient({ angle: 145, colors: this.readerControlGradient() }).shadow({ radius: 7, color: '#22000000', offsetY: 2 }).onClick(() => this.loadRelativeChapter(-1))
            Text(this.t('chapter_list')).fontSize(13).fontColor(this.iconColor('ic_layout')).layoutWeight(1).textAlign(TextAlign.Center).padding({ top: 11, bottom: 11 }).borderRadius(20).border({ width: 1, color: this.iconColor('ic_layout') }).backgroundColor(this.isDark() ? '#381E232F' : '#48FFFFFF').linearGradient({ angle: 145, colors: this.readerControlGradient() }).shadow({ radius: 7, color: '#22000000', offsetY: 2 }).onClick(() => { this.readerChapterPanelVisible = true; })
            Text(this.isCurrentFavorite() ? '♥' : '♡').fontSize(27).fontColor(this.iconColor('ic_add_shelf')).width(48).height(42).textAlign(TextAlign.Center).borderRadius(21).border({ width: 1, color: this.iconColor('ic_add_shelf') }).backgroundColor(this.isDark() ? '#381E232F' : '#48FFFFFF').linearGradient({ angle: 145, colors: this.readerControlGradient() }).shadow({ radius: 7, color: '#22000000', offsetY: 2 }).onClick(() => this.toggleCurrentFavorite())
            Text(this.t('next_chapter')).fontSize(13).fontColor(this.hasRelativeChapter(1) ? this.iconColor('ic_reader') : this.secondaryText()).layoutWeight(1).textAlign(TextAlign.Center).padding({ top: 11, bottom: 11 }).borderRadius(20).border({ width: 1, color: this.hasRelativeChapter(1) ? this.iconColor('ic_reader') : this.borderSubtle() }).backgroundColor(this.isDark() ? '#381E232F' : '#48FFFFFF').linearGradient({ angle: 145, colors: this.readerControlGradient() }).shadow({ radius: 7, color: '#22000000', offsetY: 2 }).onClick(() => this.loadRelativeChapter(1))
          }.width('100%').padding({ left: 10, right: 10, bottom: 10 })
        }.width('100%').height('100%').hitTestBehavior(HitTestMode.Transparent)
      }

      if (this.readerChapterPanelVisible) {
        Row() {
          Scroll() {
            Column() {
              ForEach(this.readerPanelChapters(), (chapter: ChapterItem) => {
                Text(chapter.title.trim().length > 0 ? chapter.title : this.t('chapter_list') + ' ' + chapter.index)
                  .fontSize(14)
                  .fontColor(chapter.url === this.currentUrl ? this.iconColor('ic_reader') : this.primaryText())
                  .width('100%').maxLines(2).padding({ top: 11, bottom: 11 })
                  .border({ width: { bottom: 1 }, color: this.borderSubtle() })
                  .onClick(() => { this.readerChapterPanelVisible = false; this.loadChapter(chapter, this.findRule(chapter.sourceId)); })
              }, (chapter: ChapterItem) => chapter.url)
            }.width('100%').padding({ left: 16, right: 16, top: this.avoidStatusBarHeight + 12, bottom: 24 })
          }
          .width('38%').height('100%')
          .backgroundColor(this.isDark() ? '#701E232F' : '#78FFFFFF')
          .linearGradient({ angle: 125, colors: this.readerPanelGradient() })
          .border({ width: { right: 1 }, color: this.borderSubtle() })
          .shadow({ radius: 14, color: '#30000000', offsetX: 4 })
          Blank().layoutWeight(1).height('100%').onClick(() => { this.readerChapterPanelVisible = false; })
        }.width('100%').height('100%')
      }
    }
    .width('100%').height('100%')
  }

  @Builder
  private SectionLabel(title: string) {
    Text(title)
      .fontSize(14)
      .fontColor(this.secondaryText())
      .fontWeight(FontWeight.Medium)
      .width('100%')
      .padding({ left: 4 })
      .margin({ top: 18, bottom: 8 })
  }

  @Builder
  private LinkRow(icon: string, label: string, value: string, showTopBorder: boolean) {
    Row({ space: 12 }) {
      Stack() {
        Image($rawfile(icon + '.svg')).width(20).height(20)
          .colorFilter(createStrokeIconColorFilter(this.iconColor(icon)))
      }.width(34).height(34)
      Column({ space: 4 }) {
        Text(label).fontSize(16).fontColor(this.primaryText()).width('100%')
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      Text(value).fontSize(13).fontColor(this.secondaryText()).textAlign(TextAlign.End)
      Image($rawfile('ic_more.svg')).width(16).height(16)
        .colorFilter(createStrokeIconColorFilter(this.iconColor('ic_more')))
    }
    .width('100%')
    .height(56)
    .border(showTopBorder ? { width: { top: 1 }, color: this.borderSubtle() } : { width: 0 })
  }

  @Builder
  private ToggleSettingRow(icon: string, label: string, isOn: boolean, showTopBorder: boolean) {
    Row({ space: 12 }) {
      Stack() {
        Image($rawfile(icon + '.svg')).width(20).height(20)
          .colorFilter(createStrokeIconColorFilter(this.iconColor(icon)))
      }.width(34).height(34)
      Text(label).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor(this.accent())
        .switchPointColor('#FFFFFF')
        .constraintSize({ maxHeight: 32 })
    }
    .width('100%')
    .height(56)
    .border(showTopBorder ? { width: { top: 1 }, color: this.borderSubtle() } : { width: 0 })
  }

  @Builder
  private ThemeOptionRow(mode: string, label: string, showTopBorder: boolean) {
    Row({ space: 10 }) {
      Stack() {
        Circle().width(20).height(20).fill(Color.Transparent).stroke(this.appTheme === mode ? this.accent() : this.secondaryText()).strokeWidth(2)
        if (this.appTheme === mode) {
          Circle().width(12).height(12).fill(this.accent())
        }
      }.width(20).height(20)
      Text(label).fontSize(16).fontColor(this.appTheme === mode ? this.accent() : this.primaryText()).layoutWeight(1)
    }
    .width('100%')
    .height(50)
    .border(showTopBorder ? { width: { top: 1 }, color: this.borderSubtle() } : { width: 0 })
    .onClick(() => {
      if (this.appTheme !== mode) {
        this.appTheme = mode;
        this.updateSystemBarColors();
        AppStorage.setOrCreate<number>('uiVersion', Date.now());
        this.statusText = this.t('theme_switched');
        this.persistData();
      }
      this.themeDialogVisible = false;
    })
  }

  @Builder
  private IconColorOptionRow(mode: string, showTopBorder: boolean) {
    Row({ space: 10 }) {
      if (mode === 'colorful') {
        Row({ space: 1 }) {
          Circle().width(5).height(18).fill('#FF3B30')
          Circle().width(5).height(18).fill('#F5C400')
          Circle().width(5).height(18).fill('#00C7BE')
          Circle().width(5).height(18).fill('#5856D6')
          Circle().width(5).height(18).fill('#FF2D92')
        }.width(30).height(20)
      } else {
        Circle().width(20).height(20).fill(this.iconModeColor(mode)).margin({ left: 5, right: 5 })
      }
      Text(this.t('icon_color_' + mode)).fontSize(16)
        .fontColor(this.iconColorMode === mode ? this.accent() : this.primaryText()).layoutWeight(1)
      if (this.iconColorMode === mode) {
        Image($rawfile('ic_check.svg')).width(18).height(18)
          .colorFilter(createStrokeIconColorFilter(this.accent()))
      }
    }
    .width('100%')
    .height(46)
    .border(showTopBorder ? { width: { top: 1 }, color: this.borderSubtle() } : { width: 0 })
    .onClick(() => {
      this.iconColorMode = mode;
      AppStorage.setOrCreate<number>('uiVersion', Date.now());
      this.persistData();
      this.settingsDialog = '';
    })
  }

  @Builder
  private LanguageOptionRow(mode: string, label: string, showTopBorder: boolean) {
    Row({ space: 10 }) {
      Stack() {
        Circle().width(20).height(20).fill(Color.Transparent).stroke(this.appLanguage === mode ? this.accent() : this.secondaryText()).strokeWidth(2)
        if (this.appLanguage === mode) {
          Circle().width(12).height(12).fill(this.accent())
        }
      }.width(20).height(20)
      Text(label).fontSize(16).fontColor(this.appLanguage === mode ? this.accent() : this.primaryText()).layoutWeight(1)
    }
    .width('100%')
    .height(50)
    .border(showTopBorder ? { width: { top: 1 }, color: this.borderSubtle() } : { width: 0 })
    .onClick(() => {
      this.appLanguage = mode;
      this.refreshCatalogLanguageFilter();
      AppStorage.setOrCreate<number>('uiVersion', Date.now());
      this.languageDialogVisible = false;
      this.persistData();
    })
  }

  @Builder
  private SettingCard(title: string, desc: string, value: string) {
    Row() {
      Column() {
        Text(title).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).width('100%')
        Text(desc).fontSize(12).fontColor(this.secondaryText()).lineHeight(18).margin({ top: 5 }).width('100%')
      }.layoutWeight(1)
      Text(value).fontSize(12).fontColor(this.secondaryText()).margin({ left: 10 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.cardBg())
    .borderRadius(18)
    .margin({ bottom: 10 })
  }

  @Builder
  private InfoRow(title: string, value: string) {
    Row() {
      Text(title).fontSize(15).fontColor(this.primaryText()).layoutWeight(1)
      Text(value).fontSize(13).fontColor(this.secondaryText()).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
    }.width('100%').padding({ top: 8, bottom: 8 })
  }

  @Builder
  private SettingsPage() {
    Stack() {
      Scroll() {
        Column() {
          Blank().height(this.contentTopInset())

          this.SectionLabel(this.t('basic_settings'))
          Column({ space: 0 }) {
            Column() { this.LinkRow('ic_moon', this.t('theme'), this.themeDisplay(), false) }.onClick(() => { this.themeDialogVisible = true; })
            Column() { this.LinkRow('ic_language', this.t('language'), this.languageDisplay(), true) }.onClick(() => { this.languageDialogVisible = true; })
            Column() { this.ToggleSettingRow('ic_fullscreen', this.t('reader_fullscreen'), this.fullscreenReader, true) }.onClick(() => { this.fullscreenReader = !this.fullscreenReader; this.persistData(); })
            Column() { this.ToggleSettingRow('ic_layout', this.t('floating_controls'), this.floatingReaderControls, true) }.onClick(() => { this.floatingReaderControls = !this.floatingReaderControls; this.persistData(); })
            Column() { this.LinkRow('ic_theme', this.t('icon_color'), this.iconColorModeDisplay(), true) }.onClick(() => { this.settingsDialog = 'icons'; })
          }.width('100%').padding({ left: 18, right: 18 }).backgroundColor(this.cardBg()).borderRadius(18)

          this.SectionLabel(this.t('app_settings'))
          Column({ space: 0 }) {
            Column() { this.LinkRow('ic_search', this.t('search_menu'), this.searchModeDisplay() + ' · ' + this.selectedEngine().name, false) }.onClick(() => { this.settingsDialog = 'search'; })
            Column() { this.LinkRow('ic_filter', this.t('source_switch'), this.enableSearchEngines ? this.t('enabled') : this.t('disabled'), true) }.onClick(() => { this.settingsDialog = 'sources'; })
            Column() { this.LinkRow('ic_reading', this.t('display_reading'), this.t('reading_settings'), true) }.onClick(() => { this.settingsDialog = 'reader'; })
            Column() { this.LinkRow('ic_engine', this.t('search_engine'), this.selectedEngine().name, true) }.onClick(() => { this.settingsDialog = 'engines'; })
            Column() { this.LinkRow('ic_rule', this.t('rule_settings'), this.remoteRuleCount + this.t('rules_unit'), true) }.onClick(() => { this.settingsDialog = 'rules'; })
            Column() { this.LinkRow('ic_code', this.t('advanced_rules'), this.rules.length + this.t('sources_unit'), true) }.onClick(() => { this.settingsDialog = 'advanced'; })
          }.width('100%').padding({ left: 18, right: 18 }).backgroundColor(this.cardBg()).borderRadius(18)

          this.SectionLabel(this.t('data_update'))
          Column({ space: 0 }) {
            Column() { this.LinkRow('ic_refresh', this.t('data_update'), '', false) }.onClick(() => { this.updateDialogVisible = true; })
          }.width('100%').padding({ left: 18, right: 18 }).backgroundColor(this.cardBg()).borderRadius(18)

          this.SectionLabel(this.t('about'))
          Column({ space: 0 }) {
            Row({ space: 12 }) {
              Image($rawfile('ic_eye.svg')).width(20).height(20)
                .colorFilter(createStrokeIconColorFilter(this.iconColor('ic_eye')))
              Text(this.t('debug_keep_screen_on')).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.debugKeepScreenOn })
                .selectedColor(this.accent())
                .switchPointColor('#FFFFFF')
            }.width('100%').height(50).onClick(() => { this.toggleDebugKeepScreenOn(); })
            Divider().color(this.borderSubtle()).width('100%').padding({ left: 32 })
            Row({ space: 12 }) {
              Image($rawfile('ic_info.svg')).width(20).height(20)
                .colorFilter(createStrokeIconColorFilter(this.iconColor('ic_info')))
              Text(this.t('version')).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
              Text(APP_VERSION).fontSize(13).fontColor(this.secondaryText())
            }.width('100%').height(50)
            Divider().color(this.borderSubtle()).width('100%').padding({ left: 32 })
            Row({ space: 12 }) {
              Image($rawfile('ic_clock.svg')).width(20).height(20)
                .colorFilter(createStrokeIconColorFilter(this.iconColor('ic_clock')))
              Text(this.t('build_time')).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
              Text(APP_BUILD_TIME).fontSize(13).fontColor(this.secondaryText())
            }.width('100%').height(50)
          }.width('100%').padding({ left: 18, right: 18 }).backgroundColor(this.cardBg()).borderRadius(18)
          Blank().height(this.contentBottomInset())
        }.width('100%').padding(14)
      }.layoutWeight(1).edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      if (this.settingsDialog.length > 0) this.SettingsDialog()
      if (this.themeDialogVisible) this.ThemeDialog()
      if (this.languageDialogVisible) this.LanguageDialog()
      if (this.updateDialogVisible) this.UpdateDialog()
    }.layoutWeight(1).backgroundColor(this.appBg())
  }

  @Builder
  private DialogLinkRow(label: string, value: string, showTopBorder: boolean) {
    Row() {
      Text(label).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
      Text(value).fontSize(13).fontColor(this.secondaryText())
      Image($rawfile('ic_more.svg')).width(16).height(16)
        .colorFilter(createStrokeIconColorFilter(this.iconColor('ic_more'))).margin({ left: 4 })
    }
    .width('100%')
    .height(50)
    .border(showTopBorder ? { width: { top: 1 }, color: this.borderSubtle() } : { width: 0 })
  }

  @Builder
  private DialogToggleRow(label: string, isOn: boolean, showTopBorder: boolean) {
    Row() {
      Text(label).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor(this.accent())
        .switchPointColor('#FFFFFF')
        .constraintSize({ maxHeight: 32 })
    }
    .width('100%')
    .height(50)
    .border(showTopBorder ? { width: { top: 1 }, color: this.borderSubtle() } : { width: 0 })
  }

  @Builder
  private DialogHeader(title: string) {
    Row() {
      Text(title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.primaryText())
        .layoutWeight(1)
      Image($rawfile('ic_close.svg')).width(20).height(20)
        .colorFilter(createStrokeIconColorFilter(this.iconColor('ic_close'))).onClick(() => { this.settingsDialog = ''; })
    }.width('100%').margin({ bottom: 8 })
  }

  @Builder
  private SettingsDialog() {
    Column() {
      Column({ space: 16 }) {
        if (this.settingsDialog === 'search') {
          this.DialogHeader(this.t('search_menu'))
          Column({ space: 0 }) {
            Column() { this.DialogLinkRow(this.t('search_mode'), this.searchModeDisplay(), false) }.onClick(() => this.nextSearchMode())
            Column() { this.DialogLinkRow(this.t('current_engine'), this.selectedEngine().name, true) }.onClick(() => this.cycleEngine())
            Column() { this.DialogToggleRow(this.t('all_engines'), this.searchAllEngines, true) }.onClick(() => { this.searchAllEngines = !this.searchAllEngines; })
            Column() { this.DialogLinkRow(this.t('language_pref'), this.languageModeDisplay(), true) }.onClick(() => this.nextLanguageMode())
          }.width('100%').padding({ left: 4, right: 4 }).backgroundColor(this.cardBg()).borderRadius(18)
          TextInput({ placeholder: this.t('extra_terms'), text: this.extraSearchTerms }).height(42).fontColor(this.primaryText()).placeholderColor(this.secondaryText()).backgroundColor(this.inputBg()).borderRadius(12).padding({ left: 10, right: 10 }).onChange((value: string) => { this.extraSearchTerms = value; })
          TextInput({ placeholder: this.t('site_hint'), text: this.siteHint }).height(42).fontColor(this.primaryText()).placeholderColor(this.secondaryText()).backgroundColor(this.inputBg()).borderRadius(12).padding({ left: 10, right: 10 }).onChange((value: string) => { this.siteHint = value; })
        } else if (this.settingsDialog === 'sources') {
          this.DialogHeader(this.t('source_switch'))
          Column({ space: 0 }) {
            Column() { this.DialogToggleRow(this.t('search_engine'), this.enableSearchEngines, false) }.onClick(() => { this.enableSearchEngines = !this.enableSearchEngines; })
            Column() { this.DialogToggleRow(this.t('html_rules'), this.enableHtmlRules, true) }.onClick(() => { this.enableHtmlRules = !this.enableHtmlRules; })
            Column() { this.DialogLinkRow(this.t('remote_rules'), this.remoteRuleCount + this.t('rules_unit'), true) }.onClick(() => this.updateRemoteRules())
          }.width('100%').padding({ left: 4, right: 4 }).backgroundColor(this.cardBg()).borderRadius(18)
          Text(this.remoteRuleStatus).fontSize(12).fontColor(this.secondaryText()).width('100%')
        } else if (this.settingsDialog === 'icons') {
          this.DialogHeader(this.t('icon_color'))
          Column({ space: 0 }) {
            this.IconColorOptionRow('colorful', false)
            this.IconColorOptionRow('red', true)
            this.IconColorOptionRow('orange', true)
            this.IconColorOptionRow('yellow', true)
            this.IconColorOptionRow('green', true)
            this.IconColorOptionRow('cyan', true)
            this.IconColorOptionRow('blue', true)
            this.IconColorOptionRow('indigo', true)
            this.IconColorOptionRow('violet', true)
            this.IconColorOptionRow('magenta', true)
          }.width('100%').padding({ left: 4, right: 4 }).backgroundColor(this.cardBg()).borderRadius(18)
        } else if (this.settingsDialog === 'reader') {
          this.DialogHeader(this.t('display_reading'))
          Column({ space: 0 }) {
            Column() { this.DialogToggleRow(this.t('auto_cover'), this.autoCoverEnabled, false) }.onClick(() => { this.autoCoverEnabled = !this.autoCoverEnabled; })
            Column() { this.DialogToggleRow(this.t('show_page_num'), this.showImageIndex, true) }.onClick(() => { this.showImageIndex = !this.showImageIndex; })
            Column() { this.DialogLinkRow(this.t('reading_bg'), this.readerDarkMode ? this.t('dark_color') : this.t('light_color'), true) }.onClick(() => { this.readerDarkMode = !this.readerDarkMode; })
            Column() { this.DialogLinkRow(this.t('max_results'), this.maxSearchResults + this.t('items_unit'), true) }.onClick(() => {
              this.maxSearchResults = this.maxSearchResults === 40 ? 80 : (this.maxSearchResults === 80 ? 160 : 40);
            })
            Column() { this.DialogLinkRow(this.t('chapter_pages'), this.maxReaderPages + this.t('pages_unit'), true) }.onClick(() => { this.maxReaderPages = this.maxReaderPages === 30 ? 50 : 30; })
          }.width('100%').padding({ left: 4, right: 4 }).backgroundColor(this.cardBg()).borderRadius(18)
        } else if (this.settingsDialog === 'engines') {
          this.DialogHeader(this.t('search_engine'))
          Column({ space: 0 }) {
            Column() { this.DialogLinkRow(this.t('current_engine'), this.selectedEngine().name, false) }.onClick(() => this.cycleEngine())
            ForEach(this.searchEngines, (engine: SearchEngineConfig, index: number) => {
              Column() { this.DialogToggleRow(engine.name, engine.enabled, index > 0 || true) }.onClick(() => { engine.enabled = !engine.enabled; })
            }, (engine: SearchEngineConfig) => engine.id)
          }.width('100%').padding({ left: 4, right: 4 }).backgroundColor(this.cardBg()).borderRadius(18)
        } else if (this.settingsDialog === 'rules') {
          this.DialogHeader(this.t('rule_settings'))
          Column({ space: 0 }) {
            Column() { this.DialogLinkRow(this.t('remote_count'), this.remoteRuleCount + this.t('rules_unit'), false) }.onClick(() => this.updateRemoteRules())
          }.width('100%').padding({ left: 4, right: 4 }).backgroundColor(this.cardBg()).borderRadius(18)
          TextInput({ placeholder: this.t('remote_url'), text: this.remoteRuleUrl }).height(42).fontColor(this.primaryText()).placeholderColor(this.secondaryText()).backgroundColor(this.inputBg()).borderRadius(12).padding({ left: 10, right: 10 }).onChange((value: string) => { this.remoteRuleUrl = value; })
          Text(this.remoteRuleStatus).fontSize(12).fontColor(this.secondaryText()).width('100%')
        } else {
          this.DialogHeader(this.t('advanced_rules'))
          TextInput({ placeholder: this.t('custom_json'), text: this.customRuleText }).height(120).fontColor(this.primaryText()).placeholderColor(this.secondaryText()).backgroundColor(this.inputBg()).borderRadius(12).padding(10).onChange((value: string) => { this.customRuleText = value; })
          Button(this.t('enabled'))
            .width('100%')
            .height(42)
            .fontSize(15)
            .fontColor('#FFFFFF')
            .backgroundColor(this.actionBg())
            .borderRadius(12)
            .margin({ top: 10 })
            .onClick(() => this.applyCustomRule())
        }
      }
      .width('85%')
      .padding(24)
      .backgroundColor(this.appBg())
      .borderRadius(16)
      .shadow({ radius: 20, color: '#18000000', offsetX: 0, offsetY: 4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.dialogOverlay())
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.settingsDialog = ''; })
  }

  @Builder
  private ThemeDialog() {
    Column() {
      Column({ space: 20 }) {
        Row() {
          Text(this.t('theme'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.primaryText())
          Blank()
          Image($rawfile('ic_close.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_close'))).onClick(() => { this.themeDialogVisible = false; })
        }.width('100%')
        Column({ space: 0 }) {
          this.ThemeOptionRow('light', this.t('light'), false)
          this.ThemeOptionRow('dark', this.t('dark'), true)
          this.ThemeOptionRow('system', this.t('follow_system'), true)
        }.width('100%')
      }
      .width('85%')
      .padding(24)
      .backgroundColor(this.cardBg())
      .borderRadius(16)
      .shadow({ radius: 20, color: '#18000000', offsetX: 0, offsetY: 4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.dialogOverlay())
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.themeDialogVisible = false; })
  }

  @Builder
  private LanguageDialog() {
    Column() {
      Column({ space: 20 }) {
        Row() {
          Text(this.t('language'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.primaryText())
          Blank()
          Image($rawfile('ic_close.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_close'))).onClick(() => { this.languageDialogVisible = false; })
        }.width('100%')
        Column({ space: 0 }) {
          this.LanguageOptionRow('system', this.t('follow_system'), false)
          this.LanguageOptionRow('zh', this.t('lang_zh'), true)
          this.LanguageOptionRow('en', this.t('lang_en'), true)
        }.width('100%')
      }
      .width('85%')
      .padding(24)
      .backgroundColor(this.cardBg())
      .borderRadius(16)
      .shadow({ radius: 20, color: '#18000000', offsetX: 0, offsetY: 4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.dialogOverlay())
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.languageDialogVisible = false; })
  }

  @Builder
  private UpdateDialog() {
    Column() {
      Column({ space: 20 }) {
        Row() {
          Text(this.t('data_update'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.primaryText())
          Blank()
          Image($rawfile('ic_close.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_close'))).onClick(() => { this.updateDialogVisible = false; })
        }.width('100%')
        Column({ space: 0 }) {
          Row() {
            Image($rawfile('ic_refresh.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_refresh'))).margin({ right: 10 })
            Text(this.t('update_all')).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
            if (this.updatingRules || this.updatingCatalog) {
              LoadingProgress().width(18).height(18).color(this.accent())
            }
          }.width('100%').height(50).onClick(() => { this.updateAll(); })
          Divider().color(this.borderSubtle()).width('100%').padding({ left: 32 })
          Row() {
            Image($rawfile('ic_rule.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_rule'))).margin({ right: 10 })
            Text(this.t('update_rules')).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
            if (this.updatingRules) {
              LoadingProgress().width(18).height(18).color(this.accent())
            } else {
              Text(this.remoteRuleCount + this.t('rules_unit')).fontSize(13).fontColor(this.secondaryText())
            }
          }.width('100%').height(50).onClick(() => { this.updateRemoteRules(); })
          Divider().color(this.borderSubtle()).width('100%').padding({ left: 32 })
          Row() {
            Image($rawfile('ic_shelf.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_shelf'))).margin({ right: 10 })
            Text(this.t('update_catalog')).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
            if (this.updatingCatalog) {
              LoadingProgress().width(18).height(18).color(this.accent())
            } else {
              Text(this.catalogUpdateAvailable
                ? this.catalogStage('有更新', 'Update available')
                : this.catalogCategories.length + this.t('items_unit'))
                .fontSize(13)
                .fontColor(this.catalogUpdateAvailable ? this.warnText() : this.secondaryText())
            }
          }.width('100%').height(50).onClick(() => { this.updateCatalog(); })
          if (this.updatingCatalog || this.catalogProgressPercent > 0) {
            Column({ space: 6 }) {
              Progress({ value: this.catalogProgressPercent, total: 100, type: ProgressType.Linear })
                .width('100%')
                .height(6)
                .color(this.accent())
              Text(this.catalogProgressText())
                .fontSize(12)
                .fontColor(this.secondaryText())
                .width('100%')
            }.width('100%').padding({ left: 30, right: 4, bottom: 8 })
          } else if (this.catalogUpdateStatus.length > 0) {
            Text(this.catalogUpdateStatus).fontSize(12).fontColor(this.secondaryText())
              .width('100%').padding({ left: 30, right: 4, bottom: 8 })
          }
        }.width('100%')
      }
      .width('85%')
      .padding(24)
      .backgroundColor(this.cardBg())
      .borderRadius(16)
      .shadow({ radius: 20, color: '#18000000', offsetX: 0, offsetY: 4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.dialogOverlay())
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.updateDialogVisible = false; })
  }

  @Builder
  private ShelfPage() {
    Scroll() {
      Column() {
        Blank().height(this.contentTopInset())

        if (this.catalogUpdateStatus.length > 0) {
          Row({ space: 8 }) {
            if (this.catalogCheckingOnline || this.catalogLoading || this.updatingCatalog) {
              LoadingProgress().width(18).height(18).color(this.accent())
            }
            Text(this.updatingCatalog ? this.catalogProgressText() : this.catalogUpdateStatus)
              .fontSize(12)
              .fontColor(this.secondaryText())
              .layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .margin({ left: 10, right: 10, bottom: 8 })
          .backgroundColor(this.cardBg())
          .borderRadius(12)
        }

        if (this.catalogLoading) {
          Column() {
            LoadingProgress().width(24).height(24).color(this.accent())
            Text(this.catalogUpdateStatus.length > 0 ? this.catalogUpdateStatus : (this.t('catalog_loading') ?? '加载目录中...')).fontSize(14).fontColor(this.secondaryText()).margin({ top: 8 })
          }.width('100%').height(200).justifyContent(FlexAlign.Center)
        } else if (this.catalogCategories.length > 0) {
          if (this.selectedCatalogCategory.length > 0 && this.catalogItems.length > 0) {
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
              ForEach(this.catalogItems, (item: CatalogItem) => {
                Column() {
                  Stack() {
                    if (this.catalogItemCover(item).length > 0) {
                      Image(this.catalogItemCover(item)).width('100%').height(140).objectFit(ImageFit.Cover).borderRadius({ topLeft: 12, topRight: 12 })
                    } else {
                      Column() {
                        Text(item.title.substring(0, 1)).fontSize(28).fontWeight(FontWeight.Bold).fontColor(this.accent())
                      }.width('100%').height(140).justifyContent(FlexAlign.Center).backgroundColor(this.coverPlaceholderBg()).borderRadius({ topLeft: 12, topRight: 12 })
                    }
                  }.width('100%').height(140).clip(true)

                  Text(item.title).fontSize(12).fontColor(this.colorfulValue(item.id)).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').padding({ left: 6, right: 6, top: 6, bottom: 6 })
                }
                .width('32%')
                .backgroundColor(this.cardBg())
                .borderRadius(12)
                .clip(true)
                .margin({ bottom: 8 })
                .onClick(() => {
                  const source = this.preferredCatalogSource(item);
                  if (source?.detailUrl) {
                    this.currentCover = source.coverUrl ? source.coverUrl : this.catalogItemCover(item);
                    this.loadDetail(source.detailUrl, item.title, this.findRuleByUrl(source.detailUrl));
                  } else if (source?.searchUrl) {
                    this.queryText = item.title;
                    this.activeTab = 'search';
                    this.startSearch();
                  }
                })
              }, (item: CatalogItem) => item.id)
            }
            .width('100%')
            .padding({ left: 10, right: 10, top: 4, bottom: 14 })
          } else {
            Column() {
              Text(this.t('select_category') ?? '选择分类浏览漫画').fontSize(14).fontColor(this.secondaryText()).margin({ top: 40 })
            }.width('100%').justifyContent(FlexAlign.Center)
          }
        } else {
          if (this.bookshelf.length === 0) {
            Text(this.t('shelf_empty')).fontSize(14).fontColor(this.secondaryText()).width('100%').padding(14).backgroundColor(this.cardBg()).borderRadius(16)
          } else {
            ForEach(this.bookshelf, (item: BookshelfItem) => {
              Column() { this.SettingCard(item.title, item.sourceName + ' · ' + item.lastReadAt, item.progressPercent + '%') }
                .onClick(() => this.loadDetail(item.url, item.title, this.findRule(item.sourceId)))
            }, (item: BookshelfItem) => item.url)
          }
        }
        Blank().height(this.contentBottomInset())
      }.width('100%').padding({ left: 10, right: 10 }).alignItems(HorizontalAlign.Start)
    }
    .layoutWeight(1)
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .backgroundColor(this.appBg())
  }

  private catalogItemCover(item: CatalogItem): string {
    for (let i = 0; i < item.sources.length; i++) {
      if (item.sources[i].coverUrl && item.sources[i].coverUrl!.length > 0) {
        return item.sources[i].coverUrl!;
      }
    }
    return '';
  }

  private preferredCatalogSource(item: CatalogItem): CatalogSource | null {
    let fallback: CatalogSource | null = null;
    for (let i = 0; i < item.sources.length; i++) {
      const source = item.sources[i];
      if (source.detailUrl && source.detailUrl.length > 0) {
        if (fallback === null) fallback = source;
        if (this.findRuleByUrl(source.detailUrl).id !== this.genericRule().id) return source;
      }
    }
    if (fallback !== null) return fallback;
    return item.sources.length > 0 ? item.sources[0] : null;
  }

  @Builder
  private HistoryPage() {
    Scroll() {
      Column() {
        Blank().height(this.contentTopInset())
        if (this.historyTab === 'history') {
          if (this.history.length === 0) {
            Text(this.t('history_empty')).fontSize(14).fontColor(this.secondaryText()).width('100%').padding(14).backgroundColor(this.cardBg()).borderRadius(16)
          } else if (this.historyViewMode === 'grid') {
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(this.history, (item: ReadingHistoryItem) => {
                Column() {
                  if (item.cover.length > 0) {
                    Image(item.cover).width('100%').height(140).borderRadius({ topLeft: 12, topRight: 12 }).objectFit(ImageFit.Cover)
                  } else {
                    Column() { Text(this.t('no_cover')).fontSize(11).fontColor(this.secondaryText()) }.width('100%').height(140).borderRadius({ topLeft: 12, topRight: 12 }).justifyContent(FlexAlign.Center).backgroundColor(this.cardBg())
                  }
                  Text(item.title).fontSize(12).fontColor(this.colorfulValue(item.title)).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').padding({ left: 6, right: 6, top: 4 })
                  Text(item.chapterTitle).fontSize(10).fontColor(this.secondaryText()).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').padding({ left: 6, right: 6, bottom: 6 })
                }.width('31.5%').margin({ bottom: 10 }).backgroundColor(this.cardBg()).borderRadius(12)
                  .onClick(() => this.openHistoryItem(item))
              }, (item: ReadingHistoryItem) => item.url)
            }.width('100%')
          } else {
            ForEach(this.history, (item: ReadingHistoryItem) => {
              Column() { this.SettingCard(item.title, item.chapterTitle + ' · ' + item.lastReadAt, item.imageCount + this.t('images_unit')) }
                .onClick(() => this.openHistoryItem(item))
            }, (item: ReadingHistoryItem) => item.url)
          }
        } else {
          if (this.bookshelf.length === 0) {
            Text(this.t('shelf_empty')).fontSize(14).fontColor(this.secondaryText()).width('100%').padding(14).backgroundColor(this.cardBg()).borderRadius(16)
          } else if (this.historyViewMode === 'grid') {
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
              ForEach(this.bookshelf, (item: BookshelfItem) => {
                Column() {
                  if (item.cover.length > 0) {
                    Image(item.cover).width('100%').height(140).borderRadius({ topLeft: 12, topRight: 12 }).objectFit(ImageFit.Cover)
                  } else {
                    Column() { Text(this.t('no_cover')).fontSize(11).fontColor(this.secondaryText()) }.width('100%').height(140).borderRadius({ topLeft: 12, topRight: 12 }).justifyContent(FlexAlign.Center).backgroundColor(this.cardBg())
                  }
                  Text(item.title).fontSize(12).fontColor(this.colorfulValue(item.title)).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').padding({ left: 6, right: 6, top: 4 })
                  Text(item.sourceName).fontSize(10).fontColor(this.secondaryText()).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').padding({ left: 6, right: 6, bottom: 6 })
                }.width('31.5%').margin({ bottom: 10 }).backgroundColor(this.cardBg()).borderRadius(12)
                  .onClick(() => this.loadDetail(item.url, item.title, this.findRule(item.sourceId)))
              }, (item: BookshelfItem) => item.url)
            }.width('100%')
          } else {
            ForEach(this.bookshelf, (item: BookshelfItem) => {
              Column() { this.SettingCard(item.title, item.sourceName + ' · ' + item.lastReadAt, item.progressPercent + '%') }
                .onClick(() => this.loadDetail(item.url, item.title, this.findRule(item.sourceId)))
            }, (item: BookshelfItem) => item.url)
          }
        }
        Blank().height(this.contentBottomInset())
      }.width('100%').padding({ left: 14, right: 14 })
    }.layoutWeight(1).edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true }).backgroundColor(this.appBg())
  }

  @Builder
  private UiIcon(name: string, size: number) {
    Image($rawfile(this.tabIconKey(name) + '.svg'))
      .width(size)
      .height(size)
      .colorFilter(createStrokeIconColorFilter(this.iconColor(this.tabIconKey(name))))
      .opacity(this.activeTab === name ? 1 : 0.68)
  }

  @Builder
  private TabPill(tab: string, label: string) {
    Column({ space: 3 }) {
      this.UiIcon(tab, 22)
      Text(label)
        .fontSize(11)
        .fontColor(this.activeTab === tab ? this.accent() : this.secondaryText())
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.End)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 4, bottom: 4 })
    .onClick(() => {
      this.activeTab = tab;
      if (tab === 'search' && this.mode === 'reader') this.mode = this.results.length > 0 ? 'results' : 'home';
    })
  }

  @Builder
  private BottomTabs() {
    Row() {
      this.TabPill('search', this.t('search'))
      this.TabPill('shelf', this.t('shelf'))
      this.TabPill('history', this.t('history'))
      this.TabPill('settings', this.t('settings'))
    }
    .width('100%')
    .height(56)
    .borderRadius(28)
    .backgroundColor(this.isDark() ? '#10000000' : '#18FFFFFF')
    .backgroundBlurStyle(BlurStyle.Thin, { colorMode: this.isDark() ? ThemeColorMode.DARK : ThemeColorMode.LIGHT, adaptiveColor: AdaptiveColor.AVERAGE })
    .border({ width: 1, color: this.isDark() ? '#18FFFFFF' : '#28FFFFFF' })
    .shadow({ radius: 8, color: '#18000000', offsetY: 3 })
  }

  private headerOverlayHeight(): number {
    return this.avoidStatusBarHeight + 64;
  }

  private contentTopInset(): number {
    return this.headerOverlayHeight();
  }

  private contentBottomInset(): number {
    return 80 + this.bottomSafeInset;
  }

  @Builder
  private HeaderOverlay() {
    Column() {
      Blank().height(this.avoidStatusBarHeight)
      if (this.activeTab === 'search' && this.mode === 'results') {
        Row() {
          Stack() {
            TextInput({ placeholder: this.t('search_placeholder'), text: this.queryText })
              .height(44)
              .fontSize(15)
              .fontColor(this.primaryText())
              .placeholderColor(this.secondaryText())
              .backgroundColor(Color.Transparent)
              .borderRadius(22)
              .border({ width: 1, color: this.secondaryText() })
              .padding({ left: 18, right: this.queryText.length > 0 ? 44 : 18 })
              .onChange((value: string) => { this.queryText = value; })
              .onSubmit(() => { this.startSearch(); })
            if (this.queryText.length > 0) {
              Row() {
                Column() {
                  Image($rawfile('ic_x.svg')).width(14).height(14).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_x')))
                }.width(32).height(32).justifyContent(FlexAlign.Center).margin({ right: 6 })
                  .onClick(() => { this.isLoading = false; this.queryText = ''; this.results = []; this.mode = 'home'; })
              }.width('100%').justifyContent(FlexAlign.End)
            }
          }.layoutWeight(1)
          Column() { this.SearchActionButton(44) }
            .margin({ left: 8 })
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      } else if (this.activeTab === 'shelf') {
        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.catalogCategories, (cat: CatalogCategory) => {
              Text(cat.name)
                .fontSize(14)
                .fontWeight(this.selectedCatalogCategory === cat.id ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.colorfulValue(cat.id))
                .maxLines(1)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .borderRadius(16)
                .border({ width: 1, color: this.selectedCatalogCategory === cat.id ? this.colorfulValue(cat.id) : this.borderSubtle() })
                .onClick(() => {
                  if (this.selectedCatalogCategory === cat.id) {
                    this.selectedCatalogCategory = '';
                    this.catalogItems = [];
                  } else {
                    this.selectedCatalogCategory = cat.id;
                    this.catalogItems = this.filteredCatalogItems(this.remoteCatalog!, cat.id);
                  }
                })
            }, (cat: CatalogCategory) => cat.id)
          }
          .padding({ left: 14, right: 14 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .backgroundColor(Color.Transparent)
      } else if (this.activeTab === 'history') {
        Row() {
          Row({ space: 16 }) {
            Text(this.t('history'))
              .fontSize(20)
              .fontWeight(this.historyTab === 'history' ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.historyTab === 'history' ? this.primaryText() : this.secondaryText())
              .onClick(() => { this.historyTab = 'history'; })
            Text(this.t('favorites'))
              .fontSize(20)
              .fontWeight(this.historyTab === 'favorites' ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.historyTab === 'favorites' ? this.primaryText() : this.secondaryText())
              .onClick(() => { this.historyTab = 'favorites'; })
          }.layoutWeight(1)
          Stack() {
            Image($rawfile('ic_more.svg')).width(22).height(22).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_more')))
              .onClick(() => { this.historyMenuVisible = !this.historyMenuVisible; })
            if (this.historyMenuVisible) {
              Column() {
                Row({ space: 8 }) {
                  Image($rawfile('ic_layout.svg')).width(16).height(16).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_layout')))
                  Text(this.t('list_view')).fontSize(14).fontColor(this.historyViewMode === 'list' ? this.accent() : this.primaryText())
                }.width('100%').height(44).padding({ left: 14, right: 14 }).onClick(() => { this.historyViewMode = 'list'; this.historyMenuVisible = false; })
                Row({ space: 8 }) {
                  Image($rawfile('ic_shelf.svg')).width(16).height(16).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_shelf')))
                  Text(this.t('grid_view')).fontSize(14).fontColor(this.historyViewMode === 'grid' ? this.accent() : this.primaryText())
                }.width('100%').height(44).padding({ left: 14, right: 14 }).onClick(() => { this.historyViewMode = 'grid'; this.historyMenuVisible = false; })
              }
              .width(140)
              .backgroundColor(this.cardBg())
              .borderRadius(12)
              .shadow({ radius: 12, color: '#30000000', offsetY: 4 })
              .border({ width: 1, color: this.borderSubtle() })
              .position({ x: -100, y: 36 })
            }
          }.width(36).height(36).alignContent(Alignment.Center)
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      } else if (this.activeTab === 'settings') {
        Row() {
          Image($rawfile('ic_settings.svg')).width(22).height(22).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_settings'))).margin({ right: 8 })
          Text(this.t('settings')).fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      } else {
        Column() {
          Text(this.mode === 'home' || this.mode === 'results' ? this.t('app_title') : this.t(this.activeTab))
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.primaryText())
            .width('100%')
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      }
    }
    .width('100%')
    .height(this.headerOverlayHeight())
    .linearGradient({ angle: 180, colors: this.headerGradientColors() })
  }

  build() {
    Stack() {
      ForEach([`${this.uiVersion}`], (_: string) => {
        Column() {
          if (this.activeTab === 'search') {
            if (this.mode === 'home') this.SearchHome()
            else if (this.mode === 'results') this.ResultsPage()
            else if (this.mode === 'chapters') this.ChaptersPage()
            else this.ReaderPage()
          } else if (this.activeTab === 'shelf') {
            this.ShelfPage()
          } else if (this.activeTab === 'history') {
            this.HistoryPage()
          } else {
            this.SettingsPage()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.appBg())

        if (this.mode !== 'reader' && this.mode !== 'chapters') {
          Column() {
            this.HeaderOverlay()
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Start)
          .backgroundColor(Color.Transparent)
          .hitTestBehavior(HitTestMode.Transparent)
        }

        if (this.mode !== 'reader' && this.mode !== 'chapters') {
          Column() {
            Blank()
            this.BottomTabs()
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.End)
          .padding({ left: 10, right: 10, bottom: Math.max(0, this.bottomSafeInset - 2) })
          .backgroundColor(Color.Transparent)
          .hitTestBehavior(HitTestMode.Transparent)
        }

        if (this.statusMessageVisible) {
          Column() { this.StatusMessageOverlay() }
            .width('100%').height('100%')
            .justifyContent(FlexAlign.End)
            .padding({ bottom: this.contentBottomInset() + 16 })
            .hitTestBehavior(HitTestMode.Transparent)
        }
      }, (item: string, index: number) => `${item}_${index}`)
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .id(`root_${this.uiVersion}`)
  }
}
