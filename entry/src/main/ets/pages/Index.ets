import webview from '@ohos.web.webview';
import { ComicSourceRule, SearchResultItem, ChapterItem, ReaderImageItem, ReadingHistoryItem, BookshelfItem, SearchEngineConfig, RemoteCatalog, CatalogCategory, CatalogItem, CatalogSource, CoverAccuracyIndex, CoverAccuracyEntry } from '../model/ComicModels';
import { DEFAULT_SOURCES, SEARCHABLE_COMIC_SOURCES, RULE_TEMPLATE, ruleForPublicUrl, VERIFIED_DOMAIN_COUNT, PUBLIC_ACCESS_DOMAIN_COUNT, isComicDomain } from '../common/SourceRules';
import { HttpClient } from '../common/HttpClient';
import { parseSearchResults, parseComicListingResults, parseChapters, parseChaptersFallback, parseImages, parseNextPageUrl } from '../common/HtmlParser';
import { looksLikeUrl, normalizeUserUrl } from '../common/UrlUtil';
import { DEFAULT_SEARCH_ENGINES, buildEngineQuery, buildSearchEngineUrl, parseSearchEngineResults, isEngineConfigured, engineHeaders, searchEngineUserAgent, searchFilterConfig, buildDebugMatchInfo, setSearchResultFilterMode } from '../common/SearchEngines';
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
import router from '@ohos.router';
import window from '@ohos.window';
import dataPreferences from '@ohos.data.preferences';
import util from '@ohos.util';
import fs from '@ohos.file.fs';
import inputMethod from '@ohos.inputMethod';
import pasteboard from '@ohos.pasteboard';
import { CodeEditorTheme, defaultEditorTheme, highlightLine, HighlightSegment,
  findSearchMatches, SearchMatch, formatJson, LineDataSource } from '../common/CodeEditor';

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
  @State private recentSearches: string[] = [];
  @State private searchHistoryVisible: boolean = false;
  @State private searchTitle: string = '';
  @State @Watch('onStatusTextChanged') private statusText: string = '';
  @State private statusMessageVisible: boolean = false;
  private statusMessageTimerId: number = -1;
  @State private rules: ComicSourceRule[] = DEFAULT_SOURCES;
  @State private onlineRules: ComicSourceRule[] = [];
  @State private advancedRules: ComicSourceRule[] = [];
  @State private blockedUrls: string[] = [];
  @State private editorMode: string = 'advanced';
  @State private editorScrollY: number = 0;
  @State private editorEditable: boolean = false;
  @State private editorLanguage: string = 'text';
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
  @State @Watch('onCatalogUpdateStatusChanged') private catalogUpdateStatus: string = '';
  @State private catalogCheckingOnline: boolean = false;
  @State private catalogUpdateAvailable: boolean = false;
  @State private catalogReceivedBytes: number = 0;
  @State private catalogTotalBytes: number = 0;
  @State private catalogProgressPercent: number = 0;
  @State private remoteCatalogItemCount: number = 0;
  @State private ruleProgressPercent: number = 0;
  @State private ruleProgressStatus: string = '';
  @State private ruleReceivedBytes: number = 0;
  @State private ruleTotalBytes: number = 0;
  @State private shelfPanOffset: number = 0;
  @State private shelfPanStartX: number = 0;
  @State private shelfIsPanning: boolean = false;
  @State private shelfViewportWidth: number = 360;
  @State private shelfAdjacentItems: CatalogItem[] = [];
  @State private shelfAdjacentDir: number = 0;
  @State private currentTitle: string = '';
  @State private currentUrl: string = '';
  @State private currentDetailUrl: string = '';
  @State private currentChapterTitle: string = '';
  @State private currentCatalogItemId: string = '';
  @State private currentCatalogSourceIndex: number = -1;
  @State private currentCover: string = '';
  @State private currentSourceId: string = '';
  @State private currentSourceName: string = '';
  @State private detailLoading: boolean = false;
  @State private detailReceivedBytes: number = 0;
  @State private detailTotalBytes: number = 0;
  @State @Watch('onLoadingChanged') private isLoading: boolean = false;
  @State private loadingAngle: number = 0;
  private loadingTimerId: number = -1;
  private scrollTimerId: number = -1;
  private webLoadTimerId: number = -1;
  private webLoadingTimeoutId: number = -1;
  private readerHintTimerId: number = -1;
  private focusTimerId: number = -1;
  private shelfCategoryTimerId: number = -1;
  private cachedReadingOrder: ChapterItem[] = [];
  private cachedDisplayedChapters: ChapterItem[] = [];
  private chaptersCacheDirty: boolean = true;
  private loadChapterGeneration: number = 0;
  private searchGeneration: number = 0;
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings);

  @State private searchMode: string = 'mixed';
  @State private searchAllEngines: boolean = true;
  @State private languageMode: string = 'chinese';
  @State private searchResultMode: string = 'rule_filter';
  @State private searchPage: number = 1;
  @State private hasMoreResults: boolean = false;
  @State private loadingMore: boolean = false;
  @State private searchEngineUrl: string = '';
  @State @Watch('onLoadingChanged') private webLoading: boolean = false;
  @State private webDarkOverlay: boolean = false;
  @State private webErrorText: string = '';
  @State private showReaderHint: boolean = false;
  private webController: webview.WebviewController = new webview.WebviewController();
  private webLastSuccessUrl: string = '';
  private webMainFrameFailed: boolean = false;
  private darkModeCssScript: string =
    "(function(){" +
    "var h=window.location.hostname.toLowerCase();" +
    "if(h.indexOf('bing.com')>=0||h.indexOf('baidu.com')>=0||h.indexOf('duckduckgo.com')>=0||h.indexOf('sogou.com')>=0||h.indexOf('yandex.com')>=0||h.indexOf('google.com')>=0||h.indexOf('so.com')>=0)return;" +
    "var s=document.createElement('style');" +
    "s.id='hw-dark-inject';" +
    "s.textContent='html,body,div,section,article,main,aside,nav,header,footer,figure,figcaption,table,tr,td,th,thead,tbody,tfoot,ul,ol,li,dl,dt,dd,p,blockquote,pre,code,form,fieldset,legend,label,option,optgroup,caption,h1,h2,h3,h4,h5,h6{background-color:#1a1a1a !important;color:#e0e0e0 !important;border-color:#333 !important;}a,a *{color:#4a9eff !important;}input,textarea,select,button{background-color:#2a2a2a !important;color:#e0e0e0 !important;border-color:#444 !important;}img,video,canvas{opacity:0.92;}';" +
    "document.documentElement.appendChild(s);" +
    "})();";
  private adBlockScript: string =
    "(function(){" +
    "var s=document.createElement('style');" +
    "s.id='hw-adblock';" +
    "s.textContent='" +
    "ins.adsbygoogle,[id*=\"google_ads\"],[id*=\"div-gpt-ad\"],[id*=\"div-gpt-ad-\"]," +
    "iframe[src*=\"doubleclick.net\"],iframe[src*=\"googlesyndication.com\"],iframe[src*=\"adserver\"],iframe[src*=\"adition\"]," +
    "iframe[src*=\"ad.\"],iframe[src*=\"/ad/\"],iframe[src*=\"_ad_\"],iframe[src*=\"adbanner\"]," +
    "[class*=\"float-ad\"],[class*=\"floatad\"],[class*=\"float_ad\"]," +
    "#coupletLeft,#coupletRight,#fixedAd,#floatAd,#ad_header,#ad_footer,#ad_top,#ad_bottom," +
    "#adContainer,#adBox,#ad_banner,#ad_area,#ad_zone,#ad_region,#ad-slot,#ad-unit," +
    "#ad-1,#ad-2,#ad-3,#ad-slot1,#ad-slot2,#ad-slot3," +
    "[class*=\"sticky-ad\"],[class*=\"fixed-ad\"],[class*=\"popup-ad\"],[class*=\"ad-popup\"],[class*=\"ad-modal\"]," +
    "[class*=\"ad-overlay\"],[id*=\"ad-overlay\"],[class*=\"ad-mask\"],[id*=\"ad-mask\"]," +
    "[class*=\"sponsored\"],[id*=\"sponsored\"],[class*=\"promotion-box\"],[class*=\"promo-ad\"]," +
    "[class*=\"ad-banner\"],[class*=\"ad-container\"],[class*=\"ad-wrapper\"],[class*=\"ad-slot\"],[class*=\"ad-unit\"]," +
    "[class*=\"banner-ad\"],[id*=\"banner-ad\"],[class*=\"ad-float\"],[id*=\"ad-float\"]," +
    "[class*=\"advertisement\"],[id*=\"advertisement\"]," +
    "[class*=\"ad-300\"],[class*=\"ad-728\"],[class*=\"ad-970\"]," +
    "[class*=\"ad-top\"],[class*=\"ad-bottom\"],[class*=\"ad-side\"],[class*=\"ad-left\"],[class*=\"ad-right\"]," +
    "[class*=\"top-ad\"],[class*=\"bottom-ad\"],[class*=\"side-ad\"],[class*=\"left-ad\"],[class*=\"right-ad\"]," +
    "[class*=\"ad-interstitial\"],[class*=\"ad-between\"],[class*=\"ad-inline\"]," +
    "[class*=\"ad-refresh\"],[class*=\"ad-show\"],[class*=\"ad-display\"],[class*=\"ad-view\"],[class*=\"ad-render\"]," +
    "[class*=\"adsbygoogle\"],[class*=\"ad-area\"],[class*=\"ad-zone\"],[class*=\"ad-region\"]," +
    "[class*=\"ad-refresh\"],[class*=\"ad-rect\"],[class*=\"ad-rectangle\"],[class*=\"ad-leaderboard\"]," +
    "[class*=\"dfp-ad\"],[id*=\"dfp-ad\"],[class*=\"adg-comp\"],[id*=\"adg-comp\"]," +
    "[data-ad],[data-ads],[data-ad-slot],[data-ad-unit],[data-ad-client]," +
    "[class*=\"commercial-unit\"],[id*=\"commercial-unit\"]," +
    "[class*=\"recommend-ad\"],[class*=\"hot-ad\"],[class*=\"trend-ad\"]," +
    "#ad1,#ad2,#ad3,#ad4,#ad5,#ad6,#ad7,#ad8,#ad9,#ad0," +
    ".topad,.bottomad,.leftad,.rightad,.adbox,.ad_box,.adarea,.ad_zone," +
    ".ad-banner,.ad-slot,.ad-unit,.ad-wrap,.ad-container,.ad-holder," +
    ".ads,.adsbox,.ad_box,.adblock,.ad_block,.adblockdiv," +
    ".gg_ad,.ggad,.google-ad,.googlead,.gad," +
    ".bd_ad,.bdad,.baidu-ad,.sogou-ad,.sogouad," +
    ".cm_ad,.cmad,.comic-ad,.comicad," +
    ".m-ad,.m_ad,.mobile-ad,.mobilead," +
    ".app-ad,.appad,.inapp-ad,.inappad" +
    "{display:none !important;}" +
    "';" +
    "document.documentElement.appendChild(s);" +
    "})();";
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
  @State private debugRuleTried: number = 0;
  @State private debugRuleSkipped: number = 0;
  @State private debugRuleSuccess: number = 0;
  @State private debugRuleFailed: number = 0;
  @State private debugEngineResults: number = 0;
  @State private debugEngineTried: number = 0;
  @State private debugEngineSuccess: number = 0;
  @State private debugSearchQueries: string = '';
  @State private customBlockedDomains: string = '';
  @State private customBlockedWords: string = '';
  @State private customNoiseWords: string = '';
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
  @State private readerZoomScale: number = 1;
  @State private readerPanX: number = 0;
  private readerZoomStartScale: number = 1;
  private readerPanStartX: number = 0;
  private readerViewportWidth: number = 0;
  private readerGestureEndedAt: number = 0;
  @State private appTheme: string = 'system';
  @State private appLanguage: string = 'zh';
  @StorageProp('systemColorMode') private systemColorMode: string = 'light';
  @StorageProp('uiVersion') @Watch('onUiVersionChanged') private uiRefresh: number = 0;
  @State private uiVersion: number = 0;
  @State private remoteRuleUrl: string = DEFAULT_REMOTE_RULE_URL;
  @State private remoteRuleStatus: string = '';
  @State private remoteRuleCount: number = 0;
  @State private coverAccuracyIndex: CoverAccuracyIndex | null = null;
  @State private coverAccuracyStatus: string = '';
  @State private updatingCoverAccuracy: boolean = false;
  @State private updatingCatalog: boolean = false;
  @State private updatingRules: boolean = false;
  @State private syncingFilterWords: boolean = false;
  @State private filterWordsStatus: string = '';
  @State private filterWordsProgressPercent: number = 0;
  @State private filterWordsReceivedBytes: number = 0;
  @State private filterWordsTotalBytes: number = 0;
  @State private updateDialogVisible: boolean = false;
  @State private customRuleText: string = RULE_TEMPLATE;
  @State private ruleViewerText: string = '';
  @State private ruleViewerTitle: string = '';
  @State private editorSearchVisible: boolean = false;
  @State private editorSearchQuery: string = '';
  @State private editorUseRegex: boolean = false;
  @State private editorCaseSensitive: boolean = false;
  @State private editorSearchMatches: SearchMatch[] = [];
  @State private editorCurrentMatch: number = -1;
  @State private editorIndentSize: number = 2;
  @State private editorUseTab: boolean = false;
  @State private editorShowIndent: boolean = false;
  @State private editorIsValid: boolean = true;
  @State private editorError: string = '';
  @State private editorCursorLine: number = 0;
  @State private editorThemeCache: CodeEditorTheme = defaultEditorTheme(false);
  @State private editorLinesCache: string[] = [];
  @State private editorSelectedLine: number = 0;
  @State private editorWordWrap: boolean = true;
  @State private editorCanUndo: boolean = false;
  @State private editorCanRedo: boolean = false;
  @State private editorLineNumberWidth: number = 12;
  @State private editorToolBarVisible: boolean = true;
  private editorToolBarHiddenByKeyboard: boolean = false;
  private editorUndoStack: string[] = [];
  private editorRedoStack: string[] = [];
  private editorLineDataSource: LineDataSource = new LineDataSource([]);
  private editorScroller: Scroller = new Scroller();
  @State private editorFullscreen: boolean = false;
  @State private editorTitle: string = '';
  @State private editorReadOnly: boolean = false;
  @State private editorMenuVisible: boolean = false;
  @State private editorSeekVisible: boolean = false;
  @State private editorSeekInput: string = '';
  @State private editorBookmarks: number[] = [];
  @State private editorCol: number = 0;
  @State private editorLinksVisible: boolean = false;
  @State private editorStatsVisible: boolean = false;
  @State private editorColorPickerVisible: boolean = false;
  @State private editorPreviewVisible: boolean = false;
  @State private editorLinksCache: string[] = [];
  @State private editorStatsLines: number = 0;
  @State private editorStatsWords: number = 0;
  @State private editorStatsChars: number = 0;
  @State private settingsDialog: string = '';
  @State private themeDialogVisible: boolean = false;
  @State private languageDialogVisible: boolean = false;
  @State private themeExpanded: boolean = false;
  @State private languageExpanded: boolean = false;
  @State private iconColorExpanded: boolean = false;
  @State private searchExpanded: boolean = false;
  @State private sourcesExpanded: boolean = false;
  @State private readerExpanded: boolean = false;
  @State private enginesExpanded: boolean = false;
  @State private rulesExpanded: boolean = false;
  @State private dlgSearchModeExpanded: boolean = false;
  @State private dlgLangExpanded: boolean = false;
  @State private dlgResultModeExpanded: boolean = false;
  @State private dlgReaderBgExpanded: boolean = false;
  @State private dlgMaxResultsExpanded: boolean = false;
  @State private dlgMaxPagesExpanded: boolean = false;
  @State private dlgEngineExpanded: boolean = false;
  @State private themeRowBottom: number = 0;
  @State private languageRowBottom: number = 0;
  @State private iconColorRowBottom: number = 0;
  @State private settingsStackTop: number = 0;
  @State private avoidStatusBarHeight: number = 0;
  @State private bottomSafeInset: number = 28;
  @State private debugKeepScreenOn: boolean = false;
  @State private showDebugInfo: boolean = false;
  @State private historyTab: string = 'history';
  @State private historyViewMode: string = 'grid';
  @State private historyMenuVisible: boolean = false;
  @State private shelfMenuVisible: boolean = false;
  @State private shelfDisplayMode: string = 'grid';
  @State private lastOpenedSearchUrl: string = '';
  @State private revealedDeleteUrl: string = '';
  @State private bookLongPressVisible: boolean = false;
  @State private bookLongPressTitle: string = '';
  @State private bookLongPressUrl: string = '';
  @State private bookLongPressCover: string = '';
  @State private bookLongPressIsFavorite: boolean = false;
  @State private bookLongPressSourceName: string = '';
  @State private bookLongPressX: number = 0;
  @State private bookLongPressY: number = 0;
  @State private isLongPressing: boolean = false;
  @State private historyPanOffset: number = 0;
  @State private historyPanStartX: number = 0;
  @State private historyViewportWidth: number = 360;

  private preferencesStore: dataPreferences.Preferences | null = null;
  private catalogCachePath: string = '';
  private ruleCachePath: string = '';
  private coverCacheDir: string = '';
  private coverAccuracyCachePath: string = '';
  private pendingCatalogVersion: string = '';
  private pendingCatalogUrl: string = '';
  private chapterScroller: Scroller = new Scroller();
  private searchResultsScroller: Scroller = new Scroller();
  private readerChapterScroller: Scroller = new Scroller();
  private searchFallbackCandidates: SearchResultItem[] = [];
  private searchFallbackIndex: number = -1;
  private searchFallbackDiscoveryAttempted: boolean = false;

  private returnToSearchResults(): void {
    this.mode = 'results';
    this.activeTab = 'search';
  }

  private openReaderChapterPanel(): void {
    this.readerChapterPanelVisible = true;
    const chapters = this.readerPanelChapters();
    const currentIndex = chapters.findIndex((chapter: ChapterItem) => chapter.url === this.currentUrl);
    if (currentIndex < 0) return;
    this.scrollTimerId = setTimeout(() => {
      this.readerChapterScroller.scrollToIndex(currentIndex, false, ScrollAlign.CENTER);
    }, 60);
  }

  private resetChapterScroll(): void {
    this.scrollTimerId = setTimeout(() => {
      this.chapterScroller.scrollEdge(Edge.Top);
    }, 0);
  }

  private scrollToCurrentChapter(): void {
    const chapters = this.displayedChapters();
    const currentIndex = chapters.findIndex((chapter: ChapterItem) => chapter.url === this.currentUrl);
    if (currentIndex < 0) return;
    this.scrollTimerId = setTimeout(() => {
      this.chapterScroller.scrollToIndex(currentIndex, false, ScrollAlign.CENTER);
    }, 100);
  }

  private async initPreferences(): Promise<void> {
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      this.coverCacheDir = context.filesDir + '/bookshelf_covers';
      this.ruleCachePath = context.filesDir + '/rules.zh-Hans.cache.json';
      this.coverAccuracyCachePath = context.filesDir + '/cover-accuracy.zh-Hans.cache.json';
      try { fs.mkdirSync(this.coverCacheDir, true); } catch (e) {}
      this.preferencesStore = await dataPreferences.getPreferences(context, 'comic_reader_store');
      await this.loadPersistedData();
      this.loadCachedRules();
      this.loadCachedCoverAccuracy();
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
        this.history = this.latestHistoryPerBook(this.history);
      }
      const shelfJson = await this.preferencesStore.get('bookshelf', '[]') as string;
      if (typeof shelfJson === 'string' && shelfJson.length > 2) {
        this.bookshelf = JSON.parse(shelfJson) as BookshelfItem[];
      }
      const advancedJson = await this.preferencesStore.get('advanced_rules', '[]') as string;
      if (typeof advancedJson === 'string' && advancedJson.length > 0) {
        try {
          const savedAdvanced = JSON.parse(advancedJson) as ComicSourceRule[];
          if (Array.isArray(savedAdvanced)) {
            this.advancedRules = savedAdvanced;
            this.customRuleText = JSON.stringify(this.advancedRules, null, 2);
            this.rebuildEffectiveRules();
          }
        } catch (advancedError) {
          this.advancedRules = [];
          this.customRuleText = '[]';
        }
      }
      const blockedJson = await this.preferencesStore.get('blocked_urls', '[]') as string;
      if (typeof blockedJson === 'string' && blockedJson.length > 0) {
        try {
          const savedBlocked = JSON.parse(blockedJson) as string[];
          if (Array.isArray(savedBlocked)) this.blockedUrls = savedBlocked;
        } catch (blockedError) {
          this.blockedUrls = [];
        }
      }
      const recentJson = await this.preferencesStore.get('recent_searches', '[]') as string;
      if (typeof recentJson === 'string' && recentJson.length > 2) this.recentSearches = JSON.parse(recentJson) as string[];
      const appTheme = await this.preferencesStore.get('app_theme', 'system') as string;
      if (typeof appTheme === 'string' && appTheme.length > 0) {
        this.appTheme = appTheme;
        this.updateSystemBarColors();
      }
      const appLanguage = await this.preferencesStore.get('app_language', 'zh') as string;
      if (typeof appLanguage === 'string' && appLanguage.length > 0) {
        this.appLanguage = appLanguage;
        this.refreshCatalogLanguageFilter();
      }
      this.debugKeepScreenOn = await this.preferencesStore.get('debug_keep_screen_on', false) as boolean;
      this.showDebugInfo = await this.preferencesStore.get('show_debug_info', false) as boolean;
      const savedIconMode = await this.preferencesStore.get('icon_color_mode', 'colorful') as string;
      this.iconColorMode = typeof savedIconMode === 'string' && savedIconMode.length > 0 ? savedIconMode : 'colorful';
      this.chapterReversed = await this.preferencesStore.get('chapter_reversed', true) as boolean;
      this.fullscreenReader = await this.preferencesStore.get('fullscreen_reader', true) as boolean;
      this.floatingReaderControls = await this.preferencesStore.get('floating_reader_controls', true) as boolean;
      const savedShelfDisplay = await this.preferencesStore.get('shelf_display_mode', 'grid') as string;
      if (typeof savedShelfDisplay === 'string' && savedShelfDisplay.length > 0) this.shelfDisplayMode = savedShelfDisplay;
      const savedBraveKey = await this.preferencesStore.get('brave_api_key', '') as string;
      if (typeof savedBraveKey === 'string') this.braveApiKey = savedBraveKey;
      const savedGoogleKey = await this.preferencesStore.get('google_api_key', '') as string;
      if (typeof savedGoogleKey === 'string') this.googleApiKey = savedGoogleKey;
      const savedGoogleCx = await this.preferencesStore.get('google_cx', '') as string;
      if (typeof savedGoogleCx === 'string') this.googleCx = savedGoogleCx;
      this.autoCoverEnabled = await this.preferencesStore.get('auto_cover_enabled', false) as boolean;
      const savedSearchMode = await this.preferencesStore.get('search_mode', 'mixed') as string;
      if (typeof savedSearchMode === 'string' && savedSearchMode.length > 0) this.searchMode = savedSearchMode;
      this.selectedEngineIndex = await this.preferencesStore.get('selected_engine_index', 1) as number;
      this.searchAllEngines = true;
      const savedLangMode = await this.preferencesStore.get('language_mode', 'chinese') as string;
      if (typeof savedLangMode === 'string' && savedLangMode.length > 0) this.languageMode = savedLangMode;
      const savedResultMode = await this.preferencesStore.get('search_result_mode', 'rule_filter') as string;
      if (typeof savedResultMode === 'string' && savedResultMode.length > 0) this.searchResultMode = savedResultMode;
    setSearchResultFilterMode('rule_filter');
      const savedExtraTerms = await this.preferencesStore.get('extra_search_terms', '') as string;
      if (typeof savedExtraTerms === 'string') this.extraSearchTerms = savedExtraTerms;
      const savedSiteHint = await this.preferencesStore.get('site_hint', '') as string;
      if (typeof savedSiteHint === 'string') this.siteHint = savedSiteHint;
      this.enableSearchEngines = await this.preferencesStore.get('enable_search_engines', true) as boolean;
      this.enableHtmlRules = await this.preferencesStore.get('enable_html_rules', true) as boolean;
      this.maxSearchResults = await this.preferencesStore.get('max_search_results', 80) as number;
      this.maxReaderPages = await this.preferencesStore.get('max_reader_pages', 30) as number;
      this.showImageIndex = await this.preferencesStore.get('show_image_index', true) as boolean;
      this.readerDarkMode = await this.preferencesStore.get('reader_dark_mode', true) as boolean;
      const savedBlockedDomains = await this.preferencesStore.get('custom_blocked_domains', '') as string;
      if (typeof savedBlockedDomains === 'string' && savedBlockedDomains.length > 0) {
        this.customBlockedDomains = savedBlockedDomains;
        searchFilterConfig.blockedDomains = savedBlockedDomains.split('\n').filter((s: string) => s.trim().length > 0);
      }
      const savedBlockedWords = await this.preferencesStore.get('custom_blocked_words', '') as string;
      if (typeof savedBlockedWords === 'string' && savedBlockedWords.length > 0) {
        this.customBlockedWords = savedBlockedWords;
        searchFilterConfig.blockedWords = savedBlockedWords.split('\n').filter((s: string) => s.trim().length > 0);
      }
      const savedNoiseWords = await this.preferencesStore.get('custom_noise_words', '') as string;
      if (typeof savedNoiseWords === 'string' && savedNoiseWords.length > 0) {
        this.customNoiseWords = savedNoiseWords;
        searchFilterConfig.noiseTitleWords = savedNoiseWords.split('\n').filter((s: string) => s.trim().length > 0);
      }
      this.applyKeepScreenOn();
    } catch (e) {
    }
  }

  private async persistDataImmediate(): Promise<void> {
    if (this.preferencesStore === null) return;
    try {
      await this.preferencesStore.put('reading_history', JSON.stringify(this.history));
      await this.preferencesStore.put('bookshelf', JSON.stringify(this.bookshelf));
      await this.preferencesStore.put('recent_searches', JSON.stringify(this.recentSearches));
      await this.preferencesStore.put('app_theme', this.appTheme);
      await this.preferencesStore.put('app_language', this.appLanguage);
      await this.preferencesStore.put('debug_keep_screen_on', this.debugKeepScreenOn);
      await this.preferencesStore.put('show_debug_info', this.showDebugInfo);
      await this.preferencesStore.put('icon_color_mode', this.iconColorMode);
      await this.preferencesStore.put('chapter_reversed', this.chapterReversed);
      await this.preferencesStore.put('fullscreen_reader', this.fullscreenReader);
      await this.preferencesStore.put('floating_reader_controls', this.floatingReaderControls);
      await this.preferencesStore.put('advanced_rules', JSON.stringify(this.advancedRules));
      await this.preferencesStore.put('blocked_urls', JSON.stringify(this.blockedUrls));
      await this.preferencesStore.put('shelf_display_mode', this.shelfDisplayMode);
      await this.preferencesStore.put('brave_api_key', this.braveApiKey);
      await this.preferencesStore.put('google_api_key', this.googleApiKey);
      await this.preferencesStore.put('google_cx', this.googleCx);
      await this.preferencesStore.put('auto_cover_enabled', this.autoCoverEnabled);
      await this.preferencesStore.put('search_mode', this.searchMode);
      await this.preferencesStore.put('selected_engine_index', this.selectedEngineIndex);
      await this.preferencesStore.put('search_all_engines', this.searchAllEngines);
      await this.preferencesStore.put('language_mode', this.languageMode);
      await this.preferencesStore.put('search_result_mode', this.searchResultMode);
      await this.preferencesStore.put('extra_search_terms', this.extraSearchTerms);
      await this.preferencesStore.put('site_hint', this.siteHint);
      await this.preferencesStore.put('enable_search_engines', this.enableSearchEngines);
      await this.preferencesStore.put('enable_html_rules', this.enableHtmlRules);
      await this.preferencesStore.put('max_search_results', this.maxSearchResults);
      await this.preferencesStore.put('max_reader_pages', this.maxReaderPages);
      await this.preferencesStore.put('show_image_index', this.showImageIndex);
      await this.preferencesStore.put('reader_dark_mode', this.readerDarkMode);
      await this.preferencesStore.put('custom_blocked_domains', this.customBlockedDomains);
      await this.preferencesStore.put('custom_blocked_words', this.customBlockedWords);
      await this.preferencesStore.put('custom_noise_words', this.customNoiseWords);
      await this.preferencesStore.flush();
    } catch (e) {
    }
  }

  private async persistData(): Promise<void> {
    await this.persistDataImmediate();
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

  private lastReaderUrlFromBrowser: string = '';

  onPageShow(): void {
    try {
      const params = router.getParams() as Record<string, Object>;
      if (params === undefined) return;
      const readerUrl = params['readerUrl'] as string;
      if (readerUrl === undefined || readerUrl.length === 0 || readerUrl === this.lastReaderUrlFromBrowser) return;
      if (!readerUrl.startsWith('http://') && !readerUrl.startsWith('https://')) return;
      this.lastReaderUrlFromBrowser = readerUrl;
      const readerTitle = (params['readerTitle'] ?? '') as string;
      const rule = this.findRuleByUrl(readerUrl);
      this.loadDetailAndRead(readerUrl, readerTitle, rule);
    } catch (e) {}
  }

  private async loadDetailAndRead(url: string, title: string, rule: ComicSourceRule): Promise<void> {
    await this.loadDetail(url, title, rule);
    if (this.chapters.length > 0) {
      this.loadChapter(this.chapters[0], this.findRule(this.chapters[0].sourceId));
    }
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

  private shelfCategoryIndex(): number {
    return this.catalogCategories.findIndex((cat: CatalogCategory) => cat.id === this.selectedCatalogCategory);
  }

  private shelfAdjacentCategory(direction: number): string {
    const idx = this.shelfCategoryIndex();
    if (idx < 0) return '';
    const next = idx + direction;
    if (next < 0 || next >= this.catalogCategories.length) return '';
    return this.catalogCategories[next].id;
  }

  private shelfSwitchCategory(direction: number): void {
    const nextId = this.shelfAdjacentCategory(direction);
    if (nextId.length === 0) return;
    this.selectedCatalogCategory = nextId;
    if (this.remoteCatalog !== null) {
      this.catalogItems = this.filteredCatalogItems(this.remoteCatalog, nextId);
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

  private loadCachedRules(): void {
    try {
      if (this.ruleCachePath.length === 0 || !fs.accessSync(this.ruleCachePath)) return;
      const cached = JSON.parse(fs.readTextSync(this.ruleCachePath)) as ComicSourceRule[];
      if (cached.length > 0) {
        this.onlineRules = cached;
        this.rebuildEffectiveRules();
        this.remoteRuleCount = cached.length;
        this.remoteRuleStatus = this.catalogStage('正在使用已缓存的线上规则', 'Using cached online rules');
      }
    } catch (e) {
      // A damaged cache must never replace the built-in fallback rules.
      this.onlineRules = [];
      this.rebuildEffectiveRules();
    }
  }

  private saveRuleCache(rules: ComicSourceRule[]): void {
    if (this.ruleCachePath.length === 0) return;
    const tempPath = this.ruleCachePath + '.tmp';
    try {
      const output: fs.File = fs.openSync(tempPath,
        fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      try {
        fs.writeSync(output.fd, JSON.stringify(rules));
      } finally {
        fs.closeSync(output);
      }
      if (fs.accessSync(this.ruleCachePath)) fs.unlinkSync(this.ruleCachePath);
      fs.renameSync(tempPath, this.ruleCachePath);
    } catch (e) {
      try {
        if (fs.accessSync(tempPath)) fs.unlinkSync(tempPath);
      } catch (ignored) {
      }
    }
  }

  private loadCachedCoverAccuracy(): void {
    try {
      if (this.coverAccuracyCachePath.length === 0 || !fs.accessSync(this.coverAccuracyCachePath)) return;
      const cached = JSON.parse(fs.readTextSync(this.coverAccuracyCachePath)) as CoverAccuracyIndex;
      if (cached.schema === 'comic_cover_accuracy_index_v1' && Array.isArray(cached.entries) &&
        cached.entries.length === cached.count) {
        this.coverAccuracyIndex = cached;
        this.coverAccuracyStatus = this.isEn() ? 'Cached verified covers: ' + cached.count :
          '已缓存准确封面：' + cached.count + ' 条';
        this.applyCoverAccuracy();
      }
    } catch (e) {
      this.coverAccuracyIndex = null;
    }
  }

  private saveCoverAccuracyCache(index: CoverAccuracyIndex): void {
    if (this.coverAccuracyCachePath.length === 0) return;
    const temp = this.coverAccuracyCachePath + '.tmp';
    try {
      const output = fs.openSync(temp, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      try { fs.writeSync(output.fd, JSON.stringify(index)); } finally { fs.closeSync(output); }
      if (fs.accessSync(this.coverAccuracyCachePath)) fs.unlinkSync(this.coverAccuracyCachePath);
      fs.renameSync(temp, this.coverAccuracyCachePath);
    } catch (e) {
      try { if (fs.accessSync(temp)) fs.unlinkSync(temp); } catch (ignored) {}
    }
  }

  private coverTitleKey(value: string): string {
    return this.cleanTitle(value).toLowerCase().replace(/\s+/g, '')
      .replace(/[·:：,，。！？!?《》【】()\[\]_-]/g, '');
  }

  private searchTitleKey(value: string): string {
    let title = this.cleanTitle(value).toLowerCase();
    const separator = title.search(/[_|｜]/);
    if (separator > 0) title = title.substring(0, separator);
    const dashSeparator = title.indexOf(' - ');
    if (dashSeparator > 0) title = title.substring(0, dashSeparator);
    title = title.replace(/(?:漫画)?(?:最新章节|在线阅读|下拉式|下拉免费漫画|免费阅读).*$/i, '')
      .replace(/漫画$/i, '')
      .replace(/\s+/g, '')
      .replace(/[·:：,，。！？!?《》【】()\[\]_-]/g, '');
    return title;
  }

  private verifiedCoverForTitle(title: string): CoverAccuracyEntry | null {
    if (this.coverAccuracyIndex === null) return null;
    const key = this.coverTitleKey(title);
    const found = this.coverAccuracyIndex.entries.find((entry: CoverAccuracyEntry) =>
      entry.titleKey === key && entry.confidence === 'verified-title-bound-cover' &&
      entry.coverUrl.startsWith('https://'));
    return found ? found : null;
  }

  private applyCoverAccuracy(): void {
    if (this.coverAccuracyIndex === null) return;
    this.results = this.results.map((item: SearchResultItem): SearchResultItem => {
      const verified = this.verifiedCoverForTitle(item.title);
      if (verified) item.cover = verified.coverUrl;
      return item;
    });
    this.history = this.history.map((item: ReadingHistoryItem): ReadingHistoryItem => {
      const verified = this.verifiedCoverForTitle(item.title);
      if (verified) item.cover = verified.coverUrl;
      return item;
    });
    const coversToCache: string[][] = [];
    this.bookshelf = this.bookshelf.map((item: BookshelfItem): BookshelfItem => {
      const verified = this.verifiedCoverForTitle(item.title);
      if (!verified) return item;
      coversToCache.push([item.url, verified.coverUrl]);
      item.cover = verified.coverUrl;
      item.remoteCover = verified.coverUrl;
      return item;
    });
    this.persistData();
    for (let i = 0; i < coversToCache.length; i++) {
      this.cacheBookshelfCover(coversToCache[i][0], coversToCache[i][1]);
    }
  }

  private async updateCoverAccuracy(): Promise<void> {
    if (this.updatingCoverAccuracy) return;
    this.updatingCoverAccuracy = true;
    this.coverAccuracyStatus = this.isEn() ? 'Updating cover accuracy index...' : '正在更新封面准确性索引…';
    try {
      const index = await RemoteRuleService.fetchCoverAccuracyIndex(this.remoteRuleUrl);
      this.coverAccuracyIndex = index;
      this.saveCoverAccuracyCache(index);
      this.applyCoverAccuracy();
      this.coverAccuracyStatus = this.isEn() ? 'Verified covers updated: ' + index.count :
        '准确封面已更新：' + index.count + ' 条';
    } catch (e) {
      this.coverAccuracyStatus = this.isEn() ? 'Cover accuracy update failed.' : '封面准确性更新失败。';
    }
    const builtinUpdated = await this.builtinCoverRefreshForMissing();
    if (builtinUpdated > 0) {
      this.coverAccuracyStatus += this.isEn() ? '; builtin check updated: ' + builtinUpdated : '；内置校对更新：' + builtinUpdated + ' 本';
    }
    this.updatingCoverAccuracy = false;
  }

  private async builtinCoverRefreshForMissing(): Promise<number> {
    const pending: BookshelfItem[] = [];
    for (let i = 0; i < this.bookshelf.length; i++) {
      const item = this.bookshelf[i];
      const rc = item.remoteCover !== undefined ? item.remoteCover : item.cover;
      if (/^https?:\/\//i.test(rc)) continue;
      if (this.verifiedCoverForTitle(item.title) !== null) continue;
      pending.push(item);
    }
    const maxBatch = 10;
    const batchCount = Math.min(pending.length, maxBatch);
    let updated = 0;
    for (let i = 0; i < batchCount; i++) {
      const item = pending[i];
      this.statusText = this.isEn()
        ? 'Builtin cover check (' + (i + 1) + '/' + batchCount + '): ' + item.title
        : '内置校对封面 (' + (i + 1) + '/' + batchCount + ')：' + item.title;
      const cover = await this.builtinCoverForTitle(item.title, item.url);
      if (cover.length > 0 && /^https?:\/\//i.test(cover)) {
        await this.cacheBookshelfCover(item.url, cover);
        updated++;
      }
    }
    if (pending.length > 0) {
      const suffix = pending.length > batchCount ? this.isEn() ? ' (remaining pending)' : '（剩余待下次更新）' : '';
      this.statusText = this.isEn()
        ? 'Builtin covers updated: ' + updated + suffix
        : '内置封面校对完成：更新 ' + updated + ' 本' + suffix;
    }
    return updated;
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

  private ruleProgressText(): string {
    if (this.ruleTotalBytes > 0) {
      return this.ruleProgressPercent + '% · ' + this.formatBytes(this.ruleReceivedBytes) +
        ' / ' + this.formatBytes(this.ruleTotalBytes);
    }
    if (this.ruleReceivedBytes > 0) return this.ruleProgressPercent + '% · ' + this.formatBytes(this.ruleReceivedBytes);
    return this.ruleProgressStatus;
  }

  private filterWordsProgressText(): string {
    if (this.filterWordsTotalBytes > 0) {
      return this.filterWordsProgressPercent + '% · ' + this.formatBytes(this.filterWordsReceivedBytes) +
        ' / ' + this.formatBytes(this.filterWordsTotalBytes);
    }
    if (this.filterWordsReceivedBytes > 0) return this.filterWordsProgressPercent + '% · ' + this.formatBytes(this.filterWordsReceivedBytes);
    return this.filterWordsStatus;
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
    if (this.themeDialogVisible) {
      this.themeDialogVisible = false;
      return true;
    }
    if (this.languageDialogVisible) {
      this.languageDialogVisible = false;
      return true;
    }
    if (this.themeExpanded) {
      this.themeExpanded = false;
      return true;
    }
    if (this.languageExpanded) {
      this.languageExpanded = false;
      return true;
    }
    if (this.iconColorExpanded) {
      this.iconColorExpanded = false;
      return true;
    }
    if (this.searchExpanded) {
      this.searchExpanded = false;
      return true;
    }
    if (this.sourcesExpanded) {
      this.sourcesExpanded = false;
      return true;
    }
    if (this.readerExpanded) {
      this.readerExpanded = false;
      return true;
    }
    if (this.enginesExpanded) {
      this.enginesExpanded = false;
      return true;
    }
    if (this.rulesExpanded) {
      this.rulesExpanded = false;
      return true;
    }
    if (this.updateDialogVisible) {
      this.updateDialogVisible = false;
      return true;
    }
    if (this.historyMenuVisible) {
      this.historyMenuVisible = false;
      return true;
    }
    if (this.shelfMenuVisible) {
      this.shelfMenuVisible = false;
      return true;
    }
    if (this.bookLongPressVisible) {
      this.closeBookLongPressMenu();
      return true;
    }
    if (this.editorMenuVisible) {
      this.editorMenuVisible = false;
      return true;
    }
    if (this.editorFullscreen) {
      this.editorFullscreen = false;
      this.settingsDialog = '';
      this.applyReaderFullscreen(false);
      return true;
    }
    if (this.mode === 'reader') {
      this.applyReaderFullscreen(false);
      if (this.chapters.length > 0) {
        this.mode = 'chapters';
        this.scrollToCurrentChapter();
      }
      else if (this.results.length > 0) this.returnToSearchResults();
      else { this.stopSearch(); this.mode = 'home'; }
      this.activeTab = 'search';
      return true;
    }
    if (this.mode === 'chapters') {
      if (this.results.length > 0) this.returnToSearchResults();
      else { this.stopSearch(); this.mode = 'home'; }
      this.activeTab = 'search';
      return true;
    }
    if (this.activeTab !== 'search') {
      this.activeTab = 'search';
      this.mode = this.results.length > 0 ? 'results' : 'home';
      return true;
    }
    if (this.mode === 'results') {
      if (this.searchResultMode === 'browser') {
        try {
          if (this.webController.accessBackward()) {
            this.webErrorText = '';
            this.webLoading = true;
            this.webController.backward();
            return true;
          }
        } catch (error) {}
      }
      this.stopSearch();
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
      if (key === 'url_copied') return 'URL copied';
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
      if (key === 'app_settings') return 'Comic Source Settings';
      if (key === 'about') return 'About';
      if (key === 'debug_keep_screen_on') return 'Keep screen on for debugging';
      if (key === 'show_debug_info') return 'Show debug info';
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
      if (key === 'advanced_rules') return 'Custom Rules';
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
      if (key === 'built_in_rules') return 'Built-in Rules';
      if (key === 'online_rule_changes') return 'Online Changes';
      if (key === 'cover_accuracy') return 'Cover Accuracy Check';
      if (key === 'update_cover') return 'Update Cover';
      if (key === 'cover_update_success') return 'Cover updated successfully';
      if (key === 'cover_update_failed') return 'Cover update failed';
      if (key === 'cover_no_source') return 'No cover source found';
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
      if (key === 'add_favorite') return 'Add Favorite';
      if (key === 'remove_favorite') return 'Remove Favorite';
      if (key === 'search_title') return 'Search Title';
      if (key === 'delete') return 'Delete';
      if (key === 'close') return 'Close';
      if (key === 'api_key') return 'API Key';
      if (key === 'brave_api_key') return 'Brave API Key';
      if (key === 'google_api_key') return 'Google API Key';
      if (key === 'google_cx') return 'Google CX (Search Engine ID)';
      if (key === 'api_config') return 'API Configuration';
      if (key === 'api_key_hint') return 'Enter API Key';
      if (key === 'google_cx_hint') return 'Enter Search Engine ID';
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
    if (key === 'url_copied') return '网址已复制';
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
    if (key === 'app_settings') return '漫画源设置';
    if (key === 'about') return '关于';
    if (key === 'debug_keep_screen_on') return '屏幕常亮';
    if (key === 'show_debug_info') return '调试信息';
    if (key === 'theme') return '主题';
    if (key === 'language') return '语言';
    if (key === 'light') return '明亮';
    if (key === 'dark') return '暗黑';
    if (key === 'follow_system') return '跟随系统';
    if (key === 'reader_fullscreen') return '阅读全屏';
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
    if (key === 'display_reading') return '显示阅读';
    if (key === 'reading_settings') return '阅读设置';
    if (key === 'search_engine') return '搜索引擎';
    if (key === 'rule_settings') return '规则设置';
    if (key === 'advanced_rules') return '自定义规则';
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
    if (key === 'built_in_rules') return '内置规则';
    if (key === 'online_rule_changes') return '在线规则变化';
    if (key === 'cover_accuracy') return '封面校验';
    if (key === 'update_cover') return '更新封面';
    if (key === 'cover_update_success') return '封面更新成功';
    if (key === 'cover_update_failed') return '封面更新失败';
    if (key === 'cover_no_source') return '未找到封面来源';
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
    if (key === 'add_favorite') return '添加收藏';
    if (key === 'remove_favorite') return '取消收藏';
    if (key === 'search_title') return '搜索书名';
    if (key === 'delete') return '删除';
    if (key === 'close') return '关闭';
    if (key === 'api_key') return 'API Key';
    if (key === 'brave_api_key') return 'Brave API Key';
    if (key === 'google_api_key') return 'Google API Key';
    if (key === 'google_cx') return 'Google CX (搜索引擎ID)';
    if (key === 'api_config') return 'API 配置';
    if (key === 'api_key_hint') return '输入 API Key';
    if (key === 'google_cx_hint') return '输入搜索引擎ID';
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

  private searchResultModeDisplay(): string {
    return this.searchResultMode === 'browser' ? '浏览器' : '规则筛选';
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
  private colorfulAccent(key: string): string {
    if (this.iconColorMode !== 'colorful') return this.iconModeColor(this.iconColorMode);
    return this.colorfulValue(key);
  }
  private primaryText(): string { return this.isDark() ? '#E8ECF4' : '#111827'; }
  private secondaryText(): string { return this.isDark() ? '#B6BFCC' : '#667085'; }
  private iconColor(icon: string): string {
    if (this.iconColorMode !== 'colorful') return this.iconModeColor(this.iconColorMode);
    if (icon === 'ic_search' || icon === 'ic_globe' || icon === 'ic_web') return '#0A84FF';
    if (icon === 'ic_shelf' || icon === 'ic_book' || icon === 'ic_add_shelf' || icon === 'ic_star_filled' || icon === 'ic_star_outline') return '#FF9500';
    if (icon === 'ic_history' || icon === 'ic_clock') return '#AF52DE';
    if (icon === 'ic_settings' || icon === 'ic_tune') return '#34C759';
    if (icon === 'ic_refresh' || icon === 'ic_engine') return '#00C7BE';
    if (icon === 'ic_rule' || icon === 'ic_code') return '#5856D6';
    if (icon === 'ic_language' || icon === 'ic_filter') return '#F5C400';
    if (icon === 'ic_reader' || icon === 'ic_reading' || icon === 'ic_fullscreen') return '#FF2D92';
    if (icon === 'ic_layout') return '#34C759';
    if (icon === 'ic_moon') return '#00C7BE';
    if (icon === 'ic_eye') return '#AF52DE';
    if (icon === 'ic_info') return '#5856D6';
    if (icon === 'ic_bug') return '#FF3B30';
    if (icon === 'ic_palette') return '#FF9500';
    if (icon === 'ic_more_vert') return '#0A84FF';
    if (icon === 'ic_keyboard') return '#34C759';
    if (icon === 'ic_link' || icon === 'ic_back' || icon === 'ic_arrow_left' || icon === 'ic_arrow_right' || icon === 'ic_chevron_right') return '#0A84FF';
    if (icon === 'ic_color_picker' || icon === 'ic_bookmark' || icon === 'ic_save') return '#FF9500';
    if (icon === 'ic_wrap_text' || icon === 'ic_copy' || icon === 'ic_paste') return '#00C7BE';
    if (icon === 'ic_play' || icon === 'ic_check_circle') return '#34C759';
    if (icon === 'ic_align_left' || icon === 'ic_undo' || icon === 'ic_redo') return '#5856D6';
    if (icon === 'ic_stats_report') return '#AF52DE';
    if (icon === 'ic_arrow_down_circle' || icon === 'ic_nav_arrow_down' || icon === 'ic_close') return '#FF2D92';
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
  private messageColor(): string { return this.colorfulValue('message-' + this.statusText); }
  private messageBackground(): string { return '#28' + this.messageColor().substring(1); }
  private messageBorder(): string { return '#88' + this.messageColor().substring(1); }
  private iconColorModeDisplay(): string { return this.t('icon_color_' + this.iconColorMode); }
  private tabIconKey(name: string): string {
    if (name === 'search') return 'ic_search';
    if (name === 'shelf') return 'ic_shelf';
    if (name === 'history') return 'ic_history';
    return 'ic_settings';
  }
  private actionBg(): string { return '#167A36'; }
  private warnText(): string { return this.isDark() ? '#F0C060' : '#8A5A12'; }
  private borderSubtle(): string { return this.isDark() ? '#2A2E3A' : '#F0F0F0'; }
  private scrollBarColor(): string { return this.isDark() ? '#CCCCCC' : '#444444'; }
  private dialogOverlay(): string { return this.isDark() ? '#88000000' : '#66000000'; }
  private inputBg(): string { return this.isDark() ? '#2A2E3A' : '#F2F4F7'; }
  private coverPlaceholderBg(): string { return this.isDark() ? '#1A3020' : '#ECFFF1'; }

  private selectedEngine(): SearchEngineConfig {
    if (this.selectedEngineIndex < 0 || this.selectedEngineIndex >= this.searchEngines.length) return this.searchEngines[0];
    return this.searchEngines[this.selectedEngineIndex];
  }

  private genericRule(): ComicSourceRule {
    const found = this.rules.find((item: ComicSourceRule) => item.id === 'generic_html_public');
    return found ? found : this.rules[0];
  }

  private buildBuiltinRulesSummary(): string {
    let text = '';
    text += '=== 内置规则概览 ===\n';
    text += '通用规则: ' + DEFAULT_SOURCES.length + ' 条\n';
    text += '已验证域名: ' + VERIFIED_DOMAIN_COUNT + ' 个\n';
    text += '公开访问域名: ' + PUBLIC_ACCESS_DOMAIN_COUNT + ' 个\n';
    text += '总计覆盖: ' + (VERIFIED_DOMAIN_COUNT + PUBLIC_ACCESS_DOMAIN_COUNT) + ' 个域名\n\n';
    text += '=== 通用规则定义 ===\n';
    text += JSON.stringify(DEFAULT_SOURCES, null, 2);
    text += '\n\n=== 已验证域名列表 (' + VERIFIED_DOMAIN_COUNT + '个) ===\n';
    text += 'maxPages=12, hasNextPage=false\n';
    text += '匹配方式: 精确域名匹配, 每域独立referer\n';
    text += '---\n';
    text += '288manhua.com, 590ac.com, 5imanhua.click, ac.qq.com, akmh666.com,\n';
    text += 'asshow.com, b.faloo.com, baoziaicomic.com, bjzf.org, bkmh555.com,\n';
    text += 'bury.bljipeapy.com, cdt-gz.cn, china-armature.com, comic.qq.com,\n';
    text += 'cuimanhua.com, cuimh.com, cxjob.com.cn, dafumh.com, dagumh.com,\n';
    text += 'dandanmh.com, dayiming.cn, dhan.cc, digumh.com, dongman.qq.com,\n';
    text += 'dongmanmanhua.cn, duiduimanhua.com, duya.cc, ffppt.com,\n';
    text += 'guazimanhua.com, guazixs.cn, hazelmaka.com, hfuodip.com,\n';
    text += 'hongshu.com, hqqh.cc, htzsgc.cn, huayangdm.com, huozx.net,\n';
    text += 'jiexi8.com, jincs.cn, jiujiumanhua.com, jjwxc.net,\n';
    text += 'jsmanhuawang.com, katadyngroup.com.cn, kkwebtoon.com,\n';
    text += 'kuaikan321.com, kuaikanmanhua.com, m.bikamanhua.com, m.bjwsxx.com,\n';
    text += 'm.dagumanhua.cc, m.dumanwu.com, m.dumanwu1.com, m.guozhenglawyer.com,\n';
    text += 'm.haohuagg.com, m.jingmingbg.com, m.maomimh.com, m.ortzn.com,\n';
    text += 'm.sisimanhua.com, m.tcsrq.cn, manbatu.com, mangatoon.mobi,\n';
    text += 'manhua1234.com, manhuarenren.com, maomaoks.com, mdb88.com,\n';
    text += 'medyakey.com, mh250.cc, mh250.com, mhz4.com, mobile.ac.qq.com,\n';
    text += 'mwjsiot.com, mzywwcm.com, nhy2.com, nubbub.com, pdbgds.com,\n';
    text += 'pufeimanhuaw.com, runshua.com, sdxqx.com, sfmanhua.com,\n';
    text += 'shenqimanhua.net, shilunmh.com, shoujimanhua.com, songyuanman.com,\n';
    text += 'sqmh.app, sqrsks.com, t.shuqi.com, tcsrq.cn, tzysjx.cn,\n';
    text += 'veryim.com, wap.faloo.com, xhp119.com, xhp124.com,\n';
    text += 'xkanmanhua.com, yandans.com, yinglifan.com, yiningguanggao.com,\n';
    text += 'yinxiang17.com, yixiuche.com, youzimanhua.com, z525.com,\n';
    text += 'zgmanhua.com, zhongkeman.com, zymk.cn\n\n';
    text += '=== 公开访问域名列表 (' + PUBLIC_ACCESS_DOMAIN_COUNT + '个) ===\n';
    text += 'maxPages=16, hasNextPage=true\n';
    text += '匹配方式: 主机名匹配, 动态referer\n';
    text += '---\n';
    text += 'mh160mh.com, shenlanqiyu.cc, manhuaus.com, mangafire.to,\n';
    text += 'mangadna.com, mangaread.org, mycomic.com, toomics.com,\n';
    text += 'lezhin.com, webtoons.com, tapas.io, mangadex.org,\n';
    text += 'guya.moe, catmanga.org, manga4life.com, asurascans.com,\n';
    text += 'flamescans.org, reapertranslates.com, lhtranslates.com,\n';
    text += 'immortalscans.com, mangakakalot.com, manganato.com,\n';
    text += 'readmanga.app, manhuatop.com, manhuaes.com, manhwa18.cc,\n';
    text += 'toonily.com, manganelo.com, hentai2read.com, nhentai.net,\n';
    text += 'myreadingmanga.info, dmzj.com, chuiyao.com, 57mh.com,\n';
    text += 'aikanmanhua.com, manhuagui.com, manhuaren.com, ikanman.com,\n';
    text += 'dm5.cn, manwang.net, ttkmh.com, labimanhua.com,\n';
    text += 'hitomi.la, jwxs.org\n';
    return text;
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

  private siteTypeTag(url: string, title: string): string {
    if (title.indexOf('漫画') >= 0 || title.indexOf('漫話') >= 0) return '漫画';
    const host = this.hostOf(url).toLowerCase();
    const lowerUrl = url.toLowerCase();
    if (lowerUrl.indexOf('ac.qq.com/') >= 0 || lowerUrl.indexOf('kuaikanmanhua') >= 0 ||
      lowerUrl.indexOf('manga.bilibili') >= 0 || lowerUrl.indexOf('bilibilicomics') >= 0 ||
      lowerUrl.indexOf('u17.com') >= 0 || lowerUrl.indexOf('manhuadao') >= 0 ||
      lowerUrl.indexOf('dongmanmanhua') >= 0 || lowerUrl.indexOf('manhuagui') >= 0 ||
      lowerUrl.indexOf('dm5.cn') >= 0 || lowerUrl.indexOf('manhuaren') >= 0 ||
      lowerUrl.indexOf('ikanman') >= 0 || lowerUrl.indexOf('57mh') >= 0 ||
      lowerUrl.indexOf('aikanmanhua') >= 0 || lowerUrl.indexOf('mangakakalot') >= 0 ||
      lowerUrl.indexOf('manganato') >= 0 || lowerUrl.indexOf('mh160') >= 0 ||
      lowerUrl.indexOf('dmzj') >= 0 || lowerUrl.indexOf('comic') >= 0 ||
      lowerUrl.indexOf('manga') >= 0 || lowerUrl.indexOf('manhua') >= 0 ||
      lowerUrl.indexOf('webtoon') >= 0) return '漫画';
    if (host.indexOf('baike.') >= 0 || host.indexOf('wikipedia') >= 0 ||
      host.indexOf('wiki') >= 0 || host.indexOf('fandom') >= 0) return '百科';
    if (host.indexOf('cidian') >= 0 || host.indexOf('zidian') >= 0 ||
      host.indexOf('shidianguji') >= 0 || host.indexOf('hanyuguoxue') >= 0 ||
      host.indexOf('guoxue') >= 0 || host.indexOf('zdic') >= 0) return '字典';
    if (host.indexOf('apps.microsoft') >= 0 || host.indexOf('appstore') >= 0 ||
      host.indexOf('play.google') >= 0) return '应用';
    if (host.indexOf('douyin') >= 0 || host.indexOf('tiktok') >= 0 ||
      host.indexOf('youtube') >= 0 || host.indexOf('bilibili') >= 0 ||
      host.indexOf('ixigua') >= 0 || host.indexOf('kuaishou') >= 0) return '视频';
    if (host.indexOf('weibo') >= 0 || host.indexOf('twitter') >= 0 ||
      host.indexOf('facebook') >= 0 || host.indexOf('instagram') >= 0 ||
      host.indexOf('reddit') >= 0 || host.indexOf('xiaohongshu') >= 0) return '社交';
    if (host.indexOf('toutiao') >= 0 || host.indexOf('news') >= 0 ||
      host.indexOf('36kr') >= 0) return '资讯';
    if (host.indexOf('taobao') >= 0 || host.indexOf('tmall') >= 0 ||
      host.indexOf('jd.com') >= 0 || host.indexOf('amazon') >= 0 ||
      host.indexOf('pinduoduo') >= 0) return '购物';
    if (host.indexOf('tieba') >= 0 || host.indexOf('zhihu') >= 0 ||
      host.indexOf('forum') >= 0 || host.indexOf('bbs') >= 0) return '社区';
    if (host.indexOf('gov.cn') >= 0) return '政府';
    return '网页';
  }

  private copyToClipboard(text: string): void {
    try {
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      const systemPasteboard = pasteboard.getSystemPasteboard();
      systemPasteboard.setData(pasteData);
    } catch (e) {}
  }

  private debugSourceKind(item: SearchResultItem): string {
    if (item.resultType === 'catalog') return '本地目录';
    if (item.resultType === 'search-engine') return '搜索引擎';
    const apiIds: string[] = ['internet_archive_iiif_api', 'wikimedia_commons_api',
      'pepper_carrot_public_catalog', 'open_library_public_api', 'library_of_congress_public_api'];
    for (let i = 0; i < apiIds.length; i++) {
      if (item.sourceId === apiIds[i]) return 'API源';
    }
    for (let i = 0; i < this.advancedRules.length; i++) {
      if (this.advancedRules[i].id === item.sourceId) return '自定义';
    }
    for (let i = 0; i < this.onlineRules.length; i++) {
      if (this.onlineRules[i].id === item.sourceId) return '远程';
    }
    for (let i = 0; i < DEFAULT_SOURCES.length; i++) {
      if (DEFAULT_SOURCES[i].id === item.sourceId) return '内置';
    }
    if (item.sourceId.endsWith('_public_access')) return '内置';
    const dotIndex = item.sourceId.indexOf('.');
    const underscoreIndex = item.sourceId.indexOf('_');
    if (dotIndex < 0 && underscoreIndex > 0) return '内置';
    return '兜底';
  }

  private debugResultTypeCN(resultType: string | undefined): string {
    if (resultType === undefined) return '未知';
    if (resultType === 'search-engine') return '搜索引擎';
    if (resultType === 'html-rule') return 'HTML规则';
    if (resultType === 'catalog') return '本地目录';
    if (resultType === 'archive-iiif') return '档案API';
    return resultType;
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

  private isUrlBlocked(url: string): boolean {
    if (this.blockedUrls.length === 0) return false;
    const lower = url.toLowerCase();
    for (let i = 0; i < this.blockedUrls.length; i++) {
      const blocked = this.blockedUrls[i].toLowerCase();
      if (lower.indexOf(blocked) >= 0) return true;
    }
    return false;
  }

  private appendResults(sourceItems: SearchResultItem[]): void {
    const next: SearchResultItem[] = [];
    for (let i = 0; i < this.results.length; i++) next.push(this.results[i]);
    for (let j = 0; j < sourceItems.length; j++) {
      if (next.length >= this.maxSearchResults) break;
      const item = this.enrich(sourceItems[j]);
      if (this.isUrlBlocked(item.url)) continue;
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

  private stopSearch(): void {
    this.searchGeneration++;
    this.isLoading = false;
    this.webLoading = false;
    if (this.webLoadingTimeoutId !== -1) {
      clearTimeout(this.webLoadingTimeoutId);
      this.webLoadingTimeoutId = -1;
    }
  }

  private clearSearchAndReset(): void {
    this.stopSearch();
    this.queryText = '';
    this.results = [];
    this.mode = 'home';
    this.statusText = '';
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
    inputMethod.getController().hideTextInput().catch(() => {});
    this.rememberSearch(keyword);
    this.searchHistoryVisible = false;
    if (looksLikeUrl(keyword)) {
      this.resetSearchState(keyword);
      this.isLoading = true;
      await this.loadDetail(normalizeUserUrl(keyword), this.t('url_parse'), ruleForPublicUrl(normalizeUserUrl(keyword), this.genericRule()));
      this.isLoading = false;
      return;
    }
    await this.searchKeyword(keyword);
  }

  private rememberSearch(keyword: string): void {
    const next: string[] = [keyword];
    for (let i = 0; i < this.recentSearches.length && next.length < 10; i++) {
      if (this.recentSearches[i] !== keyword) next.push(this.recentSearches[i]);
    }
    this.recentSearches = next;
    this.persistData();
  }

  private repeatSearch(keyword: string): void {
    this.queryText = keyword;
    this.searchHistoryVisible = false;
    this.startSearch();
  }

  private clearRecentSearches(): void {
    this.recentSearches = [];
    this.searchHistoryVisible = false;
    this.persistData();
  }

  private removeHistoryItem(url: string): void {
    this.history = this.history.filter((item: ReadingHistoryItem) => item.url !== url);
    this.persistData();
  }

  private clearVisibleHistory(): void {
    if (this.historyTab === 'history') this.history = [];
    else this.bookshelf = [];
    this.persistData();
  }

  private removeBookshelfItem(url: string): void {
    this.bookshelf = this.bookshelf.filter((item: BookshelfItem) => item.url !== url);
    this.persistData();
  }

  private async searchKeyword(keyword: string): Promise<void> {
    this.resetSearchState(keyword);
    this.isLoading = true;
    this.searchGeneration++;
    const gen = this.searchGeneration;
    setSearchResultFilterMode('rule_filter');
    this.searchPage = 1;
    this.hasMoreResults = false;
    this.debugEngineResults = 0;
    this.debugEngineTried = 0;
    this.debugSearchQueries = '';
    this.debugEngineSuccess = 0;
    const query = buildEngineQuery(keyword, this.extraSearchTerms, this.languageMode, this.siteHint);
    const baseEngineUrl = buildSearchEngineUrl(this.selectedEngine(), query, this.braveApiKey, this.googleApiKey, this.googleCx);
    this.searchEngineUrl = baseEngineUrl + (baseEngineUrl.indexOf('?') >= 0 ? '&' : '?') + '_t=' + Date.now();
    this.webLoading = true;
    this.webErrorText = '';
    this.showReaderHint = false;
    this.webMainFrameFailed = false;
    if (this.searchResultMode === 'browser') this.webDarkOverlay = true;
    console.info(`ComicReader[debug] searchKeyword: "${keyword}" mode=${this.searchMode} htmlEnabled=${this.enableHtmlRules} rules=${this.rules.length} online=${this.onlineRules.length} custom=${this.advancedRules.length} domainMatch=${VERIFIED_DOMAIN_COUNT + PUBLIC_ACCESS_DOMAIN_COUNT}`);
    try {
      if (this.searchResultMode === 'browser') {
        this.debugSearchQueries = query;
        this.statusText = this.t('searching_keyword') + ' "' + keyword + '"...';
      } else {
        this.searchLocalCatalog(keyword);
        if (this.searchGeneration !== gen) return;
        if (this.searchMode !== 'api_only') await this.searchSelectedEngines(keyword);
        if (this.searchGeneration !== gen) return;
        if (this.searchMode !== 'engine_only') {
          await this.searchHtmlRuleSources(keyword);
          if (this.searchGeneration !== gen) return;
          if (this.appLanguage === 'en') await this.searchApiSources(keyword);
        }
        if (this.searchGeneration !== gen) return;
        if (this.autoCoverEnabled) await this.enrichResultCovers(8);
        this.applyCoverAccuracy();
      }
      console.info(`ComicReader[debug] searchComplete: results=${this.results.length} engine=${this.results.filter((r: SearchResultItem) => r.resultType === 'search-engine').length} htmlRule=${this.results.filter((r: SearchResultItem) => r.resultType === 'html-rule').length} catalog=${this.results.filter((r: SearchResultItem) => r.resultType === 'catalog').length}`);
    } finally {
      if (this.searchGeneration === gen) {
        this.isLoading = false;
        this.statusText = this.results.length > 0 ? this.t('search_complete') + this.results.length + this.t('results_suffix') : this.t('no_comic_results');
      }
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
        if (item.validationPolicy !== 'readability-v5') continue;
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
    const queries: string[] = [];
    queries.push(buildEngineQuery(keyword, this.extraSearchTerms, this.languageMode, this.siteHint));
    this.debugSearchQueries = queries.join(' | ');
    const engines: SearchEngineConfig[] = [];
    if (this.searchAllEngines) {
      for (let i = 0; i < this.searchEngines.length; i++) {
        if (this.searchEngines[i].enabled) engines.push(this.searchEngines[i]);
      }
    } else if (this.selectedEngine().enabled) {
      engines.push(this.selectedEngine());
    }
    const pending: Promise<SearchResultItem[]>[] = [];
    const browserPages = this.searchResultMode === 'browser' ? 10 : 1;
    for (let i = 0; i < engines.length; i++) {
      if (isEngineConfigured(engines[i], this.braveApiKey, this.googleApiKey, this.googleCx)) {
        for (let queryIndex = 0; queryIndex < queries.length; queryIndex++) {
          for (let p = 1; p <= browserPages; p++) {
            pending.push(this.fetchSearchEngineResults(engines[i], keyword, queries[queryIndex], p));
          }
        }
      }
    }
    // HTML search providers frequently block or time out independently. Run
    // enabled engines concurrently so a failed DuckDuckGo request neither
    // produces a false zero-result search nor forces the user to wait through
    // several serial 20-second timeouts.
    const batches = await Promise.all(pending);
    const discovered: SearchResultItem[] = [];
    let engineSuccess = 0;
    for (let i = 0; i < batches.length; i++) {
      console.info(`ComicReader[debug] engineBatch: index=${i} count=${batches[i].length}`);
      if (batches[i].length > 0) engineSuccess++;
      for (let itemIndex = 0; itemIndex < batches[i].length; itemIndex++) {
        const item = batches[i][itemIndex];
        if (!discovered.some((old: SearchResultItem) => old.url === item.url)) discovered.push(item);
      }
    }
    if (this.searchResultMode !== 'browser' && this.isBroadComicKeyword(keyword)) {
      const expanded = await this.expandBroadComicResults(discovered);
      this.appendResults(expanded);
      this.appendResults(discovered.filter((item: SearchResultItem) => !this.isBroadLandingResult(item)));
    } else {
      this.appendResults(discovered);
    }
    this.debugEngineResults = discovered.length;
    this.debugEngineTried = engines.length;
    this.debugEngineSuccess = engineSuccess;
    this.statusText = this.t('engine_returned') + this.results.length + this.t('items_unit');
    if (this.searchResultMode === 'browser') {
      this.searchPage = browserPages;
      this.hasMoreResults = discovered.length > 0;
    }
  }

  private isBroadLandingResult(item: SearchResultItem): boolean {
    return /(漫画大全|漫画分类|排行榜|榜_|作品分类|全部作品|推荐|版本更新中)/i.test(item.title) ||
      /\/(category|classify|genre|tag|rank|ranking|list|search)(\/|\?|$)/i.test(item.url);
  }

  private async expandBroadComicResults(discovered: SearchResultItem[]): Promise<SearchResultItem[]> {
    const pending: Promise<SearchResultItem[]>[] = [];
    let attempted = 0;
    for (let i = 0; i < discovered.length && attempted < 8; i++) {
      if (!this.isBroadLandingResult(discovered[i])) continue;
      attempted++;
      pending.push(this.fetchComicListingResults(discovered[i]));
    }
    const batches = await Promise.all(pending);
    const expanded: SearchResultItem[] = [];
    for (let batchIndex = 0; batchIndex < batches.length; batchIndex++) {
      for (let itemIndex = 0; itemIndex < batches[batchIndex].length; itemIndex++) {
        const item = batches[batchIndex][itemIndex];
        if (!expanded.some((old: SearchResultItem) => old.url === item.url)) expanded.push(item);
      }
    }
    return expanded;
  }

  private async fetchComicListingResults(landing: SearchResultItem): Promise<SearchResultItem[]> {
    try {
      const rule = this.ruleForItemUrl(landing.url, landing.sourceId);
      const html = await HttpClient.getTextWithTimeout(landing.url, rule.userAgent,
        rule.referer.length > 0 ? rule.referer : landing.url, 8000);
      return parseComicListingResults(html, rule, landing.url);
    } catch (err) {
      return [];
    }
  }

  private isBroadComicKeyword(keyword: string): boolean {
    const compact = keyword.trim().toLowerCase().replace(/\s+/g, '');
    const broad: string[] = [
      '恋爱', '玄幻', '奇幻', '冒险', '热血', '校园', '都市', '古风', '穿越',
      '少女', '少年', '搞笑', '悬疑', '科幻', '武侠', '仙侠', '治愈', '日常',
      '动作', '历史', '竞技', '体育', '音乐', '职场', '美食', '恐怖', '漫画'
    ];
    return broad.indexOf(compact) >= 0;
  }

  private async fetchSearchEngineResults(engine: SearchEngineConfig, keyword: string,
    query: string, page: number): Promise<SearchResultItem[]> {
    try {
      let url = buildSearchEngineUrl(engine, query, this.braveApiKey, this.googleApiKey, this.googleCx);
      if (page > 1) {
        const offset = (page - 1) * 10;
        if (engine.engineType === 'bing-html') url += '&first=' + (offset + 1);
        else if (engine.engineType === 'baidu-html') url += '&pn=' + (offset * 5);
        else if (engine.engineType === 'google-html') url += '&start=' + offset;
        else if (engine.engineType === 'sogou-html') url += '&page=' + page;
        else if (engine.engineType === 'so-html') url += '&pn=' + (offset + 1);
        else if (engine.engineType === 'yandex-html') url += '&p=' + page;
      }
      const body = await HttpClient.getTextWithHeaders(url, searchEngineUserAgent(), '',
        engineHeaders(engine, this.braveApiKey));
      return parseSearchEngineResults(body, engine, keyword, url);
    } catch (err) {
      return [];
    }
  }

  private async searchHtmlRuleSources(keyword: string): Promise<void> {
    if (!this.enableHtmlRules) {
      this.debugRuleTried = 0; this.debugRuleSkipped = this.rules.length; this.debugRuleSuccess = 0; this.debugRuleFailed = 0;
      return;
    }
    let success = 0;
    let failed = 0;
    const maxPerGroup = 15;
    const pending: Promise<SearchResultItem[]>[] = [];
    const pendingRuleNames: string[] = [];
    let attempted = 0;
    let skipped = 0;
    for (let i = 0; i < this.rules.length; i++) {
      const rule = this.rules[i];
      if (rule.searchUrl.trim().length === 0) { skipped++; continue; }
      if (rule.searchMethod === 'url-only') { skipped++; continue; }
      if (attempted >= maxPerGroup * 3) { skipped++; continue; }
      attempted++;
      pending.push(this.fetchHtmlRuleResults(rule, keyword));
      pendingRuleNames.push(rule.name);
    }
    console.info(`ComicReader[debug] searchHtmlRuleSources: attempted=${attempted} skipped=${skipped} rules=${this.rules.length} searchable=${pendingRuleNames.join(', ')}`);
    const batches = await Promise.all(pending);
    for (let batchIndex = 0; batchIndex < batches.length; batchIndex++) {
      const parsed = batches[batchIndex];
      console.info(`ComicReader[debug] htmlRuleResult: rule="${pendingRuleNames[batchIndex]}" count=${parsed.length}`);
      if (parsed.length > 0) {
        success++;
        this.appendResults(parsed);
        this.statusText = this.t('rule_progress') + success + this.t('rule_succeeded') + this.results.length + this.t('rule_current');
      } else {
        failed++;
      }
    }
    this.debugRuleTried = attempted;
    this.debugRuleSkipped = skipped;
    this.debugRuleSuccess = success;
    this.debugRuleFailed = failed;
    console.info(`ComicReader[debug] searchHtmlRuleSources: tried=${attempted} skipped=${skipped} success=${success} failed=${failed} rules=${this.rules.length} online=${this.onlineRules.length} custom=${this.advancedRules.length} mode=${this.searchMode} htmlEnabled=${this.enableHtmlRules}`);
    if (failed > 0 && success === 0) {
      this.statusText = this.t('chapter_failed');
    }
  }

  private async fetchHtmlRuleResults(rule: ComicSourceRule, keyword: string): Promise<SearchResultItem[]> {
    try {
      const searchUrl = rule.searchUrl.replace('{keyword}', encodeURIComponent(keyword));
      console.info(`ComicReader[debug] fetchHtmlRule: rule="${rule.name}" url=${searchUrl}`);
      const html = await HttpClient.getTextWithTimeout(searchUrl, rule.userAgent,
        rule.referer.length > 0 ? rule.referer : rule.homepage, 8000);
      const parsed = parseSearchResults(html, rule, searchUrl, keyword);
      console.info(`ComicReader[debug] fetchHtmlRule: rule="${rule.name}" parsed=${parsed.length} htmlLen=${html.length}`);
      const expected = keyword.toLowerCase().replace(/\s+/g, '');
      const filtered = parsed.filter((item: SearchResultItem) => {
        if (expected.length === 0) return true;
        const actual = (item.title + ' ' + (item.description ?? '') + ' ' + item.url).toLowerCase().replace(/\s+/g, '');
        return actual.indexOf(expected) >= 0;
      });
      const result = filtered.length === 0 && parsed.length > 0 ? parsed.slice(0, 5) : filtered;
      for (let i = 0; i < result.length; i++) {
        result[i].debugMatchInfo = buildDebugMatchInfo(result[i].title, result[i].url, result[i].description ?? '', keyword);
      }
      return result;
    } catch (err) {
      console.info(`ComicReader[debug] fetchHtmlRule: rule="${rule.name}" error=${err}`);
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
    const matchingCatalogItem = this.catalogItemForSourceUrl(url);
    if (matchingCatalogItem !== null) {
      this.currentCatalogItemId = matchingCatalogItem.id;
      this.currentCatalogSourceIndex = this.catalogSourcesByChapterCount(matchingCatalogItem)
        .findIndex((source: CatalogSource) => source.detailUrl === url);
    }
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
      parsedChapters = this.validatedChapterManifest(parsedChapters);
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
          retryChapters = this.validatedChapterManifest(retryChapters);
          if (retryChapters.length > parsedChapters.length) parsedChapters = retryChapters;
        } catch (retryError) {
          // Preserve the best successful response. A failed reliability retry
          // must not turn a legitimate one-shot chapter into a request error.
        }
      }
      this.chapters = parsedChapters;
      if (parsedChapters.length === 0) {
        if (await this.tryNextSearchCandidate()) return;
        this.mode = 'results';
        this.statusText = this.t('no_chapters');
        console.error('ComicReader no chapters matched: rule=' + rule.id + ', url=' + url +
          ', htmlLength=' + html.length);
      } else {
        this.statusText = this.t('found_chapters') + parsedChapters.length + this.t('chapters_unit') + '.';
      }
    } catch (err) {
      if (await this.tryNextSearchCandidate()) return;
      this.mode = 'results';
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

  private async fetchReaderImagesWithPagination(firstUrl: string, rule: ComicSourceRule,
    publishProgress: boolean = true): Promise<ReaderImageItem[]> {
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
      if (publishProgress) this.images = allImages;
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
    this.resetReaderZoom();
    this.applyReaderFullscreen(this.fullscreenReader);
    this.statusText = this.t('generating_scroll');
    try {
      const parsedImages = await this.fetchReaderImagesWithPagination(chapter.url, rule);
      if (parsedImages.length === 0 && await this.tryNextCatalogSource(chapter)) return;
      if (parsedImages.length === 0 && await this.tryNextSearchCandidate()) return;
      this.images = parsedImages;
      if (parsedImages.length === 0) {
        // Never strand the user on an empty fullscreen reader. Keep the
        // directory visible so another chapter/source can be selected.
        this.applyReaderFullscreen(false);
        this.mode = 'chapters';
        this.statusText = this.t('no_images');
        return;
      }
      this.statusText = this.t('scroll_complete') + parsedImages.length + this.t('images_unit_full') + '.';
      this.addHistory(chapter, parsedImages.length);
      this.updateFavoriteReadingPosition();
    } catch (err) {
      if (await this.tryNextCatalogSource(chapter)) return;
      if (await this.tryNextSearchCandidate()) return;
      this.applyReaderFullscreen(false);
      this.mode = 'chapters';
      this.statusText = this.t('scroll_failed');
    } finally {
      this.readerPaginationLoading = false;
    }
  }

  private readerPanLimit(scale: number = this.readerZoomScale): number {
    return Math.max(0, (scale - 1) * this.readerViewportWidth);
  }

  private clampReaderPan(value: number, scale: number = this.readerZoomScale): number {
    const limit = this.readerPanLimit(scale);
    return Math.max(-limit, Math.min(0, value));
  }

  private resetReaderZoom(): void {
    this.readerZoomScale = 1;
    this.readerZoomStartScale = 1;
    this.readerPanX = 0;
    this.readerPanStartX = 0;
  }

  private updateReaderZoom(scale: number): void {
    const nextScale = Math.max(1, Math.min(4, scale));
    const oldLimit = this.readerPanLimit(this.readerZoomScale);
    const nextLimit = this.readerPanLimit(nextScale);
    if (nextScale <= 1.001) {
      this.readerPanX = 0;
    } else if (oldLimit <= 0) {
      // First enlargement keeps the center of the page under the reader.
      this.readerPanX = -nextLimit / 2;
    } else {
      this.readerPanX = this.clampReaderPan(this.readerPanX * nextLimit / oldLimit, nextScale);
    }
    this.readerZoomScale = nextScale;
  }

  private displayedReaderImages(): ReaderImageItem[] {
    return this.images.slice(0, Math.min(this.images.length, this.readerRenderLimit));
  }

  private catalogSourcesByChapterCount(item: CatalogItem): CatalogSource[] {
    const sources = [...item.sources];
    sources.sort((left: CatalogSource, right: CatalogSource): number =>
      (right.chapters ? right.chapters.length : 0) - (left.chapters ? left.chapters.length : 0));
    return sources;
  }

  private catalogItemForSourceUrl(url: string): CatalogItem | null {
    if (this.remoteCatalog === null) return null;
    const items = CatalogService.getAllItems(this.remoteCatalog);
    for (let i = 0; i < items.length; i++) {
      if (items[i].sources.some((source: CatalogSource) => source.detailUrl === url)) return items[i];
    }
    return null;
  }

  private async tryNextCatalogSource(failedChapter: ChapterItem): Promise<boolean> {
    if (this.remoteCatalog === null || this.currentCatalogItemId.length === 0) return false;
    const item = CatalogService.getAllItems(this.remoteCatalog)
      .find((candidate: CatalogItem) => candidate.id === this.currentCatalogItemId);
    if (!item) return false;
    const sources = this.catalogSourcesByChapterCount(item);
    for (let index = this.currentCatalogSourceIndex + 1; index < sources.length; index++) {
      const source = sources[index];
      if (!source.detailUrl || !source.chapters || source.chapters.length === 0) continue;
      const chapterIndex = Math.max(0, failedChapter.index - 1);
      const target = source.chapters.find((candidate) => candidate.title === failedChapter.title) ??
        source.chapters[Math.min(chapterIndex, source.chapters.length - 1)];
      if (!target) continue;
      this.currentCatalogSourceIndex = index;
      this.currentDetailUrl = source.detailUrl;
      this.currentCover = source.coverUrl ? source.coverUrl : this.currentCover;
      this.chapters = source.chapters.map((chapter, sourceIndex: number): ChapterItem => ({
        title: chapter.title, url: chapter.url, index: sourceIndex + 1,
        sourceId: this.findRuleByUrl(source.detailUrl!).id, sourceName: source.domain
      }));
      this.statusText = this.isEn() ? 'Trying fallback source ' + source.domain : '正在切换备用来源：' + source.domain;
      await this.loadChapter({ title: target.title, url: target.url, index: chapterIndex + 1,
        sourceId: this.findRuleByUrl(source.detailUrl).id, sourceName: source.domain },
        this.findRuleByUrl(source.detailUrl));
      return true;
    }
    return false;
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
      const oldLength = this.images.length;
      const nextImages = await this.fetchReaderImagesWithPagination(nextChapter.url,
        this.findRule(nextChapter.sourceId), false);
      if (nextImages.length === 0) return;
      const appended: ReaderImageItem[] = [...this.images];
      for (let i = 0; i < nextImages.length; i++) {
        appended.push({ url: nextImages[i].url, index: oldLength + i + 1, status: 'waiting' });
      }
      this.currentChapterTitle = nextChapter.title;
      this.currentUrl = nextChapter.url;
      this.currentSourceId = nextChapter.sourceId;
      this.currentSourceName = nextChapter.sourceName;
      this.images = appended;
      this.readerRenderLimit = Math.min(appended.length, oldLength + 6);
      this.addHistory(nextChapter, nextImages.length);
      this.updateFavoriteReadingPosition();
      this.statusText = this.isEn() ? 'Continued to ' + nextChapter.title : '已连续加载 ' + nextChapter.title;
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
        return leftNumber - rightNumber;
      }
      return 0;
    });
    if (!this.chapterReversed) source.reverse();
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

  private openInBrowser(url: string, title: string): void {
    if (!url.startsWith('http://') && !url.startsWith('https://')) return;
    router.pushUrl({ url: 'pages/WebBrowserPage', params: { url: url, title: title, isDark: this.isDark(), statusBarHeight: this.avoidStatusBarHeight } });
  }

  private handleWebError(errorInfo: string): void {
    this.webMainFrameFailed = true;
    if (errorInfo.indexOf('ERR_CONNECTION_CLOSED') >= 0 && this.webLastSuccessUrl.length > 0) {
      this.webLoading = true;
      this.webErrorText = '';
      const restoreUrl: string = this.webLastSuccessUrl;
      this.webLoadTimerId = setTimeout((): void => {
        try { this.webController.loadUrl(restoreUrl); }
        catch (error) { this.webLoading = false; this.webErrorText = errorInfo; }
      }, 1500);
      return;
    }
    this.webLoading = false;
    this.webErrorText = errorInfo;
  }

  private webOpenInReader(): void {
    const url: string = this.webLastSuccessUrl.length > 0 ? this.webLastSuccessUrl : this.searchEngineUrl;
    if (url.length === 0) return;
    this.openSearchResult({ title: this.searchTitle, url: url, cover: '', sourceId: '', sourceName: '', isChapter: false, resultType: 'search-engine', groupName: this.searchTitle, description: '', category: '' });
  }

  private injectSearchPageStyles(): void {
    const debugHtml = '';
    const css = `
      #sb_form,#b_header,.b_scopeTabs,#id_h,#b_notificationContainer,#b_context,.b_ans,.b_foot,
      #search-form,.navbar,#s_topwrap,#u,#u1,#s_tab,.head_nums_cont_outer,#content_right,
      #searchform,.gb_3d,#gb,.minidiv,.cOl5Id,#topstuff,.kpSBl,
      .top-box,.logo-box,#searchForm,.header,
      .serp-header,.search2,.navigation,.header__content,
      #rs,#taw,#tadsform,.commercial-unit-top,.commercial-unit-desktop-rhs,
      .b_pagination,#b_pagination,.pagination,#pagebar,.pagebar,.pager,#pg,
      .page-inner,#page,.pagebox,.p-goto,#footcnt,.AaVjI,.pp-loading,
      .page,#paging,.search-result-pagination,.results-pagination,
      #nav,.nav,.pagebar_container,.page-nav,.p-nav,.sw_next,.sw_prev,
      .sb_pagN,.sb_pagP,#pnnext,#sogou_next,#next,.pager__item_kind_next,
      .search-filters,.filters,.side,.results--side,.js-result-aside,
      .b_ad,#b_ad,.b_adlink,.b_adBottom,.b_adslim,.b_algoAns,.b_caption,.b_adGroup,
      .ec_tvc,.ec_wise_ad,.ec_youxuan,.ec_im_container,.ec_bdtg,.ec_wise_box,
      #content_right .result-op:not([tpl="recommend_list"]),
      ins.adsbygoogle,[id*="google_ads"],[id*="div-gpt-ad"],
      iframe[src*="doubleclick.net"],iframe[src*="googlesyndication.com"],iframe[src*="adserver"],
      [class*="float-ad"],[class*="floatad"],[class*="float_ad"],
      #coupletLeft,#coupletRight,#fixedAd,#floatAd,#ad_header,#ad_footer,
      [class*="sticky-ad"],[class*="fixed-ad"],[class*="popup-ad"],[class*="ad-popup"],[class*="ad-modal"],
      [class*="sponsored"],[id*="sponsored"],[class*="promotion-box"],
      [class*="ad-banner"],[class*="ad-container"],[class*="ad-wrapper"],[class*="ad-slot"],[class*="ad-unit"],
      [class*="banner-ad"],[id*="banner-ad"],[class*="ad-float"],[id*="ad-float"],
      [class*="advertisement"],[id*="advertisement"],[class*="ad-300"],[class*="ad-728"],[class*="ad-970"],
      [class*="ad-top"],[class*="ad-bottom"],[class*="ad-side"],[class*="ad-left"],[class*="ad-right"],
      [class*="top-ad"],[class*="bottom-ad"],[class*="side-ad"],[class*="left-ad"],[class*="right-ad"],
      [class*="ad-interstitial"],[class*="ad-between"],[class*="ad-inline"],
      [class*="ad-overlay"],[id*="ad-overlay"],[class*="ad-mask"],[id*="ad-mask"],
      [class*="commercial-unit"],[id*="commercial-unit"],[class*="promo-ad"],
      [class*="recommend-ad"],[class*="hot-ad"],[class*="trend-ad"],
      [data-ad],[data-ads],[data-ad-slot],[data-ad-unit],[data-ad-client],
      #ad1,#ad2,#ad3,#ad4,#ad5,#ad6,#ad7,#ad8,#ad9,#ad0,
      .topad,.bottomad,.leftad,.rightad,.adbox,.ad_box,.ads,.adsbox,.adblock,.ad_block
      { display:none !important; }
      body { padding-top:${this.headerOverlayHeight() + 25}px !important; padding-bottom:200px !important; margin-top:0 !important; box-sizing:border-box; }
      #b_content,#results,.results,#search-results,.serp-list,#content_left,#rso
      { width:100% !important; max-width:100% !important; }
      html, body { background:${this.isDark() ? '#1a1a1a' : '#fff'} !important; color:${this.isDark() ? '#e0e0e0' : '#1a1a1a'} !important; }
      #b_results,#b_content,#b_algo,#content_left,#rso,.results,.serp-list,#results
      { background:${this.isDark() ? '#1a1a1a' : '#fff'} !important; }
      #b_content * { background:transparent !important; }
      #b_results * { color:${this.isDark() ? '#e0e0e0' : '#1a1a1a'} !important; }
      #b_results a, #b_results a * { color:${this.isDark() ? '#4a9eff' : '#0066c0'} !important; }
      .results .result, .results .result * { color:${this.isDark() ? '#e0e0e0' : '#1a1a1a'} !important; }
      .results .result a, .results .result .result__a { color:${this.isDark() ? '#4a9eff' : '#0066c0'} !important; }
      .results .result .result__url, .results .result .result__url * { color:${this.isDark() ? '#6a9955' : '#006621'} !important; font-size:13px !important; }
      .results .result .result__snippet { color:${this.isDark() ? '#b0b0b0' : '#555555'} !important; }
      #b_results > li.b_algo, #b_results > .b_algo, .result, .c-container, .vrwrap, .res-list, .serp-item
      { background:${this.isDark() ? '#2a2a2a' : '#fff'} !important; margin:0 !important; padding:12px 16px !important; border-radius:0 !important; box-shadow:none !important; border:none !important; }
      li.b_algo *, .b_algo *, .result *, .c-container *, .vrwrap *, .res-list *, .serp-item *
      { border:none !important; background:transparent !important; }
      #b_results > li.b_algo, #b_results > .b_algo, .result, .c-container, .vrwrap, .res-list, .serp-item
      { background:${this.isDark() ? '#2a2a2a' : '#fff'} !important; }
      li.b_algo cite, .b_algo cite, li.b_algo .b_caption, .b_algo .b_caption, li.b_algo .b_algoSlug, .b_algo .b_algoSlug
      { color:${this.isDark() ? '#6a9955' : '#006621'} !important; }
      li.b_algo h2, .b_algo h2
      { background:transparent !important; }
      #b_results strong, #b_results b, #b_results em
      { font-weight:bold !important; }
    `;
    const js = `
      if(!window._styleInjected){
        window._styleInjected=true;
        var s=document.createElement('style');
        s.textContent=${JSON.stringify(css)};
        document.head.appendChild(s);
      }
      var dbg=document.getElementById('app_debug');
      if(!dbg && ${JSON.stringify(debugHtml)}.length>0){
        dbg=document.createElement('div');
        dbg.innerHTML=${JSON.stringify(debugHtml)};
        var firstChild=document.body.firstChild;
        if(firstChild) document.body.insertBefore(dbg,firstChild);
        else document.body.appendChild(dbg);
      }
      if(!window._styleResults){
        window._styleResults=function(scope){
          var dark=${JSON.stringify(this.isDark())};
          var C_TEXT=dark?'#e0e0e0':'#1a1a1a';
          var C_LINK=dark?'#4a9eff':'#0066c0';
          var C_URL=dark?'#6a9955':'#006621';
          var C_DESC=dark?'#b0b0b0':'#555555';
          var C_BG=dark?'#2a2a2a':'#ffffff';
          var sel='li.b_algo,.b_algo,.result,.c-container,.vrwrap,.res-list,.serp-item';
          var list=scope.querySelectorAll(sel);
          for(var i=0;i<list.length;i++){
            var it=list[i];
            it.style.setProperty('background',C_BG,'important');
            it.style.setProperty('margin','0','important');
            it.style.setProperty('padding','10px 14px','important');
            it.style.setProperty('border','none','important');
            it.style.setProperty('border-radius','0','important');
            it.style.setProperty('box-shadow','none','important');
            var subs=it.querySelectorAll('*');
            for(var j=0;j<subs.length;j++){
              var el=subs[j];
              var tag=el.tagName?el.tagName.toLowerCase():'';
              el.style.setProperty('border','none','important');
              el.style.setProperty('background-color','transparent','important');
              el.style.setProperty('text-decoration','none','important');
              el.style.setProperty('box-shadow','none','important');
              el.style.setProperty('margin','0','important');
              el.style.setProperty('padding','0','important');
              if(tag==='strong'||tag==='b'||tag==='em'){
                el.style.setProperty('font-weight','bold','important');
                el.style.setProperty('color','#d32f2f','important');
              }else if(tag==='a'){
                el.style.setProperty('color',C_LINK,'important');
                var hasTitle=el.querySelector?el.querySelector('h2,h3'):null;
                if(hasTitle){
                  el.style.setProperty('font-size','18px','important');
                  el.style.setProperty('font-weight','600','important');
                  el.style.setProperty('line-height','1.3','important');
                  el.style.setProperty('display','block','important');
                  el.style.setProperty('margin','0 0 3px 0','important');
                }
              }else if(tag==='cite'){
                el.style.setProperty('color',C_URL,'important');
                el.style.setProperty('font-size','13px','important');
                el.style.setProperty('line-height','1.3','important');
                el.style.setProperty('display','block','important');
                el.style.setProperty('margin','0 0 3px 0','important');
              }else if(tag==='h2'||tag==='h3'){
                var inLink=el.closest?el.closest('a'):null;
                if(!inLink){
                  el.style.setProperty('color',C_LINK,'important');
                  el.style.setProperty('font-size','18px','important');
                  el.style.setProperty('font-weight','600','important');
                  el.style.setProperty('line-height','1.3','important');
                  el.style.setProperty('margin','0 0 3px 0','important');
                }
              }else if(el.closest&&(el.closest('a')||el.closest('h2')||el.closest('h3'))){
              }else if(tag==='p'||tag==='span'||tag==='div'){
                el.style.setProperty('color',C_DESC,'important');
                el.style.setProperty('font-size','14px','important');
                el.style.setProperty('line-height','1.4','important');
              }else{
                el.style.setProperty('color',C_TEXT,'important');
              }
            }
          }
        };
      }
      if(!window._hidePagination){
        window._hidePagination=function(){
          var sels='.b_pagination,#b_pagination,.pagination,#pagebar,.pagebar,.pager,#pg,.page-inner,#page,.pagebox,.p-goto,#footcnt,.page,#paging,.search-result-pagination,.results-pagination,#nav,.nav,.pagebar_container,.page-nav,.p-nav,.sb_pagN,.sb_pagP,#pnnext,#sogou_next,#next,.pager__item_kind_next,.sw_next,.sw_prev,.pp-loading,.foot,.footer,#footer,#foot';
          var els=document.querySelectorAll(sels);
          for(var i=0;i<els.length;i++){ els[i].style.display='none'; }
          var nextKeywords=['下一页','下页','Next','Next page','>','→','›','»'];
          var all=document.querySelectorAll('a,button,span,div,li');
          for(var j=0;j<all.length;j++){
            var t=all[j].textContent.trim();
            var aria=all[j].getAttribute('aria-label')||'';
            for(var ni=0;ni<nextKeywords.length;ni++){
              if(t===nextKeywords[ni]||aria.indexOf('Next')>=0||aria.indexOf('下一页')>=0){
                var p=all[j].parentElement;
                if(p) p.style.display='none';
                break;
              }
            }
          }
          var navs=document.querySelectorAll('[role="navigation"],[role="pager"]');
          for(var m=0;m<navs.length;m++){
            var nt=navs[m].textContent;
            if(nt.indexOf('下一页')>=0||nt.indexOf('Next')>=0||nt.length<80){ navs[m].style.display='none'; }
          }
        };
      }
      window._hidePagination();
      if(window._styleResults) window._styleResults(document);
      if(!window._scrollListenerAdded){
        window._scrollListenerAdded=true;
        window._loadingNext=false;
        window._nextUrl='';
        window._pageCount=1;
        window._constructNextUrl=function(url){
          if(!url) return '';
          if(url.indexOf('bing.com')>=0){
            var m=url.match(/first=(\d+)/);
            var cur=m?parseInt(m[1]):1;
            var next=cur+10;
            var sep=url.indexOf('?')>=0?'&':'?';
            if(m) return url.replace(/first=\d+/,'first='+next);
            return url+sep+'first='+next;
          }
          if(url.indexOf('baidu.com')>=0){
            var m2=url.match(/pn=(\d+)/);
            var cur2=m2?parseInt(m2[1]):0;
            var next2=cur2+10;
            var sep2=url.indexOf('?')>=0?'&':'?';
            if(m2) return url.replace(/pn=\d+/,'pn='+next2);
            return url+sep2+'pn='+next2;
          }
          if(url.indexOf('google.com')>=0||url.indexOf('google.cn')>=0){
            var m3=url.match(/start=(\d+)/);
            var cur3=m3?parseInt(m3[1]):0;
            var next3=cur3+10;
            var sep3=url.indexOf('?')>=0?'&':'?';
            if(m3) return url.replace(/start=\d+/,'start='+next3);
            return url+sep3+'start='+next3;
          }
          if(url.indexOf('sogou.com')>=0){
            var m4=url.match(/page=(\d+)/);
            var cur4=m4?parseInt(m4[1]):1;
            var next4=cur4+1;
            var sep4=url.indexOf('?')>=0?'&':'?';
            if(m4) return url.replace(/page=\d+/,'page='+next4);
            return url+sep4+'page='+next4;
          }
          return '';
        };
        window._findNextUrl=function(doc, fallbackUrl){
          var links=doc.querySelectorAll('a');
          for(var i=0;i<links.length;i++){
            var t=links[i].textContent.trim();
            var aria=links[i].getAttribute('aria-label')||'';
            var rel=links[i].getAttribute('rel')||'';
            var cls=links[i].className||'';
            if(rel.indexOf('next')>=0||cls.indexOf('sb_pagN')>=0||cls.indexOf('sb_pagN')>=0){
              var h=links[i].href||links[i].getAttribute('href')||'';
              if(h.length>0 && h.indexOf('javascript:')<0 && h.indexOf('#')<0) return h;
            }
            if(t==='下一页'||t==='下页'||t==='Next'||t==='Next page'||aria==='Next page'||aria==='下一页'){
              var h2=links[i].href||links[i].getAttribute('href')||'';
              if(h2.length>0 && h2.indexOf('javascript:')<0 && h2.indexOf('#')<0) return h2;
            }
          }
          return window._constructNextUrl(fallbackUrl||location.href);
        };
        window._debugMode=${this.showDebugInfo};
        window._updateDebug=function(){
          if(!window._debugMode){
            var old=document.getElementById('app_debug');
            if(old) old.remove();
            return;
          }
          var dbg=document.getElementById('app_debug');
          if(!dbg){
            dbg=document.createElement('div');
            dbg.id='app_debug';
            dbg.style.cssText='background:#1a1a1a !important;color:#e0e0e0 !important;font-size:12px !important;padding:8px 12px !important;margin:8px !important;border-radius:8px !important;border:1px solid #444 !important;z-index:999999 !important;';
            var fc=document.body.firstChild;
            if(fc) document.body.insertBefore(dbg,fc);
            else document.body.appendChild(dbg);
          }
          var remain=Math.round(document.body.scrollHeight-window.innerHeight-window.scrollY);
          var nu=window._nextUrl||'';
          if(nu.length>80) nu=nu.substring(0,80)+'...';
          var qParam='';
          try{
            var u=new URL(location.href);
            qParam=u.searchParams.get('q')||u.searchParams.get('wd')||u.searchParams.get('query')||'';
          }catch(e){}
          var searchBox='';
          try{
            var inputs=document.querySelectorAll('input[name="q"],input[name="wd"],#sb_form_q,textarea[name="q"]');
            for(var si=0;si<inputs.length;si++){
              if(inputs[si].value&&inputs[si].value.length>0){ searchBox=inputs[si].value; break; }
            }
          }catch(e){}
          var lines=[
            '<div style="color:#0066cc;">URL: '+location.href.substring(0,80)+'</div>',
            '<div style="color:#0a0;">页面查询词(URL q参数): '+qParam+'</div>',
            '<div style="color:#0a0;">搜索框文本: '+searchBox+'</div>',
            '<div style="color:#e00;">滚动: remain='+remain+' page='+window._pageCount+' loading='+window._loadingNext+'</div>',
            '<div style="color:#e00;">nextUrl: '+nu+'</div>'
          ];
          var extra=window._debugExtra||'';
          var newHtml=lines.join('')+extra;
          if(dbg.innerHTML!==newHtml) dbg.innerHTML=newHtml;
        };
        window._updateDebug();
        window.addEventListener('scroll',function(){
          var remain=document.body.scrollHeight-window.innerHeight-window.scrollY;
          if(remain>500) return;
          if(window._loadingNext) return;
          if(!window._nextUrl) window._nextUrl=window._findNextUrl(document);
          if(!window._nextUrl){
            var dbg=document.getElementById('app_debug');
            if(dbg) dbg.setAttribute('data-extra','<div style="color:#e00;">到底了但没找到nextUrl</div>');
            window._debugExtra='到底了但没找到nextUrl';
            return;
          }
          window._loadingNext=true;
          if(window._updateDebug) window._updateDebug();
          var ifr=document.createElement('iframe');
          ifr.style.cssText='position:fixed;left:-9999px;top:0;width:1px;height:1px;border:0;';
          ifr.onload=function(){
            try{
              var idoc=ifr.contentDocument||ifr.contentWindow.document;
              var itemSel='li.b_algo,.b_algo,#b_results .b_algo,.result,.c-container,.vrwrap,.res-list,.serp-item,.g .rc,.results > div';
              var items=idoc.querySelectorAll(itemSel);
              var c=document.querySelector('#b_results,#b_content,#content_left,#rso,.results,.serp-list,#results');
              var dbg2=document.getElementById('app_debug');
              if(dbg2) dbg2.setAttribute('data-extra','<div style="color:#e00;">iframe加载: '+items.length+'条结果 container='+(c?'有':'无')+'</div>');
              window._debugExtra='iframe加载: '+items.length+'条结果 container='+(c?'有':'无');
              if(c && items.length>0){
                if(window._debugMode){
                  var sep=document.createElement('div');
                  sep.style.cssText='padding:10px;text-align:center;color:#999;font-size:12px;border-top:1px solid #e5e5e5;';
                  sep.textContent='— 第'+(window._pageCount+1)+'页 —';
                  c.appendChild(sep);
                }
                for(var i=0;i<items.length;i++){
                  var node=document.importNode(items[i],true);
                  c.appendChild(node);
                }
                if(window._styleResults) window._styleResults(c);
                window._pageCount++;
              }
              window._nextUrl=window._findNextUrl(idoc, window._nextUrl);
            }catch(e){
              var dbg3=document.getElementById('app_debug');
              if(dbg3) dbg3.setAttribute('data-extra','<div style="color:#e00;">iframe错误: '+e+'</div>');
              window._debugExtra='iframe错误: '+e;
            }
            ifr.remove();
            window._loadingNext=false;
            if(window._hidePagination) window._hidePagination();
            if(window._updateDebug) window._updateDebug();
          };
          ifr.src=window._nextUrl;
          document.body.appendChild(ifr);
        },{passive:true});
        setInterval(function(){
          if(window._updateDebug) window._updateDebug();
          if(window._styleResults) window._styleResults(document);
        },5000);
      }
    `;
    try { this.webController.runJavaScript(js); }
    catch (error) { console.info('ComicReader[debug] injectJS failed: ' + error); }
  }

  private openSearchResult(item: SearchResultItem): void {
    this.lastOpenedSearchUrl = item.url;
    const verifiedItem = this.catalogItemForExactTitle(item.title) ?? this.catalogItemForExactTitle(this.searchTitle);
    const verifiedSource = verifiedItem ? this.preferredCatalogSource(verifiedItem) : null;
    const candidates: SearchResultItem[] = [];
    if (verifiedSource && verifiedSource.detailUrl) {
      candidates.push({ title: verifiedItem!.title, url: verifiedSource.detailUrl,
        cover: verifiedSource.coverUrl ?? '', sourceId: this.findRuleByUrl(verifiedSource.detailUrl).id,
        sourceName: verifiedSource.domain, isChapter: false, resultType: 'catalog',
        groupName: verifiedItem!.title, description: '线上回放验证来源', category: verifiedItem!.category });
    }
    candidates.push(item);
    const key = this.searchTitleKey(item.title);
    for (let i = 0; i < this.results.length; i++) {
      const candidate = this.results[i];
      if (candidate.url === item.url || this.searchTitleKey(candidate.title) !== key) continue;
      candidates.push(candidate);
    }
    candidates.sort((left: SearchResultItem, right: SearchResultItem): number =>
      this.searchCandidateScore(right) - this.searchCandidateScore(left));
    this.searchFallbackCandidates = candidates.filter((candidate: SearchResultItem, index: number) =>
      candidates.findIndex((old: SearchResultItem) => old.url === candidate.url) === index);
    this.searchFallbackIndex = 0;
    this.searchFallbackDiscoveryAttempted = false;
    const first = this.searchFallbackCandidates[0];
    const rule = this.ruleForItemUrl(first.url, first.sourceId);
    const detailCandidate = this.searchFallbackCandidates.find((c: SearchResultItem) => !c.isChapter);
    this.currentCover = first.cover.length > 0 ? first.cover : (detailCandidate ? detailCandidate.cover : this.currentCover);
    if (first.isChapter) {
      this.currentDetailUrl = detailCandidate ? detailCandidate.url : '';
      this.loadChapter({ title: first.title, url: first.url, index: 1, sourceId: first.sourceId, sourceName: first.sourceName }, rule);
    }
    else this.loadDetail(first.url, first.title, rule);
  }

  private searchCandidateScore(item: SearchResultItem): number {
    const rule = this.findRuleByUrl(item.url);
    const readerCapable = rule.readerImageRegex.indexOf('__NO_IMAGE_SCRAPING') < 0;
    if (!readerCapable) return -500;
    if (item.resultType === 'catalog') return 1000;
    return rule.id !== this.genericRule().id ? 100 : 0;
  }

  private catalogItemForExactTitle(title: string): CatalogItem | null {
    if (this.remoteCatalog === null) return null;
    const key = this.coverTitleKey(title);
    const found = CatalogService.getAllItems(this.remoteCatalog)
      .find((item: CatalogItem) => this.coverTitleKey(item.title) === key);
    return found ? found : null;
  }

  private async tryNextSearchCandidate(): Promise<boolean> {
    if (this.searchFallbackIndex < 0) return false;
    if (this.searchFallbackIndex + 1 >= this.searchFallbackCandidates.length &&
      !this.searchFallbackDiscoveryAttempted) {
      this.searchFallbackDiscoveryAttempted = true;
      const current = this.searchFallbackCandidates[this.searchFallbackIndex];
      const title = current ? current.title : this.currentTitle;
      const discovered = await this.discoverFallbackCandidates(title);
      for (let i = 0; i < discovered.length; i++) {
        if (!this.searchFallbackCandidates.some((old: SearchResultItem) => old.url === discovered[i].url)) {
          this.searchFallbackCandidates.push(discovered[i]);
        }
      }
      const attempted = this.searchFallbackCandidates.slice(0, this.searchFallbackIndex + 1);
      const remaining = this.searchFallbackCandidates.slice(this.searchFallbackIndex + 1);
      remaining.sort((left: SearchResultItem, right: SearchResultItem): number =>
        this.searchCandidateScore(right) - this.searchCandidateScore(left));
      this.searchFallbackCandidates = attempted.concat(remaining);
    }
    if (this.searchFallbackIndex + 1 >= this.searchFallbackCandidates.length) return false;
    this.searchFallbackIndex++;
    const next = this.searchFallbackCandidates[this.searchFallbackIndex];
    this.statusText = this.isEn() ? 'Trying another readable source...' :
      '当前来源不可读，正在尝试备用来源 ' + (this.searchFallbackIndex + 1) + '/' + this.searchFallbackCandidates.length;
    await this.loadDetail(next.url, next.title, this.ruleForItemUrl(next.url, next.sourceId));
    return true;
  }

  private validatedChapterManifest(chapters: ChapterItem[]): ChapterItem[] {
    const filtered = chapters.filter((chapter: ChapterItem) => {
      const title = chapter.title.trim();
      if (/漫画最新话$/i.test(title) && this.searchTitleKey(title) !== this.searchTitleKey(this.currentTitle)) return false;
      return true;
    });
    if (filtered.length === 0 || filtered.length > 2) return filtered;
    const meaningful = filtered.filter((chapter: ChapterItem) =>
      /(\d+|第.+[话章节回卷]|序章|序言|番外|最终话|完结篇|短篇|全一|chapter|episode)/i.test(chapter.title));
    return meaningful.length > 0 ? filtered : [];
  }

  private async discoverFallbackCandidates(title: string): Promise<SearchResultItem[]> {
    const keyword = this.cleanTitle(title);
    if (keyword.length === 0) return [];
    const candidates: SearchResultItem[] = [];
    const catalogItem = this.catalogItemForExactTitle(keyword);
    if (catalogItem !== null) {
      const sources = this.catalogSourcesByChapterCount(catalogItem);
      for (let i = 0; i < sources.length; i++) {
        const detailUrl = sources[i].detailUrl ?? '';
        if (detailUrl.length === 0) continue;
        candidates.push({ title: catalogItem.title, url: detailUrl,
          cover: sources[i].coverUrl ?? '', sourceId: this.findRuleByUrl(detailUrl).id,
          sourceName: sources[i].domain, isChapter: false, resultType: 'catalog',
          groupName: catalogItem.title,
          description: '线上验证来源 · ' + (sources[i].chapters ? sources[i].chapters!.length : 0) + this.t('chapters_unit'),
          category: catalogItem.category });
      }
    }
    const queries: string[] = [
      buildEngineQuery(keyword, this.extraSearchTerms, this.languageMode, this.siteHint)
    ];
    const pending: Promise<SearchResultItem[]>[] = [];
    for (let i = 0; i < this.searchEngines.length; i++) {
      const engine = this.searchEngines[i];
      if (!engine.enabled || !isEngineConfigured(engine, this.braveApiKey, this.googleApiKey, this.googleCx)) continue;
      for (let queryIndex = 0; queryIndex < queries.length; queryIndex++) {
        pending.push(this.fetchSearchEngineResults(engine, keyword, queries[queryIndex], 1));
      }
    }
    const batches = await Promise.all(pending);
    const key = this.searchTitleKey(keyword);
    for (let batchIndex = 0; batchIndex < batches.length; batchIndex++) {
      for (let itemIndex = 0; itemIndex < batches[batchIndex].length; itemIndex++) {
        const item = batches[batchIndex][itemIndex];
        if (this.searchTitleKey(item.title) !== key || this.isBroadLandingResult(item)) continue;
        if (!candidates.some((old: SearchResultItem) => old.url === item.url)) candidates.push(item);
      }
    }
    return candidates.slice(0, 24);
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
      const old = this.history[i];
      const sameBook = item.detailUrl && item.detailUrl.length > 0 && old.detailUrl && old.detailUrl.length > 0
        ? old.detailUrl === item.detailUrl
        : old.title === item.title && old.sourceId === item.sourceId;
      if (!sameBook) next.push(old);
    }
    this.history = next;
    this.persistData();
  }

  private latestHistoryPerBook(items: ReadingHistoryItem[]): ReadingHistoryItem[] {
    const latest: ReadingHistoryItem[] = [];
    for (let i = 0; i < items.length && latest.length < 40; i++) {
      const item = items[i];
      const duplicate = latest.some((old: ReadingHistoryItem) => {
        if (item.detailUrl && item.detailUrl.length > 0 && old.detailUrl && old.detailUrl.length > 0) {
          return old.detailUrl === item.detailUrl;
        }
        return old.title === item.title && old.sourceId === item.sourceId;
      });
      if (!duplicate) latest.push(item);
    }
    return latest;
  }

  private async openBookUnified(detailUrl: string, title: string, sourceId: string,
    cover: string, chapterUrl: string = '', chapterTitle: string = ''): Promise<void> {
    const rule = this.findRule(sourceId);
    this.currentCover = cover;
    await this.loadDetail(detailUrl, title, rule);
    if (chapterUrl.length === 0 || chapterUrl === detailUrl) return;
    this.currentUrl = chapterUrl;
    this.currentChapterTitle = chapterTitle;
    this.scrollToCurrentChapter();
  }

  private async openHistoryItem(item: ReadingHistoryItem): Promise<void> {
    this.chapters = [{ title: item.chapterTitle, url: item.url, index: 1,
      sourceId: item.sourceId, sourceName: item.sourceName }];
    this.currentCover = item.cover;
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

  private async refreshBookCover(itemUrl: string): Promise<boolean> {
    let remoteCover = '';
    let bookTitle = '';
    for (let i = 0; i < this.bookshelf.length; i++) {
      if (this.bookshelf[i].url === itemUrl) {
        bookTitle = this.bookshelf[i].title;
        const rc = this.bookshelf[i].remoteCover;
        if (rc !== undefined && rc.length > 0) {
          remoteCover = rc;
        } else {
          remoteCover = this.bookshelf[i].cover;
        }
        break;
      }
    }
    if (remoteCover.length === 0) {
      for (let i = 0; i < this.history.length; i++) {
        if (this.history[i].url === itemUrl) {
          if (bookTitle.length === 0) bookTitle = this.history[i].title;
          remoteCover = this.history[i].cover;
          break;
        }
      }
    }
    const hasOnlineCover = /^https?:\/\//i.test(remoteCover);
    if (hasOnlineCover) {
      this.statusText = this.isEn() ? 'Updating cover from online...' : '正在从在线更新封面…';
    } else {
      this.statusText = this.isEn() ? 'Updating cover from local sources...' : '正在从本地校对更新封面…';
    }
    if (!hasOnlineCover) {
      if (bookTitle.length > 0) {
        const fallbackCover = await this.builtinCoverForTitle(bookTitle, itemUrl);
        if (fallbackCover.length > 0) {
          remoteCover = fallbackCover;
        }
      }
    }
    if (!/^https?:\/\//i.test(remoteCover)) {
      this.statusText = this.t('cover_no_source');
      return false;
    }
    const localPath = this.coverCacheDir + '/' + this.coverCacheName(remoteCover);
    try {
      if (fs.accessSync(localPath)) fs.unlinkSync(localPath);
    } catch (ignored) {
    }
    await this.cacheBookshelfCover(itemUrl, remoteCover);
    this.statusText = this.t('cover_update_success');
    return true;
  }

  private async builtinCoverForTitle(title: string, itemUrl: string): Promise<string> {
    const verified = this.verifiedCoverForTitle(title);
    if (verified && verified.coverUrl.startsWith('https://')) return verified.coverUrl;
    const catalogItem = this.catalogItemForExactTitle(title);
    if (catalogItem !== null) {
      const coverFromCatalog = this.catalogItemCover(catalogItem);
      if (coverFromCatalog.length > 0) return coverFromCatalog;
      const source = this.preferredCatalogSource(catalogItem);
      if (source !== null && source.coverUrl && source.coverUrl.length > 0) return source.coverUrl;
    }
    const rule = this.findRuleByUrl(itemUrl);
    if (rule.id !== this.genericRule().id && rule.searchUrl.length > 0 && rule.searchItemRegex.length > 0) {
      try {
        const searchUrl = rule.searchUrl.replace('{query}', encodeURIComponent(title));
        const html = await HttpClient.getText(searchUrl, rule.userAgent, rule.homepage);
        const results = parseSearchResults(html, rule, searchUrl, title);
        if (results.length > 0 && results[0].cover.length > 0) {
          return results[0].cover;
        }
      } catch (e) {
        console.error('ComicReader builtin cover fallback failed: ' + JSON.stringify(e));
      }
    }
    const engine = this.selectedEngine();
    if (isEngineConfigured(engine, this.braveApiKey, this.googleApiKey, this.googleCx)) {
      try {
        const engineResults = await this.fetchSearchEngineResults(engine, title, title, 1);
        const targetKey = this.searchTitleKey(title);
        for (let i = 0; i < engineResults.length && i < 10; i++) {
          const cand = engineResults[i];
          const candKey = this.searchTitleKey(cand.title);
          if (candKey !== targetKey && !(targetKey.length >= 2 && candKey.indexOf(targetKey) >= 0)) continue;
          if (cand.cover.length > 0) return cand.cover;
          const detailRule = this.ruleForItemUrl(cand.url, cand.sourceId);
          const detailHtml = await HttpClient.getTextWithTimeout(cand.url, detailRule.userAgent,
            detailRule.referer.length > 0 ? detailRule.referer : cand.url, 8000);
          const imgs = parseImages(detailHtml, detailRule, cand.url);
          if (imgs.length > 0) return imgs[0].url;
        }
      } catch (e) {
        console.error('ComicReader builtin cover engine fallback failed: ' + JSON.stringify(e));
      }
    }
    return '';
  }

  private addCurrentToShelf(): void {
    if (this.currentUrl.length === 0) return;
    const detailUrl = this.currentDetailUrl.length > 0 ? this.currentDetailUrl : this.currentUrl;
    const readingChapter = this.mode === 'reader';
    const existing = this.bookshelf.find((b: BookshelfItem) => b.url === detailUrl);
    const item: BookshelfItem = {
      title: this.currentTitle.length > 0 ? this.currentTitle : this.t('unnamed_comic'),
      url: detailUrl,
      sourceId: this.currentSourceId,
      sourceName: this.currentSourceName,
      cover: this.currentCover,
      remoteCover: this.currentCover,
      lastChapterTitle: readingChapter ? this.currentChapterTitle : (existing ? existing.lastChapterTitle : ''),
      lastChapterUrl: readingChapter ? this.currentUrl : (existing ? existing.lastChapterUrl : ''),
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

  private updateFavoriteReadingPosition(): void {
    if (this.currentUrl.length === 0) return;
    const detailUrl = this.currentDetailUrl.length > 0 ? this.currentDetailUrl : this.currentUrl;
    let changed = false;
    const next: BookshelfItem[] = [];
    for (let i = 0; i < this.bookshelf.length; i++) {
      const old = this.bookshelf[i];
      if (old.url === detailUrl || (old.title === this.currentTitle && old.sourceId === this.currentSourceId)) {
        next.push({
          title: old.title, url: old.url, cover: old.cover, remoteCover: old.remoteCover,
          sourceId: old.sourceId, sourceName: old.sourceName,
          lastChapterTitle: this.currentChapterTitle, lastChapterUrl: this.currentUrl,
          addedAt: old.addedAt, lastReadAt: this.nowText(), imageCount: this.images.length,
          progressPercent: this.images.length > 0 ? 100 : 0, readCount: old.readCount
        });
        changed = true;
      } else next.push(old);
    }
    if (changed) {
      this.bookshelf = next;
      this.persistData();
    }
  }

  private async openBookshelfItem(item: BookshelfItem): Promise<void> {
    await this.openBookUnified(item.url, item.title, item.sourceId, item.cover,
      item.lastChapterUrl, item.lastChapterTitle);
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

  private applyCustomRule(): boolean {
    try {
      const value = JSON.parse(this.customRuleText) as ComicSourceRule | ComicSourceRule[];
      const parsed = Array.isArray(value) ? value : [value as ComicSourceRule];
      const valid = parsed.filter((item: ComicSourceRule) => item.id !== undefined && item.id.length > 0 &&
        item.readerImageRegex !== undefined && item.readerImageRegex.length > 0);
      if (valid.length === parsed.length) {
        this.advancedRules = valid;
        this.customRuleText = JSON.stringify(valid, null, 2);
        this.rebuildEffectiveRules();
        this.persistData();
        this.statusText = this.t('added_shelf');
        return true;
      } else {
        this.statusText = this.t('chapter_failed');
        return false;
      }
    } catch (err) {
      this.statusText = this.t('chapter_failed');
      return false;
    }
  }

  private editorTheme(): CodeEditorTheme {
    return this.editorThemeCache;
  }

  private editorLines(): string[] {
    return this.editorLinesCache;
  }

  private refreshEditorTheme(): void {
    this.editorThemeCache = defaultEditorTheme(this.isDark());
  }

  private refreshEditorLines(): void {
    if (this.editorFullscreen) {
      if (this.editorReadOnly) this.editorLinesCache = this.ruleViewerText.split('\n');
      else this.editorLinesCache = this.customRuleText.split('\n');
    } else if (this.settingsDialog === 'advanced') this.editorLinesCache = this.customRuleText.split('\n');
    else if (this.settingsDialog === 'rule_viewer') this.editorLinesCache = this.ruleViewerText.split('\n');
    else this.editorLinesCache = [];
    this.editorLineDataSource.updateData(this.editorLinesCache);
  }

  private editorValidate() {
    let text: string;
    if (this.editorFullscreen) {
      text = this.editorReadOnly ? this.ruleViewerText : this.customRuleText;
    } else {
      text = this.settingsDialog === 'advanced' ? this.customRuleText : this.ruleViewerText;
    }
    this.editorLanguage = this.detectLanguage(text);
    this.editorIsValid = true;
    this.editorError = '';
  }

  private editorUpdateSearch() {
    this.editorSearchMatches = findSearchMatches(this.editorLines(), this.editorSearchQuery, this.editorUseRegex, this.editorCaseSensitive);
    this.editorCurrentMatch = this.editorSearchMatches.length > 0 ? 0 : -1;
  }

  private editorJumpToMatch(idx: number) {
    if (this.editorSearchMatches.length === 0) return;
    const m = this.editorSearchMatches[idx];
    this.editorScroller.scrollTo({ xOffset: 0, yOffset: m.lineIndex * 18 });
    this.editorCursorLine = m.lineIndex;
  }

  private editorFormat() {
    if (this.editorReadOnly) return;
    if (this.settingsDialog !== 'advanced' && !this.editorFullscreen) return;
    this.editorPushUndo();
    if (this.editorLanguage === 'json') {
      const formatted = formatJson(this.customRuleText, this.editorIndentSize);
      this.customRuleText = formatted;
    }
    this.refreshEditorLines();
    this.editorValidate();
  }

  private editorPushUndo(): void {
    this.editorUndoStack.push(this.customRuleText);
    if (this.editorUndoStack.length > 50) this.editorUndoStack.shift();
    this.editorRedoStack = [];
    this.editorCanUndo = true;
    this.editorCanRedo = false;
  }

  private editorUndo(): void {
    if (this.editorUndoStack.length === 0) return;
    this.editorRedoStack.push(this.customRuleText);
    this.customRuleText = this.editorUndoStack.pop()!;
    this.editorCanUndo = this.editorUndoStack.length > 0;
    this.editorCanRedo = true;
    this.refreshEditorLines();
    this.editorValidate();
  }

  private editorRedo(): void {
    if (this.editorRedoStack.length === 0) return;
    this.editorUndoStack.push(this.customRuleText);
    this.customRuleText = this.editorRedoStack.pop()!;
    this.editorCanUndo = true;
    this.editorCanRedo = this.editorRedoStack.length > 0;
    this.refreshEditorLines();
    this.editorValidate();
  }

  private editorCopyText(): void {
  }

  private editorPasteText(): void {
    if (this.editorReadOnly) return;
  }

  private editorEditAtLine(line: number): void {
    if (!this.editorReadOnly) return;
    if (this.editorMode === 'blocked') {
      this.customRuleText = JSON.stringify(this.blockedUrls, null, 2);
    } else {
      this.customRuleText = JSON.stringify(this.advancedRules, null, 2);
    }
    this.openEditorFullscreen(this.editorTitle, false);
    this.editorCursorLine = line;
    this.editorSelectedLine = line;
  }

  private editorSave(): void {
    if (this.editorReadOnly) return;
    if (this.editorMode === 'blocked') {
      if (this.applyBlockedUrls()) {
        this.editorFullscreen = false;
        this.settingsDialog = '';
        this.editorMode = 'advanced';
        this.applyReaderFullscreen(false);
      }
      return;
    }
    if (this.editorMode === 'filter_domains' || this.editorMode === 'filter_words' || this.editorMode === 'filter_noise') {
      const lines = this.customRuleText.split('\n').filter((s: string) => s.trim().length > 0);
      if (this.editorMode === 'filter_domains') {
        searchFilterConfig.blockedDomains = lines;
        this.customBlockedDomains = this.customRuleText;
        this.statusText = '已保存' + lines.length + '条屏蔽域名';
      } else if (this.editorMode === 'filter_words') {
        searchFilterConfig.blockedWords = lines;
        this.customBlockedWords = this.customRuleText;
        this.statusText = '已保存' + lines.length + '条屏蔽词';
      } else {
        searchFilterConfig.noiseTitleWords = lines;
        this.customNoiseWords = this.customRuleText;
        this.statusText = '已保存' + lines.length + '条噪音标题词';
      }
      this.persistData();
      this.editorFullscreen = false;
      this.settingsDialog = '';
      this.editorMode = 'advanced';
      this.applyReaderFullscreen(false);
      return;
    }
    if (this.applyCustomRule()) {
      this.editorFullscreen = false;
      this.settingsDialog = '';
      this.applyReaderFullscreen(false);
    }
  }

  private applyBlockedUrls(): boolean {
    try {
      const value = JSON.parse(this.customRuleText) as string[];
      if (Array.isArray(value)) {
        const valid: string[] = [];
        for (let i = 0; i < value.length; i++) {
          const s = String(value[i]).trim();
          if (s.length > 0) valid.push(s);
        }
        this.blockedUrls = valid;
        this.customRuleText = JSON.stringify(valid, null, 2);
        this.persistData();
        this.statusText = '已保存 ' + valid.length + ' 条屏蔽规则';
        return true;
      } else {
        this.statusText = '格式错误：需要 JSON 数组';
        return false;
      }
    } catch (err) {
      this.statusText = '格式错误：JSON 解析失败';
      return false;
    }
  }

  private toggleBookmark(): void {
    const idx = this.editorBookmarks.indexOf(this.editorCursorLine);
    if (idx >= 0) {
      this.editorBookmarks.splice(idx, 1);
    } else {
      this.editorBookmarks.push(this.editorCursorLine);
    }
  }

  private nextBookmark(): void {
    if (this.editorBookmarks.length === 0) return;
    const sorted = [...this.editorBookmarks].sort((a: number, b: number) => a - b);
    const next = sorted.find((bm: number) => bm > this.editorCursorLine);
    const target = next !== undefined ? next : sorted[0];
    this.editorCursorLine = target;
    this.editorScroller.scrollTo({ xOffset: 0, yOffset: target * 20 });
  }

  private refreshEditorLinks(): void {
    const text = this.editorReadOnly ? this.ruleViewerText : this.customRuleText;
    const keys: string[] = [];
    const lines = text.split('\n');
    for (let i = 0; i < lines.length; i++) {
      const trimmed = lines[i].trim();
      if (trimmed.startsWith('"')) {
        const endQuote = trimmed.indexOf('"', 1);
        if (endQuote > 0) {
          const key = trimmed.substring(1, endQuote);
          const after = trimmed.substring(endQuote + 1).trimStart();
          if (after.startsWith(':')) {
            if (keys.indexOf(key) < 0) keys.push(key);
          }
        }
      }
    }
    this.editorLinksCache = keys;
  }

  private refreshEditorStats(): void {
    const text = this.editorReadOnly ? this.ruleViewerText : this.customRuleText;
    this.editorStatsLines = text.split('\n').length;
    this.editorStatsWords = text.split(/\s+/).filter((s: string) => s.length > 0).length;
    this.editorStatsChars = text.length;
  }

  private detectLanguage(text: string): string {
    const trimmed = text.trim();
    if (trimmed.length === 0) return 'text';
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try { JSON.parse(trimmed); return 'json'; } catch (e) { return 'text'; }
    }
    if (trimmed.startsWith('<')) return 'xml';
    return 'text';
  }

  private openEditorFullscreen(title: string, readOnly: boolean): void {
    this.settingsDialog = '';
    this.editorTitle = title;
    this.editorReadOnly = readOnly;
    this.editorMenuVisible = false;
    this.editorSeekVisible = false;
    this.editorBookmarks = [];
    this.editorSearchVisible = false;
    this.editorSearchQuery = '';
    this.editorSearchMatches = [];
    this.editorCurrentMatch = -1;
    this.editorShowIndent = false;
    this.editorCursorLine = 0;
    this.editorCol = 0;
    this.editorSelectedLine = 0;
    this.editorLinksVisible = false;
    this.editorStatsVisible = false;
    this.editorColorPickerVisible = false;
    this.editorPreviewVisible = false;
    this.refreshEditorTheme();
    if (readOnly) this.editorLinesCache = this.ruleViewerText.split('\n');
    else this.editorLinesCache = this.customRuleText.split('\n');
    this.editorLineDataSource.updateData(this.editorLinesCache);
    this.editorLineNumberWidth = Math.max(12, this.editorLinesCache.length.toString().length * 8);
    const text = readOnly ? this.ruleViewerText : this.customRuleText;
    this.editorLanguage = this.detectLanguage(text);
    this.editorIsValid = true;
    this.editorError = '';
    this.editorFullscreen = true;
    this.applyReaderFullscreen(true);
    if (!readOnly) {
      this.focusTimerId = setTimeout(() => {
        try {
          this.getUIContext().getFocusController().requestFocus('customRuleTextArea');
        } catch (e) {}
      }, 120);
    }
  }

  private rebuildEffectiveRules(): void {
    const withSearchable = RemoteRuleService.mergeRules(DEFAULT_SOURCES, SEARCHABLE_COMIC_SOURCES);
    const withAdvanced = RemoteRuleService.mergeRules(withSearchable, this.advancedRules);
    this.rules = RemoteRuleService.mergeRules(this.onlineRules, withAdvanced);
  }

  private async updateRemoteRules(): Promise<void> {
    this.remoteRuleStatus = this.t('remote_updating');
    this.updatingRules = true;
    this.ruleProgressPercent = 0;
    this.ruleProgressStatus = this.catalogStage('正在连接规则服务器…', 'Connecting to rule server…');
    try {
      this.ruleProgressStatus = this.catalogStage('正在下载规则…', 'Downloading rules…');
      const loaded = await RemoteRuleService.fetchRemoteRules(this.remoteRuleUrl,
        (received: number, total: number) => {
          this.ruleReceivedBytes = received;
          this.ruleTotalBytes = total;
          this.ruleProgressPercent = total > 0 ? Math.min(90, Math.floor(received * 90 / total)) : 0;
        });
      this.ruleProgressPercent = 90;
      this.ruleProgressStatus = this.catalogStage('正在解析并保存规则…', 'Parsing and saving rules…');
      if (loaded.length > 0) {
        let added = 0;
        let changed = 0;
        let removed = 0;
        for (let i = 0; i < loaded.length; i++) {
          const old = this.onlineRules.find((item: ComicSourceRule) => item.id === loaded[i].id);
          if (!old) added++;
          else if (JSON.stringify(old) !== JSON.stringify(loaded[i])) changed++;
        }
        for (let i = 0; i < this.onlineRules.length; i++) {
          if (!loaded.some((item: ComicSourceRule) => item.id === this.onlineRules[i].id)) removed++;
        }
        this.onlineRules = loaded;
        this.rebuildEffectiveRules();
        this.saveRuleCache(loaded);
        this.remoteRuleCount = loaded.length;
        this.remoteRuleStatus = this.t('remote_updated') + loaded.length + this.t('rules_unit') +
          (this.isEn() ? ' (added ' + added + ', changed ' + changed + ', removed ' + removed + ')' :
            '（新增 ' + added + '，变更 ' + changed + '，移除 ' + removed + '）');
        this.ruleProgressStatus = this.remoteRuleStatus;
      } else {
        this.remoteRuleStatus = this.t('remote_empty');
        this.ruleProgressStatus = this.remoteRuleStatus;
      }
      this.ruleProgressPercent = 100;
    } catch (err) {
      this.remoteRuleStatus = this.t('remote_failed');
      this.ruleProgressStatus = this.remoteRuleStatus;
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
          this.remoteCatalogItemCount = CatalogService.getCategories(catalog).length;
          this.saveCatalogCache(catalog);
          this.applyCatalog(catalog);
          this.catalogProgressPercent = 100;
          this.catalogUpdateAvailable = false;
          this.catalogUpdateStatus = this.catalogStage(
            '目录已更新至 ' + update.version + '（' + this.remoteCatalogItemCount + '个分类）',
            'Catalog updated to ' + update.version + ' (' + this.remoteCatalogItemCount + ' categories)');
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

  private async checkCatalogUpdateOnShelfEntry(): Promise<void> {
    if (this.catalogCheckingOnline || this.updatingCatalog) return;
    this.catalogCheckingOnline = true;
    this.catalogUpdateStatus = this.catalogStage('正在检查书架数据更新…', 'Checking shelf data updates…');
    try {
      const update = await CatalogService.fetchCatalogUpdate();
      if (CatalogService.isNewerVersion(update.version, this.remoteCatalog?.version)) {
        this.pendingCatalogVersion = update.version;
        this.pendingCatalogUrl = update.url;
        this.catalogUpdateAvailable = true;
        this.catalogUpdateStatus = this.catalogStage('发现目录更新 ' + update.version + '，请在数据更新中确认',
          'Catalog update ' + update.version + ' is available. Confirm in Data Update.');
      } else {
        this.catalogUpdateAvailable = false;
        this.catalogUpdateStatus = this.catalogStage('书架数据已是最新，继续使用缓存',
          'Shelf data is current. Using cache.');
      }
    } catch (err) {
      this.catalogUpdateStatus = this.catalogStage('书架数据检查失败，继续使用现有缓存',
        'Shelf data check failed. Using existing cache.');
    } finally {
      this.catalogCheckingOnline = false;
    }
  }

  private async updateAll(): Promise<void> {
    await Promise.all([this.updateRemoteRules(), this.updateCatalog()]);
  }

  private async syncFilterWords(): Promise<void> {
    if (this.syncingFilterWords) return;
    this.syncingFilterWords = true;
    this.filterWordsProgressPercent = 0;
    this.filterWordsStatus = this.catalogStage('正在连接服务器…', 'Connecting…');
    try {
      this.filterWordsStatus = this.catalogStage('正在下载屏蔽词…', 'Downloading filter words…');
      const content = await RemoteRuleService.fetchFilterWords(this.remoteRuleUrl,
        (received: number, total: number) => {
          this.filterWordsReceivedBytes = received;
          this.filterWordsTotalBytes = total;
          this.filterWordsProgressPercent = total > 0 ? Math.min(90, Math.floor(received * 90 / total)) : 0;
        });
      this.filterWordsProgressPercent = 90;
      this.filterWordsStatus = this.catalogStage('正在解析并保存…', 'Parsing and saving…');
      if (content.trim().length === 0) {
        this.filterWordsStatus = this.catalogStage('远程屏蔽词文件为空', 'Remote filter words file is empty');
        this.filterWordsProgressPercent = 100;
        this.syncingFilterWords = false;
        return;
      }
      const lines = content.split('\n');
      const domains: string[] = [];
      const words: string[] = [];
      const noise: string[] = [];
      let section = 0;
      for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        if (line === '[DOMAINS]') { section = 1; continue; }
        if (line === '[WORDS]') { section = 2; continue; }
        if (line === '[NOISE]') { section = 3; continue; }
        if (line.length === 0) continue;
        if (section === 1) domains.push(line);
        else if (section === 2) words.push(line);
        else if (section === 3) noise.push(line);
      }
      if (domains.length === 0 && words.length === 0 && noise.length === 0) {
        this.filterWordsStatus = this.catalogStage('未解析到有效屏蔽词', 'No valid filter words parsed');
        this.filterWordsProgressPercent = 100;
        this.syncingFilterWords = false;
        return;
      }
      searchFilterConfig.blockedDomains = domains;
      searchFilterConfig.blockedWords = words;
      searchFilterConfig.noiseTitleWords = noise;
      this.customBlockedDomains = domains.join('\n');
      this.customBlockedWords = words.join('\n');
      this.customNoiseWords = noise.join('\n');
      this.persistData();
      this.filterWordsStatus = this.catalogStage(
        '已同步：域名' + domains.length + '条，屏蔽词' + words.length + '条，噪音词' + noise.length + '条',
        'Synced: ' + domains.length + ' domains, ' + words.length + ' words, ' + noise.length + ' noise');
      this.statusText = this.filterWordsStatus;
      this.filterWordsProgressPercent = 100;
    } catch (err) {
      this.filterWordsStatus = this.catalogStage('同步失败', 'Sync failed');
      console.error('ComicReader syncFilterWords failed: ' + JSON.stringify(err));
    }
    this.syncingFilterWords = false;
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

  private onCatalogUpdateStatusChanged(): void {
    if (this.catalogUpdateStatus.trim().length > 0) this.statusText = this.catalogUpdateStatus;
  }

  @Builder
  private StatusMessageOverlay() {
    Text(this.statusText)
      .fontSize(12).fontColor(this.messageColor()).lineHeight(16).maxLines(2)
      .padding({ left: 13, right: 13, top: 7, bottom: 7 })
      .backgroundColor(this.messageBackground())
      .backgroundBlurStyle(BlurStyle.Thin, { colorMode: this.isDark() ? ThemeColorMode.DARK : ThemeColorMode.LIGHT })
      .border({ width: 1, color: this.messageBorder() })
      .borderRadius(15).margin({ left: 36, right: 36 })
  }

  private onLoadingChanged(): void {
    if (this.isLoading || this.webLoading) {
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
        .enabled(!(this.isLoading || this.webLoading))
        .onClick(() => { this.startSearch(); })
      if (this.isLoading || this.webLoading) {
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

  @Builder
  private RecentSearchPanel() {
    if (this.searchHistoryVisible && this.recentSearches.length > 0) {
      Column() {
        Row() {
          Text(this.isEn() ? 'Recent searches' : '最近搜索').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).layoutWeight(1)
          Text(this.isEn() ? 'Clear' : '清除').fontSize(12).fontColor(this.iconColor('ic_x')).padding(6).onClick(() => this.clearRecentSearches())
        }.width('100%')
        ForEach(this.recentSearches, (keyword: string) => {
          Text(keyword).fontSize(14).fontColor(this.colorfulValue(keyword)).width('100%').maxLines(1)
            .padding({ top: 8, bottom: 8 }).border({ width: { top: 1 }, color: this.borderSubtle() })
            .onClick(() => this.repeatSearch(keyword))
        }, (keyword: string) => keyword)
      }.width('100%').padding({ left: 14, right: 14, top: 8, bottom: 8 })
        .borderRadius(14).border({ width: 1, color: this.borderSubtle() })
        .backgroundColor(this.isDark() ? '#CC1A1A1A' : '#CCFFFFFF')
        .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THIN)
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
  private SearchHome() {
    Scroll() {
      Column() {
        Column() {}.width('100%').height(this.contentTopInset())
        Blank().layoutWeight(1)
        Image($r('app.media.internal_icon')).width(220).height(180).objectFit(ImageFit.Contain).margin({ bottom: 24 })
        Row() {
          Stack() {
            TextInput({ placeholder: this.t('search_placeholder'), text: this.queryText })
              .height(52).fontSize(15).fontColor(this.primaryText()).placeholderColor(this.secondaryText())
              .backgroundColor(Color.Transparent).borderRadius(26).border({ width: 1, color: this.secondaryText() })
              .padding({ left: 18, right: this.queryText.length > 0 ? 44 : 18 })
              .onFocus(() => { this.searchHistoryVisible = true; })
              .onChange((value: string) => { this.queryText = value; }).onSubmit(() => { this.startSearch(); })
            if (this.queryText.length > 0) {
              Row() {
                Column() { Image($rawfile('ic_x.svg')).width(16).height(16).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_x'))) }
                  .width(36).height(36).justifyContent(FlexAlign.Center).margin({ right: 8 })
                  .onClick(() => { this.clearSearchAndReset(); })
              }.width('100%').justifyContent(FlexAlign.End).hitTestBehavior(HitTestMode.Transparent)
            }
          }.layoutWeight(1)
          Column() { this.SearchActionButton(52) }.margin({ left: 10 })
        }.width('100%').padding({ left: 22, right: 22 })
        Column() { this.RecentSearchPanel() }.width('100%').padding({ left: 22, right: 22, top: 8 })
        Blank().layoutWeight(1)
        Blank().height(this.contentBottomInset())
      }.width('100%').height('100%').alignItems(HorizontalAlign.Center)
    }
    .layoutWeight(1)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .scrollBar(BarState.Auto)
    .scrollBarColor(this.scrollBarColor()).scrollBarWidth(6)
    .backgroundColor(this.appBg())
    .onClick(() => { this.searchHistoryVisible = false; })
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
          .fontColor(this.colorfulAccent('avatar-' + item.title))
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
          Text(this.siteTypeTag(item.url, item.title)).fontSize(11).fontColor('#FFFFFF').padding({ left: 8, right: 8, top: 3, bottom: 3 }).backgroundColor(this.actionBg()).borderRadius(10)
          Text(item.url).fontSize(11).fontColor('#0A84FF').layoutWeight(1).margin({ left: 8 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).hitTestBehavior(HitTestMode.Block).onClick(() => this.openInBrowser(item.url, item.title))
            .gesture(LongPressGesture().onAction(() => { this.statusText = this.t('url_copied'); this.copyToClipboard(item.url); }))
        }.width('100%').margin({ top: 7 })
        if (this.showDebugInfo) {
          Text('[' + this.debugSourceKind(item) + '] ' + item.sourceName + ' · ' + item.sourceId + ' · ' + this.debugResultTypeCN(item.resultType) + '\n' + buildDebugMatchInfo(item.title, item.url, item.description ?? '', this.searchTitle)).fontSize(9).fontColor(this.colorfulValue('src-' + item.sourceId)).maxLines(5).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').margin({ top: 4 })
        }
      }.layoutWeight(1).margin({ left: 12 })
    }
    .width('100%')
    .height(this.showDebugInfo ? undefined : 124)
    .padding(10)
    .backgroundColor(this.cardBg())
    .border({ width: 2,
      color: item.url === this.lastOpenedSearchUrl ? this.colorfulValue('opened-' + item.url) : Color.Transparent })
    .borderRadius(16)
    .margin({ bottom: 10 })
    .onClick(() => this.openSearchResult(item))
  }

  @Builder
  private ResultsPage() {
    Stack() {
      if (this.searchResultMode === 'browser' && this.searchEngineUrl.length > 0) {
        Stack() {
          Web({ src: this.searchEngineUrl, controller: this.webController, renderMode: RenderMode.SYNC_RENDER })
            .width('100%').height('100%')
            .backgroundColor(this.isDark() ? '#1a1a1a' : '#ffffff')
            .javaScriptAccess(true).domStorageAccess(true)
            .mixedMode(MixedMode.All).cacheMode(CacheMode.Default)
            .imageAccess(true).zoomAccess(true)
            .fileAccess(true).databaseAccess(true)
            .userAgent(searchEngineUserAgent())
            .darkMode(WebDarkMode.Off)
            .forceDarkAccess(false)
            .javaScriptOnDocumentStart(this.isDark() ? [{ script: this.darkModeCssScript, scriptRules: ['*'] }, { script: this.adBlockScript, scriptRules: ['*'] }] : [{ script: this.adBlockScript, scriptRules: ['*'] }])
            .opacity(this.webErrorText.length > 0 ? 0 : 1)
            .onPageBegin(() => {
              this.webMainFrameFailed = false;
              this.webLoading = true;
              this.webErrorText = '';
              try { this.webController.runJavaScript(this.adBlockScript); } catch (e) {}
              if (this.isDark()) {
                try { this.webController.runJavaScript(this.darkModeCssScript); } catch (e) {}
              }
              this.webLoadingTimeoutId = setTimeout((): void => { if (this.webLoading) this.webLoading = false; }, 15000);
            })
            .onPageEnd((event: OnPageEndEvent) => {
              this.webLoading = false;
              this.webDarkOverlay = false;
              if (!this.webMainFrameFailed && event !== undefined && event.url !== undefined &&
                (event.url.startsWith('http://') || event.url.startsWith('https://'))) {
                this.webLastSuccessUrl = event.url;
                const urlLower = event.url.toLowerCase();
                const isSearchEngine = urlLower.indexOf('bing.com') >= 0 || urlLower.indexOf('baidu.com') >= 0 ||
                  urlLower.indexOf('duckduckgo.com') >= 0 || urlLower.indexOf('sogou.com') >= 0 ||
                  urlLower.indexOf('yandex.com') >= 0 || urlLower.indexOf('google.com') >= 0 ||
                  urlLower.indexOf('so.com') >= 0;
                if (isSearchEngine) {
                  this.showReaderHint = false;
                  this.injectSearchPageStyles();
                } else {
                  this.showReaderHint = isComicDomain(event.url);
                  try { this.webController.runJavaScript(this.adBlockScript); } catch (e) {}
                  if (this.isDark()) {
                    try { this.webController.runJavaScript(this.darkModeCssScript); } catch (e) {}
                  }
                }
              }
            })
            .onSslErrorEventReceive((event: OnSslErrorEventReceiveEvent) => {
              if (event !== undefined && event.handler !== undefined) event.handler.handleConfirm();
            })
            .onErrorReceive((event: OnErrorReceiveEvent) => {
              if (event !== undefined && event.request !== undefined && event.request.isMainFrame() &&
                event.error !== undefined) {
                this.handleWebError(event.error.getErrorInfo());
              }
            })

          if (this.webDarkOverlay) {
            Column().width('100%').height('100%').backgroundColor(this.isDark() ? '#1a1a1a' : '#ffffff')
          }

          if (this.webLoading) {
            Column({ space: 12 }) {
              LoadingProgress().width(36).height(36).color(this.secondaryText())
              Text(this.t('searching_sources')).fontSize(14).fontColor(this.secondaryText())
              if (this.showDebugInfo) {
                Text(`[debug] URL=${this.searchEngineUrl.substring(0, 80)}`).fontSize(10).fontColor('#ff6600').padding({ left: 16, right: 16 })
                Text(`[debug] mode=${this.searchResultMode} loading=${this.webLoading} err=${this.webErrorText.length} mainFail=${this.webMainFrameFailed}`).fontSize(10).fontColor('#ff6600')
              }
            }.width('100%').height('100%').justifyContent(FlexAlign.Center).backgroundColor(this.appBg())
          }

          if (this.webErrorText.length > 0) {
            Column({ space: 12 }) {
              Text(this.webErrorText).fontSize(14).fontColor(this.secondaryText()).textAlign(TextAlign.Center).padding({ left: 24, right: 24 })
              Text('点击返回重试').fontSize(12).fontColor(this.secondaryText())
            }.width('100%').height('100%').justifyContent(FlexAlign.Center).backgroundColor(this.appBg())
          }
        }.width('100%').height('100%')

        if (this.showReaderHint) {
          Stack({ alignContent: Alignment.Center }) {
            Image($rawfile('ic_reader.svg')).width(26).height(26)
              .colorFilter(createStrokeIconColorFilter(this.iconColor('ic_reader')))
          }
          .width(56).height(56)
          .borderRadius(28)
          .backgroundColor(this.isDark() ? '#40FFFFFF' : '#40FFFFFF')
          .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THIN)
          .border({ width: 1, color: this.isDark() ? '#30FFFFFF' : '#20000000' })
          .shadow({ radius: 8, color: '#40000000', offsetY: 2 })
          .position({ x: '82%', y: '70%' })
          .onClick(() => { this.webOpenInReader(); })
        }
      } else {
        Scroll(this.searchResultsScroller) {
          Column() {
            Column() {}.width('100%').height(this.contentTopInset())
            if (this.showDebugInfo) {
              Text('引擎' + this.debugEngineResults + '条(试' + this.debugEngineTried + '成' + this.debugEngineSuccess + ') | HTML可搜索' + this.debugRuleTried + ' 跳过' + this.debugRuleSkipped + ' 成功' + this.debugRuleSuccess + ' 失败' + this.debugRuleFailed + ' | 模式' + this.searchMode + ' | 全引擎' + (this.searchAllEngines ? '开' : '关') + ' 搜索引擎' + (this.enableSearchEngines ? '开' : '关') + ' | 规则' + this.rules.length + '条').fontSize(9).fontColor(this.secondaryText()).width('100%').padding({ left: 4, right: 4, top: 2, bottom: 4 })
              if (this.debugSearchQueries.length > 0) {
                Text('实际查询: ' + this.debugSearchQueries).fontSize(9).fontColor(this.colorfulValue('debug-queries')).width('100%').padding({ left: 4, right: 4, top: 2, bottom: 4 }).maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis })
              }
            }
            if (this.results.length === 0) {
              Text(this.isLoading ? this.t('searching_sources') : this.t('no_results'))
                .fontSize(14)
                .fontColor(this.secondaryText())
                .width('100%')
                .padding(12)
                .backgroundColor(this.cardBg())
                .borderRadius(10)
            } else {
              ForEach(this.results, (item: SearchResultItem) => {
                this.ResultListCard(item)
              }, (item: SearchResultItem) => item.url)
            }
            Blank().height(this.contentBottomInset())
          }.width('100%').padding({ left: 14, right: 14 }).justifyContent(FlexAlign.Start)
        }
        .width('100%').height('100%')
        .align(Alignment.TopStart)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
        .scrollBar(BarState.Auto)
        .scrollBarColor(this.scrollBarColor()).scrollBarWidth(6)
        .backgroundColor(this.appBg())
      }
    }
    .width('100%').height('100%')
  }

  @Builder
  private ChaptersPage() {
    Stack() {
      List({ scroller: this.chapterScroller, space: 8 }) {
          ListItem() { Column() {}.width('100%').height(this.headerOverlayHeight()) }
          if (this.showDebugInfo) {
            ListItem() {
              Row() {
                Text('Chapters: ' + this.chapters.length).fontSize(10).fontColor(this.colorfulValue('debug-Chapters'))
                Text('Loading: ' + this.detailLoading).fontSize(10).fontColor(this.colorfulValue('debug-DetailLoading')).margin({ left: 8 })
                Text('Reversed: ' + this.chapterReversed).fontSize(10).fontColor(this.colorfulValue('debug-Reversed')).margin({ left: 8 })
                Text('SrcId: ' + this.currentSourceId).fontSize(10).fontColor(this.colorfulValue('debug-SrcId')).margin({ left: 8 })
                Text('SrcName: ' + this.currentSourceName).fontSize(10).fontColor(this.colorfulValue('debug-SrcName')).margin({ left: 8 })
                Text('DetailUrl: ' + this.currentDetailUrl).fontSize(10).fontColor(this.colorfulValue('debug-DetailUrl')).margin({ left: 8 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
      }.width('100%').padding({ left: 14, right: 14 }).justifyContent(FlexAlign.Start)
            }
          }
          if (this.detailLoading) {
            ListItem() {
              Column({ space: 6 }) {
                Progress({ value: this.detailTotalBytes > 0
                  ? Math.min(100, Math.floor(this.detailReceivedBytes * 100 / this.detailTotalBytes)) : 0,
                  total: 100, type: ProgressType.Linear }).width('100%').height(6).color(this.colorfulAccent('progress-detail'))
                Text(this.detailProgressText()).fontSize(12).fontColor(this.secondaryText()).width('100%')
              }.width('100%').padding({ bottom: 2 })
            }
          }
          if (this.chapters.length === 0) {
            ListItem() {
              Text(this.t('no_chapters')).fontSize(14).fontColor(this.secondaryText())
                .width('100%').padding(12).backgroundColor(this.cardBg()).borderRadius(10)
            }
          } else {
            ForEach(this.displayedChapters(), (chapter: ChapterItem) => {
              ListItem() {
                Row() {
                  Text(chapter.title.trim().length > 0 ? chapter.title : this.t('chapter_list') + ' ' + chapter.index)
                    .fontSize(15)
                    .fontWeight(chapter.url === this.currentUrl ? FontWeight.Bold : FontWeight.Medium)
                    .fontColor(chapter.url === this.currentUrl ? this.colorfulAccent('chapter-' + chapter.url) : this.primaryText())
                    .layoutWeight(1)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('100%')
                .padding(12)
                .backgroundColor(this.cardBg())
                .borderRadius(10)
                .border({ width: chapter.url === this.currentUrl ? 2 : 0, color: this.colorfulAccent('chapter-' + chapter.url) })
              }
              .onClick(() => this.loadChapter(chapter, this.findRule(chapter.sourceId)))
            }, (chapter: ChapterItem) => chapter.url)
          }
      }
      .width('100%').height('100%')
      .padding({ left: 14, right: 14, bottom: 14 })
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .scrollBar(BarState.Auto)
      .scrollBarColor(this.scrollBarColor()).scrollBarWidth(6)

      Column() {
        Blank().height(this.avoidStatusBarHeight)
        Row() {
          Column() { Image($rawfile('ic_back.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_back'))) }
            .padding({ left: 12, right: 8, top: 6, bottom: 6 }).onClick(() => this.returnToSearchResults())
          Text(this.currentTitle.length > 0 ? this.currentTitle : this.t('chapter_list'))
            .fontSize(19).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).layoutWeight(1)
            .margin({ left: 6 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.chapterReversed ? this.t('chapter_ascending') : this.t('chapter_descending'))
            .fontSize(13).fontColor(this.colorfulAccent('btn-chapter-order')).padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .border({ width: 1, color: this.colorfulAccent('btn-chapter-order') }).borderRadius(14)
            .onClick(() => { this.chapterReversed = !this.chapterReversed; this.persistData(); })
          Text(this.isCurrentFavorite() ? '★' : '☆').fontSize(20).fontColor(this.iconColor('ic_star_filled'))
            .padding({ left: 8, right: 12, top: 6, bottom: 6 }).onClick(() => this.toggleCurrentFavorite())
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
          if (this.showDebugInfo) {
            Row() {
              Text('Images: ' + this.images.length).fontSize(10).fontColor(this.colorfulValue('debug-Images'))
              Text('Render: ' + this.readerRenderLimit).fontSize(10).fontColor(this.colorfulValue('debug-Render')).margin({ left: 8 })
              Text('Zoom: ' + this.readerZoomScale.toFixed(2)).fontSize(10).fontColor(this.colorfulValue('debug-Zoom')).margin({ left: 8 })
              Text('MaxPages: ' + this.maxReaderPages).fontSize(10).fontColor(this.colorfulValue('debug-MaxPages')).margin({ left: 8 })
              Text('ChapTitle: ' + this.currentChapterTitle).fontSize(10).fontColor(this.colorfulValue('debug-ChapIdx')).margin({ left: 8 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
              Text('SrcId: ' + this.currentSourceId).fontSize(10).fontColor(this.colorfulValue('debug-RdrSrcId')).margin({ left: 8 })
              Text('Fullscreen: ' + this.fullscreenReader).fontSize(10).fontColor(this.colorfulValue('debug-Fullscreen')).margin({ left: 8 })
              Text('Floating: ' + this.floatingReaderControls).fontSize(10).fontColor(this.colorfulValue('debug-Floating')).margin({ left: 8 })
            }.width('100%').padding({ left: 14, right: 14, top: 2, bottom: 2 })
          }
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
        }
        .width((this.readerZoomScale * 100).toString() + '%')
        .translate({ x: this.readerPanX })
      }
      .layoutWeight(1)
      .backgroundColor(this.readerDarkMode ? '#050505' : this.appBg())
      .scrollBar(BarState.Auto)
      .scrollBarColor(this.scrollBarColor()).scrollBarWidth(6)
      .onAreaChange((_oldValue, newValue) => {
        const width = Number(newValue.width);
        if (width > 0) {
          this.readerViewportWidth = width;
          this.readerPanX = this.clampReaderPan(this.readerPanX);
        }
      })
      .onReachEnd(() => { this.loadNextChapterIfReady(); })
      .onClick(() => {
        if (Date.now() - this.readerGestureEndedAt < 300) return;
        if (this.floatingReaderControls) this.readerToolsVisible = !this.readerToolsVisible;
      })
      .parallelGesture(
        GestureGroup(GestureMode.Parallel,
          PinchGesture()
            .onActionStart(() => {
              this.readerZoomStartScale = this.readerZoomScale;
            })
            .onActionUpdate((event: PinchGestureEvent) => {
              this.updateReaderZoom(this.readerZoomStartScale * event.scale);
            })
            .onActionEnd(() => {
              this.readerZoomStartScale = this.readerZoomScale;
              this.readerGestureEndedAt = Date.now();
            }),
          PanGesture({ direction: PanDirection.Horizontal, distance: 4 })
            .onActionStart(() => {
              this.readerPanStartX = this.readerPanX;
            })
            .onActionUpdate((event: PanGestureEvent) => {
              if (this.readerZoomScale > 1) {
                this.readerPanX = this.clampReaderPan(this.readerPanStartX + event.offsetX);
              }
            })
            .onActionEnd(() => {
              this.readerPanStartX = this.readerPanX;
              this.readerGestureEndedAt = Date.now();
            })
        )
      )

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
              .onClick(() => { this.fullscreenReader = !this.fullscreenReader; this.applyReaderFullscreen(this.fullscreenReader); this.persistData(); })
          }
          .width('100%').padding({ left: 10, right: 10, top: this.avoidStatusBarHeight + 8 })

          Blank()

          Row({ space: 8 }) {
            Text(this.t('previous_chapter')).fontSize(13).fontColor(this.hasRelativeChapter(-1) ? this.iconColor('ic_back') : this.secondaryText()).layoutWeight(1).textAlign(TextAlign.Center).padding({ top: 11, bottom: 11 }).borderRadius(20).border({ width: 1, color: this.hasRelativeChapter(-1) ? this.iconColor('ic_back') : this.borderSubtle() }).backgroundColor(this.isDark() ? '#381E232F' : '#48FFFFFF').linearGradient({ angle: 145, colors: this.readerControlGradient() }).shadow({ radius: 7, color: '#22000000', offsetY: 2 }).onClick(() => this.loadRelativeChapter(-1))
            Text(this.t('chapter_list')).fontSize(13).fontColor(this.iconColor('ic_layout')).layoutWeight(1).textAlign(TextAlign.Center).padding({ top: 11, bottom: 11 }).borderRadius(20).border({ width: 1, color: this.iconColor('ic_layout') }).backgroundColor(this.isDark() ? '#381E232F' : '#48FFFFFF').linearGradient({ angle: 145, colors: this.readerControlGradient() }).shadow({ radius: 7, color: '#22000000', offsetY: 2 }).onClick(() => this.openReaderChapterPanel())
            Text(this.isCurrentFavorite() ? '★' : '☆').fontSize(24).fontColor(this.iconColor('ic_star_filled')).width(48).height(42).textAlign(TextAlign.Center).borderRadius(21).border({ width: 1, color: this.iconColor('ic_star_filled') }).backgroundColor(this.isDark() ? '#381E232F' : '#48FFFFFF').linearGradient({ angle: 145, colors: this.readerControlGradient() }).shadow({ radius: 7, color: '#22000000', offsetY: 2 }).onClick(() => this.toggleCurrentFavorite())
            Text(this.t('next_chapter')).fontSize(13).fontColor(this.hasRelativeChapter(1) ? this.iconColor('ic_reader') : this.secondaryText()).layoutWeight(1).textAlign(TextAlign.Center).padding({ top: 11, bottom: 11 }).borderRadius(20).border({ width: 1, color: this.hasRelativeChapter(1) ? this.iconColor('ic_reader') : this.borderSubtle() }).backgroundColor(this.isDark() ? '#381E232F' : '#48FFFFFF').linearGradient({ angle: 145, colors: this.readerControlGradient() }).shadow({ radius: 7, color: '#22000000', offsetY: 2 }).onClick(() => this.loadRelativeChapter(1))
          }.width('100%').padding({ left: 10, right: 10, bottom: 10 })
        }.width('100%').height('100%').hitTestBehavior(HitTestMode.Transparent)
      }

      if (this.readerChapterPanelVisible) {
        Row() {
          List({ scroller: this.readerChapterScroller, space: 0 }) {
              ForEach(this.readerPanelChapters(), (chapter: ChapterItem) => {
                ListItem() {
                Text(chapter.title.trim().length > 0 ? chapter.title : this.t('chapter_list') + ' ' + chapter.index)
                  .fontSize(14)
                  .fontColor(chapter.url === this.currentUrl ? this.iconColor('ic_reader') : this.primaryText())
                  .width('100%').maxLines(2).padding({ top: 11, bottom: 11 })
                  .border({ width: { bottom: 1 }, color: this.borderSubtle() })
                  .onClick(() => { this.readerChapterPanelVisible = false; this.loadChapter(chapter, this.findRule(chapter.sourceId)); })
                }.width('100%')
              }, (chapter: ChapterItem) => chapter.url)
          }
          .width('38%').height('100%')
          .contentStartOffset(this.avoidStatusBarHeight + 12)
          .contentEndOffset(24)
          .padding({ left: 16, right: 16 })
          .backgroundColor(this.isDark() ? '#701E232F' : '#78FFFFFF')
          .linearGradient({ angle: 125, colors: this.readerPanelGradient() })
          .border({ width: { right: 1 }, color: this.borderSubtle() })
          .shadow({ radius: 14, color: '#30000000', offsetX: 4 })
          .scrollBar(BarState.Auto)
          .scrollBarColor(this.scrollBarColor()).scrollBarWidth(6)
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
      .margin({ top: 4, bottom: 8 })
  }

  @Builder
  private LinkRow(icon: string, label: string, value: string, showTopBorder: boolean, arrowIcon?: string) {
    Row({ space: 12 }) {
      Stack() {
        Image($rawfile(icon + '.svg')).width(20).height(20)
          .colorFilter(createStrokeIconColorFilter(this.iconColor(icon)))
      }.width(34).height(34)
      Column({ space: 4 }) {
        Text(label).fontSize(16).fontColor(this.primaryText()).width('100%')
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      Text(value).fontSize(13).fontColor(this.secondaryText()).textAlign(TextAlign.End)
      Image($rawfile((arrowIcon ?? 'ic_chevron_right') + '.svg')).width(16).height(16)
        .colorFilter(createStrokeIconColorFilter(this.iconColor(icon)))
    }
    .width('100%')
    .height(56)
    .border(showTopBorder ? { width: { top: 1 }, color: this.borderSubtle() } : { width: 0 })
  }

  @Builder
  private ToggleSettingRow(icon: string, label: string, isOn: boolean, showTopBorder: boolean, onChange: (isOn: boolean) => void) {
    Row({ space: 12 }) {
      Stack() {
        Image($rawfile(icon + '.svg')).width(20).height(20)
          .colorFilter(createStrokeIconColorFilter(this.iconColor(icon)))
      }.width(34).height(34)
      Text(label).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor(this.iconColor(icon))
        .switchPointColor('#FFFFFF')
        .constraintSize({ maxHeight: 32 })
        .onChange(onChange)
    }
    .width('100%')
    .height(56)
    .border(showTopBorder ? { width: { top: 1 }, color: this.borderSubtle() } : { width: 0 })
  }

  @Builder
  private SelectOptionRow(label: string, isSelected: boolean, showTopBorder: boolean, onSelect: () => void) {
    Row({ space: 0 }) {
      Text(label).fontSize(16).fontColor(isSelected ? this.colorfulAccent('select-option-' + label) : this.primaryText()).layoutWeight(1).textAlign(TextAlign.Start).margin({ left: 16 })
    }
    .width('100%')
    .height(50)
    .borderRadius(isSelected ? 8 : 0)
    .border(isSelected
      ? { width: 1.5, color: this.colorfulAccent('select-option-' + label), style: BorderStyle.Solid }
      : showTopBorder ? { width: { top: 1 }, color: this.borderSubtle() } : { width: 0 })
    .onClick(onSelect)
  }

  @Builder
  private ThemeOptionRow(mode: string, label: string, showTopBorder: boolean) {
    Row({ space: 0 }) {
      Text(label).fontSize(16).fontColor(this.appTheme === mode ? this.colorfulAccent('theme-' + mode) : this.primaryText()).layoutWeight(1).textAlign(TextAlign.Start).margin({ left: 16 })
    }
    .width('100%')
    .height(50)
    .borderRadius(this.appTheme === mode ? 8 : 0)
    .border(this.appTheme === mode
      ? { width: 1.5, color: this.colorfulAccent('theme-' + mode), style: BorderStyle.Solid }
      : showTopBorder ? { width: { top: 1 }, color: this.borderSubtle() } : { width: 0 })
    .onClick(() => {
      if (this.appTheme !== mode) {
        this.appTheme = mode;
        this.updateSystemBarColors();
        AppStorage.setOrCreate<number>('uiVersion', Date.now());
        this.statusText = this.t('theme_switched');
        this.persistData();
      }
      this.themeExpanded = false;
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
        }.width(30).height(20).margin({ left: 11 })
      } else {
        Circle().width(20).height(20).fill(this.iconModeColor(mode)).margin({ left: 16 })
      }
      Text(this.t('icon_color_' + mode)).fontSize(16)
        .fontColor(this.iconColorMode === mode ? this.colorfulAccent('icon-mode-' + mode) : this.primaryText()).layoutWeight(1)
    }
    .width('100%')
    .height(50)
    .borderRadius(this.iconColorMode === mode ? 8 : 0)
    .border(this.iconColorMode === mode
      ? { width: 1.5, color: this.colorfulAccent('icon-mode-' + mode), style: BorderStyle.Solid }
      : showTopBorder ? { width: { top: 1 }, color: this.borderSubtle() } : { width: 0 })
    .onClick(() => {
      this.iconColorMode = mode;
      AppStorage.setOrCreate<number>('uiVersion', Date.now());
      this.persistData();
      this.iconColorExpanded = false;
    })
  }

  @Builder
  private LanguageOptionRow(mode: string, label: string, showTopBorder: boolean) {
    Row({ space: 0 }) {
      Text(label).fontSize(16).fontColor(this.appLanguage === mode ? this.colorfulAccent('lang-' + mode) : this.primaryText()).layoutWeight(1).textAlign(TextAlign.Start).margin({ left: 16 })
    }
    .width('100%')
    .height(50)
    .borderRadius(this.appLanguage === mode ? 8 : 0)
    .border(this.appLanguage === mode
      ? { width: 1.5, color: this.colorfulAccent('lang-' + mode), style: BorderStyle.Solid }
      : showTopBorder ? { width: { top: 1 }, color: this.borderSubtle() } : { width: 0 })
    .onClick(() => {
      this.appLanguage = mode;
      this.refreshCatalogLanguageFilter();
      AppStorage.setOrCreate<number>('uiVersion', Date.now());
      this.languageExpanded = false;
      this.persistData();
    })
  }

  @Builder
  private BookListCard(cover: string, title: string, desc: string, value: string) {
    Row() {
      if (cover.length > 0) {
        Image(cover).width(44).height(60).borderRadius(6).objectFit(ImageFit.Cover)
      } else {
        Column() {
          Text(title.substring(0, 1)).fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.colorfulAccent('avatar-' + title))
        }.width(44).height(60).borderRadius(6).justifyContent(FlexAlign.Center).backgroundColor(this.coverPlaceholderBg())
      }
      Column() {
        Text(title).fontSize(15).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).width('100%').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(desc).fontSize(12).fontColor(this.secondaryText()).width('100%').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 3 })
        Text(value).fontSize(11).fontColor(this.secondaryText()).width('100%').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 3 })
      }.layoutWeight(1).margin({ left: 10 }).alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
    .backgroundColor(this.cardBg())
    .borderRadius(12)
    .margin({ bottom: 8 })
  }

  @Builder
  private SettingsPage() {
    Stack() {
      Scroll() {
        Column() {
          Column() {}.width('100%').height(this.avoidStatusBarHeight + 43)

          if (this.showDebugInfo) {
            Row() {
              Text('Rules: ' + this.rules.length).fontSize(10).fontColor(this.colorfulValue('debug-RulesCount'))
              Text('Online: ' + this.onlineRules.length).fontSize(10).fontColor(this.colorfulValue('debug-OnlineRules')).margin({ left: 8 })
              Text('Engines: ' + this.searchEngines.length).fontSize(10).fontColor(this.colorfulValue('debug-EnginesCount')).margin({ left: 8 })
              Text('AdvRules: ' + this.advancedRules.length).fontSize(10).fontColor(this.colorfulValue('debug-AdvRules')).margin({ left: 8 })
              Text('Theme: ' + this.appTheme).fontSize(10).fontColor(this.colorfulValue('debug-Theme')).margin({ left: 8 })
              Text('Lang: ' + this.appLanguage).fontSize(10).fontColor(this.colorfulValue('debug-Lang')).margin({ left: 8 })
              Text('IconMode: ' + this.iconColorMode).fontSize(10).fontColor(this.colorfulValue('debug-IconMode')).margin({ left: 8 })
              Text('CoverAcc: ' + (this.coverAccuracyIndex === null ? '0' : this.coverAccuracyIndex.count)).fontSize(10).fontColor(this.colorfulValue('debug-CoverAcc')).margin({ left: 8 })
            }.width('100%').padding({ left: 18, right: 18, top: 2, bottom: 2 })
          }
          this.SectionLabel(this.t('basic_settings'))
          Column({ space: 0 }) {
            Column() { this.LinkRow('ic_moon', this.t('theme'), this.themeDisplay(), false,
              this.themeExpanded ? 'ic_chevron_up' : 'ic_chevron_down') }
              .onClick(() => { this.themeExpanded = !this.themeExpanded; this.languageExpanded = false; this.iconColorExpanded = false; this.dlgSearchModeExpanded = false; this.dlgLangExpanded = false; this.dlgEngineExpanded = false; this.dlgReaderBgExpanded = false; this.dlgMaxResultsExpanded = false; this.dlgMaxPagesExpanded = false; })
              .onAreaChange((_old: Area, newArea: Area) => {
                this.themeRowBottom = Number(newArea.globalPosition.y) + Number(newArea.height);
              })
            Column() { this.LinkRow('ic_language', this.t('language'), this.languageDisplay(), true,
              this.languageExpanded ? 'ic_chevron_up' : 'ic_chevron_down') }
              .onClick(() => { this.languageExpanded = !this.languageExpanded; this.themeExpanded = false; this.iconColorExpanded = false; this.dlgSearchModeExpanded = false; this.dlgLangExpanded = false; this.dlgEngineExpanded = false; this.dlgReaderBgExpanded = false; this.dlgMaxResultsExpanded = false; this.dlgMaxPagesExpanded = false; })
              .onAreaChange((_old: Area, newArea: Area) => {
                this.languageRowBottom = Number(newArea.globalPosition.y) + Number(newArea.height);
              })
            Column() { this.ToggleSettingRow('ic_fullscreen', this.t('reader_fullscreen'), this.fullscreenReader, true, (isOn: boolean) => { this.fullscreenReader = isOn; this.persistData(); }) }
            Column() { this.ToggleSettingRow('ic_layout', this.t('floating_controls'), this.floatingReaderControls, true, (isOn: boolean) => { this.floatingReaderControls = isOn; this.persistData(); }) }
            Column() { this.LinkRow('ic_theme', this.t('icon_color'), this.iconColorModeDisplay(), true,
              this.iconColorExpanded ? 'ic_chevron_up' : 'ic_chevron_down') }
              .onClick(() => { this.iconColorExpanded = !this.iconColorExpanded; this.themeExpanded = false; this.languageExpanded = false; this.dlgSearchModeExpanded = false; this.dlgLangExpanded = false; this.dlgEngineExpanded = false; this.dlgReaderBgExpanded = false; this.dlgMaxResultsExpanded = false; this.dlgMaxPagesExpanded = false; })
              .onAreaChange((_old: Area, newArea: Area) => {
                this.iconColorRowBottom = Number(newArea.globalPosition.y) + Number(newArea.height);
              })
          }.width('100%').padding({ left: 18, right: 18 }).backgroundColor(this.cardBg()).borderRadius(18)

          this.SectionLabel(this.t('app_settings'))
          Column({ space: 0 }) {
            Column() { this.LinkRow('ic_search', this.t('search_menu'), this.searchModeDisplay() + ' · ' + this.selectedEngine().name, false) }.onClick(() => { this.themeExpanded = false; this.languageExpanded = false; this.iconColorExpanded = false; this.settingsDialog = 'search'; })
            Column() { this.LinkRow('ic_filter', this.t('source_switch'), this.enableSearchEngines ? this.t('enabled') : this.t('disabled'), true) }.onClick(() => { this.themeExpanded = false; this.languageExpanded = false; this.iconColorExpanded = false; this.settingsDialog = 'sources'; })
            Column() { this.LinkRow('ic_reading', this.t('display_reading'), this.t('reading_settings'), true) }.onClick(() => { this.themeExpanded = false; this.languageExpanded = false; this.iconColorExpanded = false; this.settingsDialog = 'reader'; })
            Column() { this.LinkRow('ic_rule', this.t('rule_settings'), this.remoteRuleCount + this.t('rules_unit'), true) }.onClick(() => { this.themeExpanded = false; this.languageExpanded = false; this.iconColorExpanded = false; this.settingsDialog = 'rules'; })
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
                .selectedColor(this.iconColor('ic_eye'))
                .switchPointColor('#FFFFFF')
                .onChange((isOn: boolean) => { this.debugKeepScreenOn = isOn; this.applyKeepScreenOn(); this.persistData(); })
            }.width('100%').height(50)
            Divider().color(this.borderSubtle()).width('100%').padding({ left: 32 })
            Row({ space: 12 }) {
              Image($rawfile('ic_bug.svg')).width(20).height(20)
                .colorFilter(createStrokeIconColorFilter(this.iconColor('ic_bug')))
              Text(this.t('show_debug_info')).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.showDebugInfo })
                .selectedColor(this.iconColor('ic_bug'))
                .switchPointColor('#FFFFFF')
                .onChange((isOn: boolean) => { this.showDebugInfo = isOn; this.persistData(); })
            }.width('100%').height(50)
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
        }.width('100%').constraintSize({ minHeight: '100%' }).padding(14)
        .onClick(() => { this.themeExpanded = false; this.languageExpanded = false; this.iconColorExpanded = false; this.searchExpanded = false; this.sourcesExpanded = false; this.readerExpanded = false; this.enginesExpanded = false; this.rulesExpanded = false; })
      }.layoutWeight(1).edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .scrollBar(BarState.Auto)
      .scrollBarColor(this.scrollBarColor()).scrollBarWidth(6)
      if (this.themeExpanded) {
        Column({ space: 0 }) {
          this.ThemeOptionRow('light', this.t('light'), false)
          this.ThemeOptionRow('dark', this.t('dark'), true)
          this.ThemeOptionRow('system', this.t('follow_system'), true)
        }
        .width('35%')
        .backgroundColor(this.cardBg())
        .borderRadius(12)
        .border({ width: 1, color: this.isDark() ? '#33FFFFFF' : '#33000000' })
        .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
        .position({ x: '63%', y: this.themeRowBottom - this.settingsStackTop + 4 })
        .zIndex(9999)
      }
      if (this.languageExpanded) {
        Column({ space: 0 }) {
          this.LanguageOptionRow('system', this.t('follow_system'), false)
          this.LanguageOptionRow('zh', this.t('lang_zh'), true)
          this.LanguageOptionRow('en', this.t('lang_en'), true)
        }
        .width('35%')
        .backgroundColor(this.cardBg())
        .borderRadius(12)
        .border({ width: 1, color: this.isDark() ? '#33FFFFFF' : '#33000000' })
        .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
        .position({ x: '63%', y: this.languageRowBottom - this.settingsStackTop + 4 })
        .zIndex(9999)
      }
      if (this.iconColorExpanded) {
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
        }
        .width('35%')
        .backgroundColor(this.cardBg())
        .borderRadius(12)
        .border({ width: 1, color: this.isDark() ? '#33FFFFFF' : '#33000000' })
        .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
        .position({ x: '63%', y: this.iconColorRowBottom - this.settingsStackTop + 4 })
        .zIndex(9999)
      }
      if (this.settingsDialog.length > 0) this.SettingsDialog()
      if (this.updateDialogVisible) this.UpdateDialog()
    }.layoutWeight(1).backgroundColor(this.appBg())
    .onAreaChange((_old: Area, newArea: Area) => {
      this.settingsStackTop = Number(newArea.globalPosition.y);
    })
  }

  @Builder
  private DialogLinkRow(label: string, value: string, showTopBorder: boolean) {
    Row() {
      Text(label).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
      Text(value).fontSize(13).fontColor(this.secondaryText())
    }
    .width('100%')
    .height(50)
    .border(showTopBorder ? { width: { top: 1 }, color: this.borderSubtle() } : { width: 0 })
  }

  @Builder
  private DialogToggleRow(label: string, isOn: boolean, showTopBorder: boolean, onChange: (isOn: boolean) => void) {
    Row() {
      Text(label).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor(this.colorfulAccent('toggle-dialog'))
        .switchPointColor('#FFFFFF')
        .constraintSize({ maxHeight: 32 })
        .onChange(onChange)
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
      Stack() {
        Column({ space: 16 }) {
          if (this.settingsDialog === 'search') {
            this.DialogHeader(this.t('search_menu'))
            Column({ space: 0 }) {
              Row() {
                Text(this.t('search_mode')).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
                Text(this.searchModeDisplay()).fontSize(14).fontColor(this.colorfulAccent('dialog-value-search_mode'))
                Image($rawfile(this.dlgSearchModeExpanded ? 'ic_chevron_up.svg' : 'ic_chevron_down.svg')).width(16).height(16)
                  .colorFilter(createStrokeIconColorFilter(this.secondaryText()))
              }
              .width('100%').height(50)
              .onClick(() => { this.dlgSearchModeExpanded = !this.dlgSearchModeExpanded; this.dlgLangExpanded = false; this.dlgEngineExpanded = false; this.dlgResultModeExpanded = false; this.themeExpanded = false; this.languageExpanded = false; this.iconColorExpanded = false; })
            }.width('100%')
            Column({ space: 0 }) {
              Row() {
                Text(this.t('language_pref')).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
                Text(this.languageModeDisplay()).fontSize(14).fontColor(this.colorfulAccent('dialog-value-language_pref'))
                Image($rawfile(this.dlgLangExpanded ? 'ic_chevron_up.svg' : 'ic_chevron_down.svg')).width(16).height(16)
                  .colorFilter(createStrokeIconColorFilter(this.secondaryText()))
              }
              .width('100%').height(50)
              .border({ width: { top: 1 }, color: this.borderSubtle() })
              .onClick(() => { this.dlgLangExpanded = !this.dlgLangExpanded; this.dlgSearchModeExpanded = false; this.dlgEngineExpanded = false; this.dlgResultModeExpanded = false; this.themeExpanded = false; this.languageExpanded = false; this.iconColorExpanded = false; })
            }.width('100%')
            Column({ space: 0 }) {
              Row() {
                Text('结果筛选').fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
                Text(this.searchResultModeDisplay()).fontSize(14).fontColor(this.colorfulAccent('dialog-value-result_mode'))
                Image($rawfile(this.dlgResultModeExpanded ? 'ic_chevron_up.svg' : 'ic_chevron_down.svg')).width(16).height(16)
                  .colorFilter(createStrokeIconColorFilter(this.secondaryText()))
              }
              .width('100%').height(50)
              .border({ width: { top: 1 }, color: this.borderSubtle() })
              .onClick(() => { this.dlgResultModeExpanded = !this.dlgResultModeExpanded; this.dlgSearchModeExpanded = false; this.dlgLangExpanded = false; this.dlgEngineExpanded = false; this.themeExpanded = false; this.languageExpanded = false; this.iconColorExpanded = false; })
            }.width('100%')
            Column({ space: 0 }) {
              Row() {
                Text(this.t('search_engine')).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
                Text(this.selectedEngine().name).fontSize(14).fontColor(this.colorfulAccent('dialog-value-search_engine'))
                Image($rawfile(this.dlgEngineExpanded ? 'ic_chevron_up.svg' : 'ic_chevron_down.svg')).width(16).height(16)
                  .colorFilter(createStrokeIconColorFilter(this.secondaryText()))
              }
              .width('100%').height(50)
              .border({ width: { top: 1 }, color: this.borderSubtle() })
              .onClick(() => { this.dlgEngineExpanded = !this.dlgEngineExpanded; this.dlgSearchModeExpanded = false; this.dlgLangExpanded = false; this.dlgResultModeExpanded = false; this.themeExpanded = false; this.languageExpanded = false; this.iconColorExpanded = false; })
            }.width('100%')
            if (this.selectedEngine().requiresKey) {
              Column({ space: 8 }) {
                Text(this.t('api_config')).fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.colorfulAccent('api-config-label')).width('100%')
                if (this.selectedEngine().engineType === 'brave-api') {
                  TextInput({ placeholder: this.t('api_key_hint'), text: this.braveApiKey })
                    .height(42).fontColor(this.primaryText()).placeholderColor(this.secondaryText())
                    .backgroundColor(this.inputBg()).borderRadius(12).padding({ left: 10, right: 10 })
                    .type(InputType.Password)
                    .onChange((value: string) => { this.braveApiKey = value; this.persistData(); })
                }
                if (this.selectedEngine().engineType === 'google-cse-api') {
                  TextInput({ placeholder: this.t('api_key_hint'), text: this.googleApiKey })
                    .height(42).fontColor(this.primaryText()).placeholderColor(this.secondaryText())
                    .backgroundColor(this.inputBg()).borderRadius(12).padding({ left: 10, right: 10 })
                    .type(InputType.Password)
                    .onChange((value: string) => { this.googleApiKey = value; this.persistData(); })
                  TextInput({ placeholder: this.t('google_cx_hint'), text: this.googleCx })
                    .height(42).fontColor(this.primaryText()).placeholderColor(this.secondaryText())
                    .backgroundColor(this.inputBg()).borderRadius(12).padding({ left: 10, right: 10 })
                    .onChange((value: string) => { this.googleCx = value; this.persistData(); })
                }
              }
              .width('100%')
              .padding({ left: 14, right: 14, top: 8, bottom: 8 })
              .borderRadius(12)
              .backgroundColor(this.inputBg())
            }
            Column() { this.DialogToggleRow(this.t('all_engines'), this.searchAllEngines, true, (isOn: boolean) => { this.searchAllEngines = isOn; this.persistData(); }) }
            TextInput({ placeholder: this.t('extra_terms'), text: this.extraSearchTerms }).height(42).fontColor(this.primaryText()).placeholderColor(this.secondaryText()).backgroundColor(this.inputBg()).borderRadius(12).padding({ left: 10, right: 10 }).onChange((value: string) => { this.extraSearchTerms = value; })
            TextInput({ placeholder: this.t('site_hint'), text: this.siteHint }).height(42).fontColor(this.primaryText()).placeholderColor(this.secondaryText()).backgroundColor(this.inputBg()).borderRadius(12).padding({ left: 10, right: 10 }).onChange((value: string) => { this.siteHint = value; })
          } else if (this.settingsDialog === 'sources') {
            this.DialogHeader(this.t('source_switch'))
            Column({ space: 0 }) {
              Column() { this.DialogToggleRow(this.t('search_engine'), this.enableSearchEngines, false, (isOn: boolean) => { this.enableSearchEngines = isOn; this.persistData(); }) }
              Column() { this.DialogLinkRow(this.t('html_rules'), this.enableHtmlRules ? this.t('on') : this.t('off'), true) }.onClick(() => { this.enableHtmlRules = !this.enableHtmlRules; this.persistData(); })
              Column() { this.DialogLinkRow(this.t('remote_rules'), this.remoteRuleCount + this.t('rules_unit'), true) }.onClick(() => this.updateRemoteRules())
            }.width('100%')
            Text(this.remoteRuleStatus).fontSize(12).fontColor(this.secondaryText()).width('100%')
          } else if (this.settingsDialog === 'reader') {
            this.DialogHeader(this.t('display_reading'))
            Column({ space: 0 }) {
              Column() { this.DialogToggleRow(this.t('auto_cover'), this.autoCoverEnabled, false, (isOn: boolean) => { this.autoCoverEnabled = isOn; this.persistData(); }) }
              Column() { this.DialogToggleRow(this.t('show_page_num'), this.showImageIndex, true, (isOn: boolean) => { this.showImageIndex = isOn; this.persistData(); }) }
            }.width('100%')
            Column({ space: 0 }) {
              Row() {
                Text(this.t('reading_bg')).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
                Text(this.readerDarkMode ? this.t('dark_color') : this.t('light_color')).fontSize(14).fontColor(this.colorfulAccent('dialog-value-reading_bg'))
                Image($rawfile(this.dlgReaderBgExpanded ? 'ic_chevron_up.svg' : 'ic_chevron_down.svg')).width(16).height(16)
                  .colorFilter(createStrokeIconColorFilter(this.secondaryText()))
              }
              .width('100%').height(50)
              .border({ width: { top: 1 }, color: this.borderSubtle() })
              .onClick(() => { this.dlgReaderBgExpanded = !this.dlgReaderBgExpanded; this.dlgMaxResultsExpanded = false; this.dlgMaxPagesExpanded = false; this.themeExpanded = false; this.languageExpanded = false; this.iconColorExpanded = false; })
            }.width('100%')
            Column({ space: 0 }) {
              Row() {
                Text(this.t('max_results')).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
                Text(this.maxSearchResults + this.t('items_unit')).fontSize(14).fontColor(this.colorfulAccent('dialog-value-max_results'))
                Image($rawfile(this.dlgMaxResultsExpanded ? 'ic_chevron_up.svg' : 'ic_chevron_down.svg')).width(16).height(16)
                  .colorFilter(createStrokeIconColorFilter(this.secondaryText()))
              }
              .width('100%').height(50)
              .border({ width: { top: 1 }, color: this.borderSubtle() })
              .onClick(() => { this.dlgMaxResultsExpanded = !this.dlgMaxResultsExpanded; this.dlgReaderBgExpanded = false; this.dlgMaxPagesExpanded = false; this.themeExpanded = false; this.languageExpanded = false; this.iconColorExpanded = false; })
            }.width('100%')
            Column({ space: 0 }) {
              Row() {
                Text(this.t('chapter_pages')).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
                Text(this.maxReaderPages + this.t('pages_unit')).fontSize(14).fontColor(this.colorfulAccent('dialog-value-chapter_pages'))
                Image($rawfile(this.dlgMaxPagesExpanded ? 'ic_chevron_up.svg' : 'ic_chevron_down.svg')).width(16).height(16)
                  .colorFilter(createStrokeIconColorFilter(this.secondaryText()))
              }
              .width('100%').height(50)
              .border({ width: { top: 1 }, color: this.borderSubtle() })
              .onClick(() => { this.dlgMaxPagesExpanded = !this.dlgMaxPagesExpanded; this.dlgReaderBgExpanded = false; this.dlgMaxResultsExpanded = false; this.themeExpanded = false; this.languageExpanded = false; this.iconColorExpanded = false; })
            }.width('100%')
          } else if (this.settingsDialog === 'rules') {
            this.DialogHeader(this.t('rule_settings'))
            Column({ space: 0 }) {
              Column() { this.DialogLinkRow(this.t('built_in_rules'), (VERIFIED_DOMAIN_COUNT + PUBLIC_ACCESS_DOMAIN_COUNT) + this.t('rules_unit'), false) }.onClick(() => {
                this.editorMode = 'advanced';
                this.editorEditable = false;
                this.ruleViewerTitle = this.t('built_in_rules');
                this.ruleViewerText = this.buildBuiltinRulesSummary();
                this.openEditorFullscreen(this.ruleViewerTitle, true);
              })
              Column() { this.DialogLinkRow(this.t('advanced_rules'), this.advancedRules.length + this.t('rules_unit'), true) }.onClick(() => {
                this.editorMode = 'advanced';
                this.editorEditable = true;
                this.ruleViewerTitle = this.t('advanced_rules');
                this.ruleViewerText = JSON.stringify(this.advancedRules, null, 2);
                this.openEditorFullscreen(this.ruleViewerTitle, true);
              })
              Column() { this.DialogLinkRow(this.t('remote_rules'), this.onlineRules.length + this.t('rules_unit'), true) }.onClick(() => {
                this.editorMode = 'advanced';
                this.editorEditable = false;
                this.ruleViewerTitle = this.t('remote_rules');
                this.ruleViewerText = JSON.stringify(this.onlineRules, null, 2);
                this.openEditorFullscreen(this.ruleViewerTitle, true);
              })
              Column() { this.DialogLinkRow(this.t('cover_accuracy'), this.coverAccuracyIndex === null ? '0' : this.coverAccuracyIndex.count.toString(), true) }.onClick(() => this.updateCoverAccuracy())
              Column() { this.DialogLinkRow('屏蔽域名', searchFilterConfig.blockedDomains.length + '条', true) }.onClick(() => {
                this.editorMode = 'filter_domains'; this.editorEditable = true;
                this.customRuleText = searchFilterConfig.blockedDomains.join('\n');
                this.openEditorFullscreen('屏蔽域名（每行一个）', false);
              })
              Column() { this.DialogLinkRow('屏蔽词', searchFilterConfig.blockedWords.length + '条', true) }.onClick(() => {
                this.editorMode = 'filter_words'; this.editorEditable = true;
                this.customRuleText = searchFilterConfig.blockedWords.join('\n');
                this.openEditorFullscreen('屏蔽词（每行一个）', false);
              })
              Column() { this.DialogLinkRow('噪音标题词', searchFilterConfig.noiseTitleWords.length + '条', true) }.onClick(() => {
                this.editorMode = 'filter_noise'; this.editorEditable = true;
                this.customRuleText = searchFilterConfig.noiseTitleWords.join('\n');
                this.openEditorFullscreen('噪音标题词（每行一个）', false);
              })
            }.width('100%')
            Button(this.updatingRules ? '更新中...' : '更新远程规则')
              .width('100%').height(38).fontSize(14).fontColor('#FFFFFF')
              .backgroundColor(this.updatingRules ? this.borderSubtle() : this.actionBg())
              .borderRadius(10).margin({ top: 8 })
              .onClick(() => { if (!this.updatingRules) this.updateRemoteRules(); })
            TextInput({ placeholder: this.t('remote_url'), text: this.remoteRuleUrl }).height(42).fontColor(this.primaryText()).placeholderColor(this.secondaryText()).backgroundColor(this.inputBg()).borderRadius(12).padding({ left: 10, right: 10 }).onChange((value: string) => { this.remoteRuleUrl = value; })
            Text(this.t('online_rule_changes')).fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).width('100%').margin({ top: 8 })
            Text(this.remoteRuleStatus).fontSize(12).fontColor(this.secondaryText()).width('100%')
            Text(this.coverAccuracyStatus).fontSize(12).fontColor(this.secondaryText()).width('100%')
          } else {
            this.DialogHeader(this.t('advanced_rules'))
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
        .width('100%')
        .padding(14)
        .backgroundColor(this.cardBg())
        .borderRadius(16)
        .shadow({ radius: 20, color: '#18000000', offsetX: 0, offsetY: 4 })
        .onClick(() => {
          if (this.dlgSearchModeExpanded || this.dlgLangExpanded || this.dlgEngineExpanded || this.dlgResultModeExpanded ||
            this.dlgReaderBgExpanded || this.dlgMaxResultsExpanded || this.dlgMaxPagesExpanded) {
            this.dlgSearchModeExpanded = false;
            this.dlgLangExpanded = false;
            this.dlgEngineExpanded = false;
            this.dlgResultModeExpanded = false;
            this.dlgReaderBgExpanded = false;
            this.dlgMaxResultsExpanded = false;
            this.dlgMaxPagesExpanded = false;
          }
        })

        if (this.dlgSearchModeExpanded) {
          Column({ space: 0 }) {
            this.SelectOptionRow(this.t('mixed'), this.searchMode === 'mixed', false, () => { this.searchMode = 'mixed'; this.persistData(); this.dlgSearchModeExpanded = false; })
            this.SelectOptionRow(this.t('engine_only'), this.searchMode === 'engine_only', true, () => { this.searchMode = 'engine_only'; this.persistData(); this.dlgSearchModeExpanded = false; })
            this.SelectOptionRow(this.t('api_only'), this.searchMode === 'api_only', true, () => { this.searchMode = 'api_only'; this.persistData(); this.dlgSearchModeExpanded = false; })
          }
          .width('35%')
          .backgroundColor(this.cardBg())
          .borderRadius(12)
          .border({ width: 1, color: this.isDark() ? '#33FFFFFF' : '#33000000' })
          .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
          .position({ x: '63%', y: 78 })
          .zIndex(9999)
        }
        if (this.dlgLangExpanded) {
          Column({ space: 0 }) {
            this.SelectOptionRow(this.t('chinese'), this.languageMode === 'chinese', false, () => { this.languageMode = 'chinese'; this.persistData(); this.dlgLangExpanded = false; })
            this.SelectOptionRow(this.t('english'), this.languageMode === 'english', true, () => { this.languageMode = 'english'; this.persistData(); this.dlgLangExpanded = false; })
            this.SelectOptionRow(this.t('auto'), this.languageMode === 'auto', true, () => { this.languageMode = 'auto'; this.persistData(); this.dlgLangExpanded = false; })
          }
          .width('35%')
          .backgroundColor(this.cardBg())
          .borderRadius(12)
          .border({ width: 1, color: this.isDark() ? '#33FFFFFF' : '#33000000' })
          .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
          .position({ x: '63%', y: 128 })
          .zIndex(9999)
        }
        if (this.dlgResultModeExpanded) {
          Column({ space: 0 }) {
            this.SelectOptionRow('规则筛选', this.searchResultMode === 'rule_filter', false, () => { this.searchResultMode = 'rule_filter'; setSearchResultFilterMode('rule_filter'); this.persistData(); this.dlgResultModeExpanded = false; })
            this.SelectOptionRow('浏览器', this.searchResultMode === 'browser', true, () => { this.searchResultMode = 'browser'; setSearchResultFilterMode('browser'); this.persistData(); this.dlgResultModeExpanded = false; })
          }
          .width('35%')
          .backgroundColor(this.cardBg())
          .borderRadius(12)
          .border({ width: 1, color: this.isDark() ? '#33FFFFFF' : '#33000000' })
          .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
          .position({ x: '63%', y: 178 })
          .zIndex(9999)
        }
        if (this.dlgEngineExpanded) {
          Scroll() {
            Column({ space: 0 }) {
              ForEach(this.searchEngines, (engine: SearchEngineConfig, index: number) => {
                this.SelectOptionRow(engine.name, this.selectedEngineIndex === index, index > 0,
                  () => { this.selectedEngineIndex = index; this.persistData(); this.dlgEngineExpanded = false; })
              }, (engine: SearchEngineConfig) => engine.id)
            }
          }
          .scrollable(ScrollDirection.Vertical)
          .scrollBar(BarState.Auto)
          .scrollBarColor(this.scrollBarColor()).scrollBarWidth(6)
          .constraintSize({ maxHeight: 300 })
          .width('35%')
          .backgroundColor(this.cardBg())
          .borderRadius(12)
          .border({ width: 1, color: this.isDark() ? '#33FFFFFF' : '#33000000' })
          .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
          .position({ x: '63%', y: 228 })
          .zIndex(9999)
        }
        if (this.dlgReaderBgExpanded) {
          Column({ space: 0 }) {
            this.SelectOptionRow(this.t('dark_color'), this.readerDarkMode, false, () => { this.readerDarkMode = true; this.persistData(); this.dlgReaderBgExpanded = false; })
            this.SelectOptionRow(this.t('light_color'), !this.readerDarkMode, true, () => { this.readerDarkMode = false; this.persistData(); this.dlgReaderBgExpanded = false; })
          }
          .width('35%')
          .backgroundColor(this.cardBg())
          .borderRadius(12)
          .border({ width: 1, color: this.isDark() ? '#33FFFFFF' : '#33000000' })
          .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
          .position({ x: '63%', y: 178 })
          .zIndex(9999)
        }
        if (this.dlgMaxResultsExpanded) {
          Column({ space: 0 }) {
            this.SelectOptionRow('40' + this.t('items_unit'), this.maxSearchResults === 40, false, () => { this.maxSearchResults = 40; this.persistData(); this.dlgMaxResultsExpanded = false; })
            this.SelectOptionRow('80' + this.t('items_unit'), this.maxSearchResults === 80, true, () => { this.maxSearchResults = 80; this.persistData(); this.dlgMaxResultsExpanded = false; })
            this.SelectOptionRow('160' + this.t('items_unit'), this.maxSearchResults === 160, true, () => { this.maxSearchResults = 160; this.persistData(); this.dlgMaxResultsExpanded = false; })
          }
          .width('35%')
          .backgroundColor(this.cardBg())
          .borderRadius(12)
          .border({ width: 1, color: this.isDark() ? '#33FFFFFF' : '#33000000' })
          .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
          .position({ x: '63%', y: 228 })
          .zIndex(9999)
        }
        if (this.dlgMaxPagesExpanded) {
          Column({ space: 0 }) {
            this.SelectOptionRow('30' + this.t('pages_unit'), this.maxReaderPages === 30, false, () => { this.maxReaderPages = 30; this.persistData(); this.dlgMaxPagesExpanded = false; })
            this.SelectOptionRow('50' + this.t('pages_unit'), this.maxReaderPages === 50, true, () => { this.maxReaderPages = 50; this.persistData(); this.dlgMaxPagesExpanded = false; })
          }
          .width('35%')
          .backgroundColor(this.cardBg())
          .borderRadius(12)
          .border({ width: 1, color: this.isDark() ? '#33FFFFFF' : '#33000000' })
          .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
          .position({ x: '63%', y: 278 })
          .zIndex(9999)
        }
      }
      .width('80%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.dialogOverlay())
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      if (this.dlgSearchModeExpanded || this.dlgLangExpanded || this.dlgEngineExpanded || this.dlgResultModeExpanded || this.dlgReaderBgExpanded || this.dlgMaxResultsExpanded || this.dlgMaxPagesExpanded) {
        this.dlgSearchModeExpanded = false;
        this.dlgLangExpanded = false;
        this.dlgEngineExpanded = false;
        this.dlgResultModeExpanded = false;
        this.dlgReaderBgExpanded = false;
        this.dlgMaxResultsExpanded = false;
        this.dlgMaxPagesExpanded = false;
      } else {
        this.settingsDialog = '';
      }
    })
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
            if (this.updatingRules || this.updatingCatalog || this.syncingFilterWords) {
              LoadingProgress().width(18).height(18).color(this.colorfulAccent('loading-update'))
            }
          }.width('100%').height(50).onClick(() => { this.updateAll(); })
          Divider().color(this.borderSubtle()).width('100%').padding({ left: 32 })
          Row() {
            Image($rawfile('ic_rule.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_rule'))).margin({ right: 10 })
            Text(this.t('update_rules')).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
            if (this.updatingRules) {
              LoadingProgress().width(18).height(18).color(this.colorfulAccent('loading-update'))
            } else {
              Text(this.remoteRuleCount + this.t('rules_unit')).fontSize(13).fontColor(this.secondaryText())
            }
          }.width('100%').height(50).onClick(() => { this.updateRemoteRules(); })
          if (this.updatingRules || this.ruleProgressPercent > 0) {
            Column({ space: 4 }) {
              Progress({ value: this.ruleProgressPercent, total: 100, type: ProgressType.Linear })
                .width('100%').height(5).color(this.colorfulAccent('progress-catalog'))
              Text(this.ruleProgressText()).fontSize(11).fontColor(this.secondaryText()).width('100%')
            }.width('100%').padding({ left: 30, right: 4, bottom: 6 })
          } else if (this.remoteRuleStatus.length > 0 && this.remoteRuleStatus !== this.t('remote_not_updated')) {
            Text(this.remoteRuleStatus).fontSize(11).fontColor(this.secondaryText())
              .width('100%').padding({ left: 30, right: 4, bottom: 6 })
          }
          Divider().color(this.borderSubtle()).width('100%').padding({ left: 32 })
          Row() {
            Image($rawfile('ic_shelf.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_shelf'))).margin({ right: 10 })
            Text(this.t('update_catalog')).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
            if (this.updatingCatalog) {
              LoadingProgress().width(18).height(18).color(this.colorfulAccent('loading-update'))
            } else {
              Text(this.catalogUpdateAvailable
                ? (this.remoteCatalogItemCount > 0
                  ? this.catalogCategories.length + ' → ' + this.remoteCatalogItemCount + this.t('items_unit')
                  : this.catalogStage('有更新', 'Update available'))
                : this.catalogCategories.length + this.t('items_unit'))
                .fontSize(13)
                .fontColor(this.catalogUpdateAvailable ? this.warnText() : this.secondaryText())
            }
          }.width('100%').height(50).onClick(() => { this.updateCatalog(); })
          if (this.updatingCatalog || this.catalogProgressPercent > 0) {
            Column({ space: 4 }) {
              Progress({ value: this.catalogProgressPercent, total: 100, type: ProgressType.Linear })
                .width('100%').height(5).color(this.colorfulAccent('progress-catalog'))
              Text(this.catalogProgressText()).fontSize(11).fontColor(this.secondaryText()).width('100%')
            }.width('100%').padding({ left: 30, right: 4, bottom: 6 })
          } else if (this.catalogUpdateStatus.length > 0) {
            Text(this.catalogUpdateStatus).fontSize(11).fontColor(this.secondaryText())
              .width('100%').padding({ left: 30, right: 4, bottom: 6 })
          }
          Divider().color(this.borderSubtle()).width('100%').padding({ left: 32 })
          Row() {
            Image($rawfile('ic_block.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_block'))).margin({ right: 10 })
            Text(this.catalogStage('同步屏蔽词', 'Sync Filter Words')).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
            if (this.syncingFilterWords) {
              LoadingProgress().width(18).height(18).color(this.colorfulAccent('loading-update'))
            } else {
              Text((searchFilterConfig.blockedDomains.length + searchFilterConfig.blockedWords.length + searchFilterConfig.noiseTitleWords.length) + this.catalogStage('条', ' items')).fontSize(13).fontColor(this.secondaryText())
            }
          }.width('100%').height(50).onClick(() => { this.syncFilterWords(); })
          if (this.syncingFilterWords || this.filterWordsProgressPercent > 0) {
            Column({ space: 4 }) {
              Progress({ value: this.filterWordsProgressPercent, total: 100, type: ProgressType.Linear })
                .width('100%').height(5).color(this.colorfulAccent('progress-catalog'))
              Text(this.filterWordsProgressText()).fontSize(11).fontColor(this.secondaryText()).width('100%')
            }.width('100%').padding({ left: 30, right: 4, bottom: 6 })
          } else if (this.filterWordsStatus.length > 0) {
            Text(this.filterWordsStatus).fontSize(11).fontColor(this.secondaryText())
              .width('100%').padding({ left: 30, right: 4, bottom: 6 })
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
  private CatalogListCard(item: CatalogItem) {
    Row() {
      if (this.catalogItemCover(item).length > 0) {
        Image(this.catalogItemCover(item)).width(56).height(76).borderRadius(8).objectFit(ImageFit.Cover)
      } else {
        Column() {
          Text(item.title.substring(0, 1)).fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.colorfulAccent('catalog-avatar-' + item.title))
        }.width(56).height(76).borderRadius(8).justifyContent(FlexAlign.Center).backgroundColor(this.coverPlaceholderBg())
      }
      Column() {
        Text(item.title).fontSize(15).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).width('100%').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(item.sources.length + ' 来源 · ' + (item.verifiedChapterCount !== undefined ? item.verifiedChapterCount + ' 章' : '未知')).fontSize(12).fontColor(this.secondaryText()).width('100%').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 4 })
        Text(item.sources.length > 0 ? (item.sources[0].domain ?? '') : '').fontSize(11).fontColor(this.secondaryText()).width('100%').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 4 })
      }.layoutWeight(1).margin({ left: 12 }).alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.cardBg())
    .borderRadius(14)
    .margin({ bottom: 10 })
    .onClick(() => {
      if (!this.isLongPressing) {
        const source = this.preferredCatalogSource(item);
        if (source?.detailUrl) {
          const cover = source.coverUrl ? source.coverUrl : this.catalogItemCover(item);
          const shelfMatch = this.bookshelf.find((b: BookshelfItem) => b.url === source!.detailUrl ||
            (b.title === item.title && b.lastChapterUrl.length > 0));
          if (shelfMatch && shelfMatch.lastChapterUrl.length > 0) {
            this.openBookUnified(shelfMatch.url, shelfMatch.title, shelfMatch.sourceId, cover,
              shelfMatch.lastChapterUrl, shelfMatch.lastChapterTitle);
            return;
          }
          const histMatch = this.history.find((h: ReadingHistoryItem) =>
            (h.detailUrl !== undefined && h.detailUrl.length > 0 && h.detailUrl === source!.detailUrl) ||
            (h.title === item.title && h.url.length > 0));
          if (histMatch && histMatch.detailUrl !== undefined && histMatch.detailUrl.length > 0 &&
            histMatch.detailUrl !== histMatch.url) {
            this.openBookUnified(histMatch.detailUrl!, histMatch.title, histMatch.sourceId, cover,
              histMatch.url, histMatch.chapterTitle);
            return;
          }
          this.currentCover = cover;
          this.loadDetail(source.detailUrl, item.title, this.findRuleByUrl(source.detailUrl));
        } else if (source?.searchUrl) {
          this.queryText = item.title;
          this.activeTab = 'search';
          this.startSearch();
        }
      }
    })
    .parallelGesture(LongPressGesture({ repeat: false, duration: 500 }).onAction((event: GestureEvent) => {
      this.isLongPressing = true;
      this.bookLongPressTitle = item.title;
      this.bookLongPressUrl = '';
      this.bookLongPressCover = this.catalogItemCover(item);
      this.bookLongPressIsFavorite = this.bookshelf.some((b: BookshelfItem) => b.title === item.title);
      this.bookLongPressSourceName = item.sources.length > 0 ? (item.sources[0].domain ?? '') : '';
      this.setLongPressPosition(event.fingerList[0].globalX, event.fingerList[0].globalY);
      this.bookLongPressVisible = true;
    }))
  }

  @Builder
  private CatalogItemCard(item: CatalogItem) {
    Column() {
      Stack() {
        if (this.catalogItemCover(item).length > 0) {
          Image(this.catalogItemCover(item)).width('100%').height(140).objectFit(ImageFit.Cover).borderRadius({ topLeft: 12, topRight: 12 })
        } else {
          Column() {
            Text(item.title.substring(0, 1)).fontSize(28).fontWeight(FontWeight.Bold).fontColor(this.colorfulAccent('catalog-avatar-' + item.title))
          }.width('100%').height(140).justifyContent(FlexAlign.Center).backgroundColor(this.coverPlaceholderBg()).borderRadius({ topLeft: 12, topRight: 12 })
        }
      }.width('100%').height(140).clip(true)

      Text(item.title).fontSize(12).fontColor(this.colorfulValue(item.id)).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').padding({ left: 6, right: 6, top: 6, bottom: 6 })
    }
    .width('31%')
    .backgroundColor(this.cardBg())
    .borderRadius(12)
    .clip(true)
    .margin({ bottom: 8, right: '2%' })
    .onClick(() => {
      if (!this.isLongPressing) {
        const source = this.preferredCatalogSource(item);
        if (source?.detailUrl) {
          const cover = source.coverUrl ? source.coverUrl : this.catalogItemCover(item);
          const shelfMatch = this.bookshelf.find((b: BookshelfItem) => b.url === source!.detailUrl ||
            (b.title === item.title && b.lastChapterUrl.length > 0));
          if (shelfMatch && shelfMatch.lastChapterUrl.length > 0) {
            this.openBookUnified(shelfMatch.url, shelfMatch.title, shelfMatch.sourceId, cover,
              shelfMatch.lastChapterUrl, shelfMatch.lastChapterTitle);
            return;
          }
          const histMatch = this.history.find((h: ReadingHistoryItem) =>
            (h.detailUrl !== undefined && h.detailUrl.length > 0 && h.detailUrl === source!.detailUrl) ||
            (h.title === item.title && h.url.length > 0));
          if (histMatch && histMatch.detailUrl !== undefined && histMatch.detailUrl.length > 0 &&
            histMatch.detailUrl !== histMatch.url) {
            this.openBookUnified(histMatch.detailUrl!, histMatch.title, histMatch.sourceId, cover,
              histMatch.url, histMatch.chapterTitle);
            return;
          }
          this.currentCover = cover;
          this.loadDetail(source.detailUrl, item.title, this.findRuleByUrl(source.detailUrl));
        } else if (source?.searchUrl) {
          this.queryText = item.title;
          this.activeTab = 'search';
          this.startSearch();
        }
      }
    })
    .parallelGesture(LongPressGesture({ repeat: false, duration: 500 }).onAction((event: GestureEvent) => {
      this.isLongPressing = true;
      this.bookLongPressTitle = item.title;
      this.bookLongPressUrl = '';
      this.bookLongPressCover = this.catalogItemCover(item);
      this.bookLongPressIsFavorite = this.bookshelf.some((b: BookshelfItem) => b.title === item.title);
      this.bookLongPressSourceName = item.sources.length > 0 ? (item.sources[0].domain ?? '') : '';
      this.setLongPressPosition(event.fingerList[0].globalX, event.fingerList[0].globalY);
      this.bookLongPressVisible = true;
    }))
  }

  @Builder
  private ShelfPage() {
    Scroll() {
      Column() {
        Column() {}.width('100%').height(this.compactContentTopInset())

        if (this.showDebugInfo) {
          Row() {
            Text('Catalog: ' + (this.remoteCatalog !== null ? 'loaded' : 'null')).fontSize(10).fontColor(this.colorfulValue('debug-Catalog'))
            Text('Categories: ' + this.catalogCategories.length).fontSize(10).fontColor(this.colorfulValue('debug-Categories')).margin({ left: 8 })
            Text('Items: ' + this.catalogItems.length).fontSize(10).fontColor(this.colorfulValue('debug-CatalogItems')).margin({ left: 8 })
            Text('Bookshelf: ' + this.bookshelf.length).fontSize(10).fontColor(this.colorfulValue('debug-Bookshelf')).margin({ left: 8 })
            Text('CoverCache: ' + this.coverCacheDir).fontSize(10).fontColor(this.colorfulValue('debug-CoverCache')).margin({ left: 8 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
          }.width('100%').padding({ left: 14, right: 14, top: 2, bottom: 2 })
        }
        if (this.catalogLoading) {
          Column() {
            LoadingProgress().width(24).height(24).color(this.colorfulAccent('loading-catalog'))
            Text(this.catalogUpdateStatus.length > 0 ? this.catalogUpdateStatus : (this.t('catalog_loading') ?? '加载目录中...')).fontSize(14).fontColor(this.secondaryText()).margin({ top: 8 })
          }.width('100%').height(200).justifyContent(FlexAlign.Center)
        } else if (this.catalogCategories.length > 0) {
          if (this.selectedCatalogCategory.length > 0 && this.catalogItems.length > 0) {
            Stack() {
              Column() {
                if (this.shelfDisplayMode === 'grid') {
                  Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                    ForEach(this.catalogItems, (item: CatalogItem) => {
                      this.CatalogItemCard(item)
                    }, (item: CatalogItem) => item.id)
                  }
                  .width('100%')
                  .padding({ left: 10, right: 10, top: 4, bottom: 14 })
                } else {
                  Column() {
                    ForEach(this.catalogItems, (item: CatalogItem) => {
                      this.CatalogListCard(item)
                    }, (item: CatalogItem) => item.id)
                  }.width('100%').padding({ left: 4, right: 4, top: 4 })
                }
              }
              .width('100%')
              .translate({ x: this.shelfPanOffset })

              if (this.shelfAdjacentDir !== 0 && this.shelfAdjacentItems.length > 0) {
                Column() {
                  if (this.shelfDisplayMode === 'grid') {
                    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                      ForEach(this.shelfAdjacentItems, (item: CatalogItem) => {
                        this.CatalogItemCard(item)
                      }, (item: CatalogItem) => item.id)
                    }
                    .width('100%')
                    .padding({ left: 10, right: 10, top: 4, bottom: 14 })
                  } else {
                    Column() {
                      ForEach(this.shelfAdjacentItems, (item: CatalogItem) => {
                        this.CatalogListCard(item)
                      }, (item: CatalogItem) => item.id)
                    }.width('100%').padding({ left: 4, right: 4, top: 4 })
                  }
                }
                .width('100%')
                .translate({ x: this.shelfAdjacentDir * this.shelfViewportWidth + this.shelfPanOffset })
              }
            }
            .width('100%')
            .alignContent(Alignment.TopStart)
            .parallelGesture(PanGesture({ direction: PanDirection.Horizontal, distance: 8 })
              .onActionStart(() => {
                this.shelfPanStartX = this.shelfPanOffset;
                this.shelfIsPanning = true;
                this.shelfAdjacentDir = 0;
                this.shelfAdjacentItems = [];
              })
              .onActionUpdate((event: PanGestureEvent) => {
                this.shelfPanOffset = this.shelfPanStartX + event.offsetX;
                if (this.shelfAdjacentDir === 0 && Math.abs(event.offsetX) > 5) {
                  const dir = event.offsetX < 0 ? 1 : -1;
                  const adjacentId = this.shelfAdjacentCategory(dir);
                  if (adjacentId.length > 0 && this.remoteCatalog !== null) {
                    this.shelfAdjacentDir = dir;
                    this.shelfAdjacentItems = this.filteredCatalogItems(this.remoteCatalog, adjacentId);
                  }
                }
              })
              .onActionEnd(() => {
                this.shelfIsPanning = false;
                const threshold = this.shelfViewportWidth / 3;
                if (this.shelfPanOffset < -threshold && this.shelfAdjacentDir === 1) {
                  animateTo({ duration: 250, curve: Curve.EaseInOut }, () => {
                    this.shelfPanOffset = -this.shelfViewportWidth;
                  });
                  this.shelfCategoryTimerId = setTimeout(() => {
                    this.shelfSwitchCategory(1);
                    this.shelfPanOffset = 0;
                    this.shelfAdjacentItems = [];
                    this.shelfAdjacentDir = 0;
                  }, 300);
                } else if (this.shelfPanOffset > threshold && this.shelfAdjacentDir === -1) {
                  animateTo({ duration: 250, curve: Curve.EaseInOut }, () => {
                    this.shelfPanOffset = this.shelfViewportWidth;
                  });
                  this.shelfCategoryTimerId = setTimeout(() => {
                    this.shelfSwitchCategory(-1);
                    this.shelfPanOffset = 0;
                    this.shelfAdjacentItems = [];
                    this.shelfAdjacentDir = 0;
                  }, 300);
                } else {
                  animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
                    this.shelfPanOffset = 0;
                  });
                  this.shelfAdjacentItems = [];
                  this.shelfAdjacentDir = 0;
                }
              })
            )
          } else {
            Column() {
              Text(this.t('select_category') ?? '选择分类浏览漫画').fontSize(14).fontColor(this.secondaryText()).margin({ top: 40 })
            }.width('100%').justifyContent(FlexAlign.Center)
          }
        } else {
          Text(this.t('shelf_empty') ?? '暂无目录数据').fontSize(14).fontColor(this.secondaryText()).width('100%').padding(14).backgroundColor(this.cardBg()).borderRadius(16)
        }
        Blank().height(this.contentBottomInset())
      }.width('100%').constraintSize({ minHeight: '100%' }).padding({ left: 10, right: 10 }).alignItems(HorizontalAlign.Start)
    }
    .layoutWeight(1)
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .scrollBarColor(this.scrollBarColor()).scrollBarWidth(6)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .backgroundColor(this.appBg())
    .onAreaChange((_oldValue: Area, newValue: Area) => {
      const width = Number(newValue.width);
      if (width > 0) this.shelfViewportWidth = width;
    })
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
    const ordered = this.catalogSourcesByChapterCount(item);
    let fallback: CatalogSource | null = null;
    for (let i = 0; i < ordered.length; i++) {
      const source = ordered[i];
      if (source.detailUrl && source.detailUrl.length > 0) {
        if (fallback === null) fallback = source;
        if (this.findRuleByUrl(source.detailUrl).id !== this.genericRule().id) return source;
      }
    }
    if (fallback !== null) return fallback;
    return ordered.length > 0 ? ordered[0] : null;
  }

  private closeBookLongPressMenu() {
    this.bookLongPressVisible = false;
    this.isLongPressing = false;
  }

  private setLongPressPosition(globalX: number, globalY: number): void {
    const menuWidth = 180;
    const menuHeight = 280;
    const screenWidth = 1320;
    const screenHeight = 2856;
    const margin = 8;
    let x = globalX;
    let y = globalY;
    if (x + menuWidth + margin > screenWidth) {
      x = screenWidth - menuWidth - margin;
    }
    if (x < margin) x = margin;
    if (y + menuHeight + margin > screenHeight) {
      y = screenHeight - menuHeight - margin;
    }
    if (y < margin) y = margin;
    this.bookLongPressX = x;
    this.bookLongPressY = y;
  }

  private closeAllDialogsAndMenus() {
    this.searchHistoryVisible = false;
    this.updateDialogVisible = false;
    this.editorSearchVisible = false;
    this.editorMenuVisible = false;
    this.editorSeekVisible = false;
    this.editorLinksVisible = false;
    this.editorStatsVisible = false;
    this.editorColorPickerVisible = false;
    this.editorPreviewVisible = false;
    this.themeDialogVisible = false;
    this.languageDialogVisible = false;
    this.historyMenuVisible = false;
    this.bookLongPressVisible = false;
    this.settingsDialog = '';
    this.themeExpanded = false;
    this.languageExpanded = false;
    this.iconColorExpanded = false;
    this.searchExpanded = false;
    this.sourcesExpanded = false;
    this.readerExpanded = false;
    this.enginesExpanded = false;
    this.rulesExpanded = false;
    this.dlgSearchModeExpanded = false;
    this.dlgLangExpanded = false;
    this.dlgResultModeExpanded = false;
    this.dlgReaderBgExpanded = false;
    this.dlgMaxResultsExpanded = false;
    this.dlgMaxPagesExpanded = false;
    this.dlgEngineExpanded = false;
    this.isLongPressing = false;
  }

  @Builder
  private BookLongPressMenu() {
    Column() {
      Column() {
        if (this.bookLongPressCover.length > 0) {
          Image(this.bookLongPressCover).width(40).height(40).borderRadius(8).objectFit(ImageFit.Cover).margin({ right: 8 })
        }
        Text(this.bookLongPressTitle).fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 10, bottom: 8 })
      .alignItems(HorizontalAlign.Start)

      Column() {
        Row({ space: 8 }) {
          Text(this.bookLongPressIsFavorite ? '★' : '☆').fontSize(16).fontColor(this.iconColor('ic_star_filled'))
          Text(this.bookLongPressIsFavorite ? this.t('remove_favorite') : this.t('add_favorite'))
            .fontSize(13).fontColor(this.primaryText())
        }
        .width('100%').padding({ left: 14, top: 10, bottom: 10 })
      }
      .width('100%')
      .onClick(() => {
        if (this.bookLongPressIsFavorite) this.removeBookshelfItem(this.bookLongPressUrl);
        else this.addCurrentToShelf();
        this.closeBookLongPressMenu();
      })

      Column() {
        Text(this.t('search_title'))
          .fontSize(13).fontColor(this.primaryText()).width('100%').padding({ left: 14, top: 10, bottom: 10 })
      }
      .width('100%')
      .onClick(() => {
        this.queryText = this.bookLongPressTitle;
        this.activeTab = 'search';
        this.startSearch();
        this.closeBookLongPressMenu();
      })

      Column() {
        Text(this.t('update_cover'))
          .fontSize(13).fontColor(this.primaryText()).width('100%').padding({ left: 14, top: 10, bottom: 10 })
      }
      .width('100%')
      .onClick(() => {
        this.refreshBookCover(this.bookLongPressUrl);
        this.closeBookLongPressMenu();
      })

      Column() {
        Text(this.t('delete'))
          .fontSize(13).fontColor('#F38BA8').width('100%').padding({ left: 14, top: 10, bottom: 10 })
      }
      .width('100%')
      .onClick(() => {
        this.removeHistoryItem(this.bookLongPressUrl);
        if (this.bookLongPressIsFavorite) this.removeBookshelfItem(this.bookLongPressUrl);
        this.closeBookLongPressMenu();
      })

      Column() {
        Text(this.t('close'))
          .fontSize(13).fontColor(this.secondaryText()).width('100%').padding({ left: 14, top: 10, bottom: 10 })
      }
      .width('100%')
      .onClick(() => {
        this.closeBookLongPressMenu();
      })
    }
    .width(180)
    .backgroundColor(this.cardBg())
    .borderRadius(12)
    .border({ width: 1, color: this.borderSubtle() })
    .shadow({ radius: 12, color: '#40000000', offsetY: 4 })
    .position({ x: this.bookLongPressX, y: this.bookLongPressY })
  }

  @Builder
  private UiIcon(name: string, size: number) {
    Image($rawfile(this.tabIconKey(name) + '.svg'))
      .width(size)
      .height(size)
      .colorFilter(createStrokeIconColorFilter(
        this.activeTab === name ? this.colorfulAccent('tab-' + name) : this.secondaryText()
      ))
  }

  @Builder
  private TabPill(tab: string, label: string) {
    Column({ space: 3 }) {
      this.UiIcon(tab, 22)
      Text(label)
        .fontSize(11)
        .fontColor(this.activeTab === tab ? this.colorfulAccent('tab-' + tab) : this.secondaryText())
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.End)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 4, bottom: 4 })
    .onClick(() => {
      const switchingFromOtherTab = this.activeTab !== tab;
      if (switchingFromOtherTab) this.closeAllDialogsAndMenus();
      if (tab !== 'search' && (this.isLoading || this.webLoading)) this.stopSearch();
      this.activeTab = tab;
      if (tab === 'shelf') this.checkCatalogUpdateOnShelfEntry();
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

  private headerOverlayWidth(): number {
    return 360;
  }

  private contentTopInset(): number {
    return this.headerOverlayHeight();
  }

  private compactContentTopInset(): number {
    // The page is drawn under the translucent header. Reserve exactly the
    // measured status-bar + header height so the first card touches the logo
    // region without being covered by it on devices with different insets.
    return this.headerOverlayHeight();
  }

  private contentBottomInset(): number {
    return 80 + this.bottomSafeInset;
  }

  @Builder
  private HistoryPage() {
    Scroll() {
      Column() {
        Column() {}.width('100%').height(this.compactContentTopInset())
        if (this.showDebugInfo) {
          Row() {
            Text('History: ' + this.history.length).fontSize(10).fontColor(this.colorfulValue('debug-HistoryCount'))
            Text('Bookshelf: ' + this.bookshelf.length).fontSize(10).fontColor(this.colorfulValue('debug-HistBookshelf')).margin({ left: 8 })
            Text('View: ' + this.historyViewMode).fontSize(10).fontColor(this.colorfulValue('debug-HistView')).margin({ left: 8 })
            Text('Tab: ' + this.historyTab).fontSize(10).fontColor(this.colorfulValue('debug-HistTab')).margin({ left: 8 })
            Text('Sources: ' + new Set(this.history.map((h: ReadingHistoryItem) => h.sourceId)).size).fontSize(10).fontColor(this.colorfulValue('debug-HistSources')).margin({ left: 8 })
          }.width('100%').padding({ left: 14, right: 14, top: 2, bottom: 2 })
        }
        Stack() {
          Column() {
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
                    Row() {
                      Text(item.title).fontSize(12).fontColor(this.colorfulValue(item.title)).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
                      if (this.revealedDeleteUrl === item.url) {
                        Image($rawfile('ic_x.svg')).width(18).height(18).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_x')))
                          .padding({ left: 6, right: 6 }).onClick(() => this.removeHistoryItem(item.url))
                      }
                    }.width('100%').padding({ left: 6, top: 4 })
                    Text(item.chapterTitle).fontSize(10).fontColor(this.secondaryText()).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').padding({ left: 6, right: 6, bottom: 2 })
                    if (this.showDebugInfo) {
                      Text(item.sourceName).fontSize(9).fontColor(this.colorfulValue('src-' + item.sourceId)).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').padding({ left: 6, right: 6, bottom: 6 })
                    } else {
                      Text('').height(4)
                    }
                  }.width('31%').margin({ bottom: 8, right: '2%' }).backgroundColor(this.cardBg()).borderRadius(12)
                    .onClick(() => { if (!this.isLongPressing) this.openHistoryItem(item); })
                    .parallelGesture(LongPressGesture({ repeat: false, duration: 500 }).onAction((event: GestureEvent) => {
                      this.isLongPressing = true;
                      this.bookLongPressTitle = item.title;
                      this.bookLongPressUrl = item.url;
                      this.bookLongPressCover = item.cover;
                      this.bookLongPressIsFavorite = this.bookshelf.some((b: BookshelfItem) => b.url === item.url);
                      this.bookLongPressSourceName = item.sourceName;
                      this.setLongPressPosition(event.fingerList[0].globalX, event.fingerList[0].globalY);
                      this.bookLongPressVisible = true;
                    }))
                }, (item: ReadingHistoryItem) => item.url + item.title)
              }.width('100%')
            } else {
              ForEach(this.history, (item: ReadingHistoryItem) => {
                Row() {
                  Column() {
                    this.BookListCard(item.cover, item.title, item.chapterTitle + ' · ' + item.lastReadAt, item.imageCount + this.t('images_unit'))
                    if (this.showDebugInfo) {
                      Text('来源: ' + item.sourceName + ' (' + item.sourceId + ')').fontSize(9).fontColor(this.colorfulValue('src-' + item.sourceId)).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').padding({ left: 14, top: 2 })
                    }
                  }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                  if (this.revealedDeleteUrl === item.url) {
                    Image($rawfile('ic_x.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_x')))
                      .padding(14).onClick(() => this.removeHistoryItem(item.url))
                  }
                }.width('100%')
                  .onClick(() => { if (!this.isLongPressing) this.openHistoryItem(item); })
                  .parallelGesture(LongPressGesture({ repeat: false, duration: 500 }).onAction((event: GestureEvent) => {
                    this.isLongPressing = true;
                    this.bookLongPressTitle = item.title;
                    this.bookLongPressUrl = item.url;
                    this.bookLongPressCover = item.cover;
                    this.bookLongPressIsFavorite = this.bookshelf.some((b: BookshelfItem) => b.url === item.url);
                    this.bookLongPressSourceName = item.sourceName;
                    this.setLongPressPosition(event.fingerList[0].globalX, event.fingerList[0].globalY);
                    this.bookLongPressVisible = true;
                  }))
              }, (item: ReadingHistoryItem) => item.url + item.title)
            }
          }
          .width('100%')
          .translate({ x: this.historyTab === 'history' ? this.historyPanOffset : -this.historyViewportWidth + this.historyPanOffset })

          Column() {
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
                    Row() {
                      Text(item.title).fontSize(12).fontColor(this.colorfulValue(item.title)).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
                      if (this.revealedDeleteUrl === item.url) {
                        Image($rawfile('ic_x.svg')).width(18).height(18).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_x')))
                          .padding({ left: 6, right: 6 }).onClick(() => this.removeBookshelfItem(item.url))
                      }
                    }.width('100%').padding({ left: 6, top: 4 })
                    Text(item.lastChapterTitle.length > 0 ? item.lastChapterTitle : item.sourceName).fontSize(10).fontColor(this.secondaryText()).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').padding({ left: 6, right: 6, bottom: 2 })
                    if (this.showDebugInfo) {
                      Text(item.sourceName).fontSize(9).fontColor(this.colorfulValue('src-' + item.sourceId)).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').padding({ left: 6, right: 6, bottom: 6 })
                    } else {
                      Text('').height(4)
                    }
                  }.width('31%').margin({ bottom: 8, right: '2%' }).backgroundColor(this.cardBg()).borderRadius(12)
                    .onClick(() => { if (!this.isLongPressing) this.openBookshelfItem(item); })
                    .parallelGesture(LongPressGesture({ repeat: false, duration: 500 }).onAction((event: GestureEvent) => {
                      this.isLongPressing = true;
                      this.bookLongPressTitle = item.title;
                      this.bookLongPressUrl = item.url;
                      this.bookLongPressCover = item.cover;
                      this.bookLongPressIsFavorite = true;
                      this.bookLongPressSourceName = item.sourceName;
                      this.setLongPressPosition(event.fingerList[0].globalX, event.fingerList[0].globalY);
                      this.bookLongPressVisible = true;
                    }))
                }, (item: BookshelfItem) => item.url + item.title)
              }.width('100%')
            } else {
              ForEach(this.bookshelf, (item: BookshelfItem) => {
                Row() {
                  Column() {
                    this.BookListCard(item.cover, item.title, (item.lastChapterTitle.length > 0 ? item.lastChapterTitle : item.sourceName) + ' · ' + item.lastReadAt, item.progressPercent + '%')
                    if (this.showDebugInfo) {
                      Text('来源: ' + item.sourceName + ' (' + item.sourceId + ')').fontSize(9).fontColor(this.colorfulValue('src-' + item.sourceId)).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').padding({ left: 14, top: 2 })
                    }
                  }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                  if (this.revealedDeleteUrl === item.url) {
                    Image($rawfile('ic_x.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_x')))
                      .padding(14).onClick(() => this.removeBookshelfItem(item.url))
                  }
                }.width('100%')
                  .onClick(() => { if (!this.isLongPressing) this.openBookshelfItem(item); })
                  .parallelGesture(LongPressGesture({ repeat: false, duration: 500 }).onAction((event: GestureEvent) => {
                    this.isLongPressing = true;
                    this.bookLongPressTitle = item.title;
                    this.bookLongPressUrl = item.url;
                    this.bookLongPressCover = item.cover;
                    this.bookLongPressIsFavorite = true;
                    this.bookLongPressSourceName = item.sourceName;
                    this.setLongPressPosition(event.fingerList[0].globalX, event.fingerList[0].globalY);
                    this.bookLongPressVisible = true;
                  }))
              }, (item: BookshelfItem) => item.url + item.title)
            }
          }
          .width('100%')
          .translate({ x: this.historyTab === 'favorites' ? this.historyPanOffset : this.historyViewportWidth + this.historyPanOffset })
        }
        .width('100%')
        .alignContent(Alignment.TopStart)
        .parallelGesture(PanGesture({ direction: PanDirection.Horizontal, distance: 8 })
          .onActionStart(() => {
            this.historyPanStartX = this.historyPanOffset;
          })
          .onActionUpdate((event: PanGestureEvent) => {
            this.historyPanOffset = this.historyPanStartX + event.offsetX;
          })
          .onActionEnd(() => {
            const threshold = this.historyViewportWidth / 3;
            if (this.historyPanOffset < -threshold) {
              animateTo({ duration: 250, curve: Curve.EaseInOut }, () => {
                this.historyPanOffset = 0;
              });
              this.historyTab = 'favorites';
            } else if (this.historyPanOffset > threshold) {
              animateTo({ duration: 250, curve: Curve.EaseInOut }, () => {
                this.historyPanOffset = 0;
              });
              this.historyTab = 'history';
            } else {
              animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
                this.historyPanOffset = 0;
              });
            }
          })
        )
        Blank().height(this.contentBottomInset())
      }.width('100%').constraintSize({ minHeight: '100%' }).padding({ left: 14, right: 14 })
    }.layoutWeight(1).edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true }).backgroundColor(this.appBg())
    .scrollBar(BarState.Auto)
    .scrollBarColor(this.scrollBarColor()).scrollBarWidth(6)
    .onAreaChange((_oldValue, newValue) => {
      const width = Number(newValue.width);
      if (width > 0) this.historyViewportWidth = width;
    })
  }

  @Builder
  private CodeEditorFullscreen() {
    Stack() {
      this.EditorContent()

      Column() {
        this.EditorTopBar()
        if (this.editorSearchVisible) this.EditorSearchBar()
        if (this.editorShowIndent && !this.editorReadOnly) this.EditorIndentBar()
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .padding({ top: this.avoidStatusBarHeight })
      .hitTestBehavior(HitTestMode.Transparent)

      if (this.editorToolBarVisible) {
        Column() {
          Blank()
          this.EditorStatusBar()
          this.EditorToolBar()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.End)
        .padding({ bottom: Math.max(this.bottomSafeInset - 10, 0) })
        .hitTestBehavior(HitTestMode.Transparent)
      }

      if (this.editorMenuVisible) this.EditorMenu()
      if (this.editorSeekVisible) this.EditorSeekDialog()
      if (this.editorLinksVisible) this.EditorLinksPanel()
      if (this.editorStatsVisible) this.EditorStatsPanel()
      if (this.editorColorPickerVisible) this.EditorColorPickerPanel()
      if (this.editorPreviewVisible) this.EditorPreviewPanel()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.editorTheme().background)
  }

  @Builder
  private EditorTopBar() {
    Row() {
      Image($rawfile('ic_back.svg')).width(20).height(20)
        .colorFilter(createStrokeIconColorFilter(this.iconColor('ic_back')))
        .onClick(() => {
          this.editorFullscreen = false;
          this.settingsDialog = '';
          this.applyReaderFullscreen(false);
        })
      Text(this.editorTitle)
        .fontSize(14).fontColor(this.editorTheme().text)
        .margin({ left: 8 }).layoutWeight(1).maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      if (this.editorReadOnly) {
        Text('READ').fontSize(10).fontColor(this.editorTheme().nullColor)
          .margin({ right: 4 })
      }
      Image($rawfile('ic_more_vert.svg')).width(20).height(20)
        .colorFilter(createStrokeIconColorFilter(this.iconColor('ic_more_vert')))
        .onClick(() => { this.editorMenuVisible = !this.editorMenuVisible; })
    }
    .width('100%').height(40).padding({ left: 8, right: 8 })
    .backgroundColor('#1A000000')
  }

  @Builder
  private EditorSearchBar() {
    Row() {
      TextInput({ placeholder: '搜索...', text: this.editorSearchQuery })
        .height(32).fontSize(12).layoutWeight(1)
        .backgroundColor('#33000000').fontColor(this.editorTheme().text)
        .borderRadius(6).padding({ left: 6, right: 6 })
        .onChange((value: string) => { this.editorSearchQuery = value; this.editorUpdateSearch(); })
      Text('正则').fontSize(10)
        .fontColor(this.editorUseRegex ? this.editorTheme().keyword : this.editorTheme().nullColor)
        .margin({ left: 4 }).onClick(() => { this.editorUseRegex = !this.editorUseRegex; this.editorUpdateSearch(); })
      Text('大小写').fontSize(10)
        .fontColor(this.editorCaseSensitive ? this.editorTheme().keyword : this.editorTheme().nullColor)
        .margin({ left: 4 }).onClick(() => { this.editorCaseSensitive = !this.editorCaseSensitive; this.editorUpdateSearch(); })
      if (this.editorSearchMatches.length > 0) {
        Text(`${this.editorCurrentMatch + 1}/${this.editorSearchMatches.length}`)
          .fontSize(10).fontColor(this.editorTheme().text).margin({ left: 4 })
      }
      Text('<').fontSize(14).fontColor(this.editorTheme().text).margin({ left: 4 })
        .onClick(() => {
          if (this.editorSearchMatches.length > 0) {
            this.editorCurrentMatch = (this.editorCurrentMatch - 1 + this.editorSearchMatches.length) % this.editorSearchMatches.length;
            this.editorJumpToMatch(this.editorCurrentMatch);
          }
        })
      Text('>').fontSize(14).fontColor(this.editorTheme().text).margin({ left: 4 })
        .onClick(() => {
          if (this.editorSearchMatches.length > 0) {
            this.editorCurrentMatch = (this.editorCurrentMatch + 1) % this.editorSearchMatches.length;
            this.editorJumpToMatch(this.editorCurrentMatch);
          }
        })
      Image($rawfile('ic_close.svg')).width(16).height(16)
        .colorFilter(createStrokeIconColorFilter(this.iconColor('ic_close')))
        .margin({ left: 4 })
        .onClick(() => {
          this.editorSearchVisible = false;
          this.editorSearchQuery = '';
          this.editorSearchMatches = [];
        })
    }
    .width('100%').height(36).padding({ left: 8, right: 8 })
    .backgroundColor('#1A000000')
  }

  @Builder
  private EditorIndentBar() {
    Row() {
      Text('缩进:').fontSize(11).fontColor(this.editorTheme().text)
      Text(this.editorUseTab ? 'Tab' : '空格').fontSize(11).fontColor(this.editorTheme().keyword)
        .onClick(() => { this.editorUseTab = !this.editorUseTab; })
      Text('大小:').fontSize(11).fontColor(this.editorTheme().text).margin({ left: 8 })
      ForEach([2, 4, 8], (size: number) => {
        Text(size.toString()).fontSize(11)
          .fontColor(this.editorIndentSize === size ? this.editorTheme().keyword : this.editorTheme().text)
          .margin({ left: 4 })
          .onClick(() => { this.editorIndentSize = size; })
      }, (size: number) => size.toString())
      Blank()
      Image($rawfile('ic_close.svg')).width(16).height(16)
        .colorFilter(createStrokeIconColorFilter(this.iconColor('ic_close')))
        .onClick(() => { this.editorShowIndent = false; })
    }
    .width('100%').height(32).padding({ left: 8, right: 8 })
    .backgroundColor('#1A000000')
  }

  @Builder
  private EditorContent() {
    if (this.editorReadOnly) {
      Stack() {
        List() {
          LazyForEach(this.editorLineDataSource, (line: string, index: number) => {
            ListItem() {
              Row() {
                Text((index + 1).toString())
                  .fontSize(13).fontFamily('monospace').lineHeight(20)
                  .fontColor(index === this.editorCursorLine ? this.editorThemeCache.text : this.editorThemeCache.lineNumber)
                  .width(this.editorLineNumberWidth)
                  .textAlign(TextAlign.End)
                  .padding({ right: 4 })
                  .onClick(() => {
                    this.editorCursorLine = index;
                    this.editorSelectedLine = index;
                    if (this.editorEditable) this.editorEditAtLine(index);
                  })
                Text() {
                  ForEach(highlightLine(line, this.editorThemeCache, this.editorLanguage), (seg: HighlightSegment) => {
                    Span(seg.text)
                      .fontColor(seg.color)
                      .fontSize(13)
                      .fontFamily('monospace')
                  }, (seg: HighlightSegment, idx: number) => `${index}_${idx}`)
                }
                .layoutWeight(1)
                .lineHeight(20)
                .copyOption(CopyOptions.LocalDevice)
                .maxLines(this.editorWordWrap ? Infinity : 1)
                .textOverflow({ overflow: this.editorWordWrap ? TextOverflow.None : TextOverflow.Ellipsis })
                .padding({ left: 6 })
              }
              .width('100%')
              .padding({ left: 0, right: 8 })
              .backgroundColor(index === this.editorCursorLine ? this.editorThemeCache.currentLine : Color.Transparent)
              .onClick(() => {
                this.editorCursorLine = index;
                this.editorSelectedLine = index;
              })
            }
          }, (line: string, index: number) => 'line_' + index)
        }
        .width('100%').height('100%')
        .scrollBar(BarState.Auto)
        .scrollBarColor(this.scrollBarColor()).scrollBarWidth(6)
        .backgroundColor(this.editorThemeCache.background)
        .contentStartOffset(this.avoidStatusBarHeight + 40)
        .contentEndOffset(this.editorToolBarVisible ? 60 : 0)

        Column() {}
          .width(1)
          .height('100%')
          .backgroundColor(this.editorThemeCache.nullColor)
          .position({ x: this.editorLineNumberWidth + 4, y: 0 })
      }
      .width('100%').height('100%')
      .alignContent(Alignment.Start)
    } else {
      Row() {
        Column() {
          ForEach(this.editorLinesCache, (line: string, index: number) => {
            Text((index + 1).toString())
              .fontSize(13).fontFamily('monospace').lineHeight(20)
              .fontColor(index === this.editorCursorLine ? this.editorThemeCache.text : this.editorThemeCache.lineNumber)
              .width(this.editorLineNumberWidth)
              .textAlign(TextAlign.End)
              .height(20)
              .onClick(() => {
                this.editorCursorLine = index;
                this.editorSelectedLine = index;
              })
          }, (line: string, index: number) => 'ln_' + index)
        }
        .width(this.editorLineNumberWidth + 8)
        .height('100%')
        .padding({ top: this.avoidStatusBarHeight + 40, bottom: this.editorToolBarVisible ? 60 : 0 })
        .backgroundColor(this.editorThemeCache.background)
        .translate({ y: this.editorScrollY })

        Column() {}
          .width(1)
          .height('100%')
          .backgroundColor(this.editorThemeCache.nullColor)

        TextArea({ text: this.customRuleText })
          .fontSize(13).fontFamily('monospace')
          .lineHeight(20)
          .fontColor(this.editorThemeCache.text)
          .backgroundColor(this.editorThemeCache.background)
          .caretStyle({ color: this.editorThemeCache.keyword })
          .layoutWeight(1).height('100%')
          .padding({ top: this.avoidStatusBarHeight + 40, bottom: this.editorToolBarVisible ? 60 : 0, left: 4 })
          .focusOnTouch(false)
          .enableKeyboardOnFocus(true)
          .defaultFocus(false)
          .id('customRuleTextArea')
          .onFocus(() => {
            if (this.editorToolBarVisible) {
              this.editorToolBarHiddenByKeyboard = true;
              this.editorToolBarVisible = false;
            }
          })
          .onBlur(() => {
            if (this.editorToolBarHiddenByKeyboard) {
              this.editorToolBarHiddenByKeyboard = false;
              this.editorToolBarVisible = true;
            }
          })
          .onChange((value: string) => {
            if (value !== this.customRuleText) {
              this.editorPushUndo();
              this.customRuleText = value;
              this.editorValidate();
              this.editorLinesCache = value.split('\n');
              this.editorLineDataSource.updateData(this.editorLinesCache);
              this.editorLineNumberWidth = Math.max(12, this.editorLinesCache.length.toString().length * 8);
            }
          })
          .onTextSelectionChange((selectionStart: number, selectionEnd: number) => {
            const pos = selectionStart;
            const before = this.customRuleText.substring(0, pos);
            const lines = before.split('\n');
            this.editorCursorLine = lines.length - 1;
            this.editorCol = lines[lines.length - 1].length;
            this.editorSelectedLine = this.editorCursorLine;
          })
          .onContentScroll((totalOffsetX: number, totalOffsetY: number) => {
            this.editorScrollY = -totalOffsetY;
          })
      }
      .width('100%').height('100%')
    }
  }

  @Builder
  private EditorToolBar() {
    Row() {
      Image($rawfile('ic_copy.svg')).width(18).height(18)
        .colorFilter(createStrokeIconColorFilter(this.iconColor('ic_copy')))
        .onClick(() => { this.editorCopyText(); })
      Image($rawfile('ic_paste.svg')).width(18).height(18)
        .colorFilter(createStrokeIconColorFilter(this.iconColor('ic_paste')))
        .margin({ left: 10 })
        .onClick(() => { this.editorPasteText(); })
      Image($rawfile('ic_undo.svg')).width(18).height(18)
        .colorFilter(createStrokeIconColorFilter(this.editorCanUndo ? this.iconColor('ic_undo') : this.editorTheme().nullColor))
        .margin({ left: 10 })
        .onClick(() => { this.editorUndo(); })
      Image($rawfile('ic_redo.svg')).width(18).height(18)
        .colorFilter(createStrokeIconColorFilter(this.editorCanRedo ? this.iconColor('ic_redo') : this.editorTheme().nullColor))
        .margin({ left: 10 })
        .onClick(() => { this.editorRedo(); })
      Image($rawfile('ic_search.svg')).width(18).height(18)
        .colorFilter(createStrokeIconColorFilter(this.iconColor('ic_search')))
        .margin({ left: 10 })
        .onClick(() => { this.editorSearchVisible = !this.editorSearchVisible; })
      Image($rawfile('ic_arrow_left.svg')).width(18).height(18)
        .colorFilter(createStrokeIconColorFilter(this.editorSearchMatches.length > 0 ? this.iconColor('ic_arrow_left') : this.editorTheme().nullColor))
        .margin({ left: 10 })
        .onClick(() => {
          if (this.editorSearchMatches.length > 0) {
            this.editorCurrentMatch = (this.editorCurrentMatch - 1 + this.editorSearchMatches.length) % this.editorSearchMatches.length;
            this.editorJumpToMatch(this.editorCurrentMatch);
          }
        })
      Image($rawfile('ic_arrow_right.svg')).width(18).height(18)
        .colorFilter(createStrokeIconColorFilter(this.editorSearchMatches.length > 0 ? this.iconColor('ic_arrow_right') : this.editorTheme().nullColor))
        .margin({ left: 10 })
        .onClick(() => {
          if (this.editorSearchMatches.length > 0) {
            this.editorCurrentMatch = (this.editorCurrentMatch + 1) % this.editorSearchMatches.length;
            this.editorJumpToMatch(this.editorCurrentMatch);
          }
        })
      Blank()
      if (!this.editorReadOnly) {
        Image($rawfile('ic_keyboard.svg')).width(18).height(18)
          .colorFilter(createStrokeIconColorFilter(this.iconColor('ic_keyboard')))
          .margin({ right: 10 })
          .onClick(() => {
            try {
              this.getUIContext().getFocusController().requestFocus('customRuleTextArea');
            } catch (e) {}
          })
      }
      Image($rawfile('ic_save.svg')).width(18).height(18)
        .colorFilter(createStrokeIconColorFilter(this.iconColor('ic_save')))
        .onClick(() => { this.editorSave(); })
    }
    .width('100%').height(32).padding({ left: 8, right: 8 })
    .backgroundColor('#0A000000')
  }

  @Builder
  private EditorStatusBar() {
    Row() {
      Text(`Ln ${this.editorCursorLine + 1}`)
        .fontSize(10).fontColor(this.editorTheme().nullColor)
      Text(`Col ${this.editorCol + 1}`)
        .fontSize(10).fontColor(this.editorTheme().nullColor).margin({ left: 8 })
      if (this.editorBookmarks.length > 0) {
        Text(`BM ${this.editorBookmarks.length}`)
          .fontSize(10).fontColor(this.editorTheme().keyword).margin({ left: 8 })
      }
      Blank()
      Text(this.editorLanguage === 'json' ? 'JSON' : this.editorLanguage === 'xml' ? 'XML' : 'Text').fontSize(10).fontColor('#A6E3A1')
      Text(`${this.editorIndentSize} ${this.editorUseTab ? 'Tab' : '空格'}`)
        .fontSize(10).fontColor(this.editorTheme().nullColor).margin({ left: 8 })
    }
    .width('100%').height(24).padding({ left: 8, right: 8 })
    .backgroundColor('#0A000000')
  }

  @Builder
  private EditorMenu() {
    Column() {
      Column({ space: 0 }) {
        if (this.editorReadOnly) {
          this.EditorMenuItem('编辑', 'ic_code', true, () => {
            if (this.editorMode === 'blocked') {
              this.customRuleText = JSON.stringify(this.blockedUrls, null, 2);
            } else {
              this.customRuleText = JSON.stringify(this.advancedRules, null, 2);
            }
            this.openEditorFullscreen(this.editorTitle, false);
            this.editorMenuVisible = false;
          })
        }
        this.EditorMenuItem('搜索', 'ic_search', !this.editorSearchVisible, () => {
          this.editorSearchVisible = true;
          this.editorMenuVisible = false;
        })
        this.EditorMenuItem(this.editorLanguage === 'json' ? '格式化 JSON' : '格式化', 'ic_align_left', !this.editorReadOnly && this.editorLanguage === 'json', () => {
          this.editorFormat();
          this.editorMenuVisible = false;
        })
        this.EditorMenuItem('缩进设置', 'ic_tune', !this.editorReadOnly, () => {
          this.editorShowIndent = true;
          this.editorMenuVisible = false;
        })
        this.EditorMenuItem('跳转到行', 'ic_arrow_down_circle', true, () => {
          this.editorSeekVisible = true;
          this.editorMenuVisible = false;
        })
        this.EditorMenuItem('切换书签', 'ic_bookmark', true, () => {
          this.toggleBookmark();
          this.editorMenuVisible = false;
        })
        this.EditorMenuItem('下一个书签', 'ic_nav_arrow_down', this.editorBookmarks.length > 0, () => {
          this.nextBookmark();
          this.editorMenuVisible = false;
        })
        this.EditorMenuItem('链接（JSON键）', 'ic_link', true, () => {
          this.refreshEditorLinks();
          this.editorLinksVisible = true;
          this.editorMenuVisible = false;
        })
        this.EditorMenuItem('统计', 'ic_stats_report', true, () => {
          this.refreshEditorStats();
          this.editorStatsVisible = true;
          this.editorMenuVisible = false;
        })
        this.EditorMenuItem('颜色选择器', 'ic_color_picker', !this.editorReadOnly, () => {
          this.editorColorPickerVisible = true;
          this.editorMenuVisible = false;
        })
        this.EditorMenuItem('预览', 'ic_eye', true, () => {
          this.editorPreviewVisible = true;
          this.editorMenuVisible = false;
        })
        this.EditorMenuItem(this.editorWordWrap ? '关闭自动换行' : '自动换行', 'ic_wrap_text', true, () => {
          this.editorWordWrap = !this.editorWordWrap;
          this.editorMenuVisible = false;
        })
        this.EditorMenuItem(this.editorToolBarVisible ? '隐藏工具栏' : '显示工具栏', 'ic_layout', true, () => {
          this.editorToolBarVisible = !this.editorToolBarVisible;
          this.editorMenuVisible = false;
        })
        if (!this.editorReadOnly) {
          this.EditorMenuItem('应用规则', 'ic_play', true, () => {
            this.applyCustomRule();
            this.editorMenuVisible = false;
          })
        }
      }
      .width(160)
      .backgroundColor(this.editorTheme().currentLine)
      .borderRadius(8)
      .border({ width: 1, color: this.editorTheme().nullColor })
    }
    .width('100%').height('100%')
    .backgroundColor('#66000000')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.End)
    .padding({ top: this.avoidStatusBarHeight + 40, right: 8 })
    .onClick(() => { this.editorMenuVisible = false; })
  }

  @Builder
  private EditorMenuItem(label: string, icon: string, enabled: boolean, action: () => void) {
    Row() {
      if (icon.length > 0) {
        Image($rawfile(icon + '.svg')).width(16).height(16)
          .colorFilter(createStrokeIconColorFilter(enabled ? this.iconColor(icon) : this.editorTheme().nullColor))
          .margin({ right: 8 })
      }
      Text(label)
        .fontSize(12).fontColor(enabled ? this.editorTheme().text : this.editorTheme().nullColor)
        .layoutWeight(1).textAlign(TextAlign.Start)
    }
    .width('100%').height(32).padding({ left: 12 })
    .onClick(() => { if (enabled) action(); })
  }

  @Builder
  private EditorSeekDialog() {
    Column() {
      Column({ space: 8 }) {
        Text('Go to Line').fontSize(14).fontColor(this.editorTheme().text)
        TextInput({ placeholder: 'Line number...', text: this.editorSeekInput })
          .height(32).fontSize(12)
          .backgroundColor(this.editorTheme().background).fontColor(this.editorTheme().text)
          .borderRadius(6).padding({ left: 6, right: 6 })
          .type(InputType.Number)
          .onChange((value: string) => { this.editorSeekInput = value; })
        Row() {
          Button('Go').height(28).fontSize(12).fontColor('#FFFFFF')
            .backgroundColor(this.editorTheme().keyword).borderRadius(6)
            .onClick(() => {
              const ln = parseInt(this.editorSeekInput);
              if (ln > 0 && ln <= this.editorLinesCache.length) {
                this.editorCursorLine = ln - 1;
                this.editorSelectedLine = ln - 1;
        if (this.editorReadOnly && this.editorEditable) {
                  this.editorScroller.scrollTo({ xOffset: 0, yOffset: (ln - 1) * 20 });
                } else {
                  this.focusTimerId = setTimeout(() => {
                    try {
                      this.getUIContext().getFocusController().requestFocus('customRuleTextArea');
                    } catch (e) {}
                  }, 50);
                }
              }
              this.editorSeekVisible = false;
              this.editorSeekInput = '';
            })
          Button('Cancel').height(28).fontSize(12).fontColor(this.editorTheme().text)
            .backgroundColor(this.editorTheme().currentLine).borderRadius(6)
            .margin({ left: 8 })
            .onClick(() => { this.editorSeekVisible = false; this.editorSeekInput = ''; })
        }
      }
      .width('60%').padding(12)
      .backgroundColor(this.editorTheme().currentLine)
      .borderRadius(12)
      .border({ width: 1, color: this.editorTheme().nullColor })
    }
    .width('100%').height('100%')
    .backgroundColor('#66000000')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => { this.editorSeekVisible = false; this.editorSeekInput = ''; })
  }

  @Builder
  private EditorLinksPanel() {
    Column() {
      Column({ space: 0 }) {
        Row() {
          Text('JSON Keys').fontSize(14).fontColor(this.editorTheme().text).layoutWeight(1)
          Image($rawfile('ic_close.svg')).width(16).height(16)
            .colorFilter(createStrokeIconColorFilter(this.iconColor('ic_close')))
            .onClick(() => { this.editorLinksVisible = false; })
        }
        .width('100%').height(36).padding({ left: 12, right: 8 })
        List() {
          ForEach(this.editorLinksCache, (key: string, index: number) => {
            ListItem() {
              Text(key)
                .fontSize(12).fontColor(this.editorTheme().keyword)
                .width('100%').height(32).padding({ left: 12 })
                .onClick(() => {
                  const text = this.editorReadOnly ? this.ruleViewerText : this.customRuleText;
                  const lines = text.split('\n');
                  for (let i = 0; i < lines.length; i++) {
                    if (lines[i].indexOf('"' + key + '"') >= 0) {
                      this.editorCursorLine = i;
                      this.editorLinksVisible = false;
                      return;
                    }
                  }
                  this.editorLinksVisible = false;
                })
            }
          }, (key: string, index: number) => 'link_' + index)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .scrollBarColor(this.scrollBarColor()).scrollBarWidth(6)
      }
      .width('70%')
      .height('60%')
      .backgroundColor(this.editorTheme().currentLine)
      .borderRadius(12)
      .border({ width: 1, color: this.editorTheme().nullColor })
    }
    .width('100%').height('100%')
    .backgroundColor('#66000000')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => { this.editorLinksVisible = false; })
  }

  @Builder
  private EditorStatsPanel() {
    Column() {
      Column({ space: 8 }) {
        Row() {
          Text('Statistics').fontSize(14).fontColor(this.editorTheme().text).layoutWeight(1)
          Image($rawfile('ic_close.svg')).width(16).height(16)
            .colorFilter(createStrokeIconColorFilter(this.iconColor('ic_close')))
            .onClick(() => { this.editorStatsVisible = false; })
        }
        .width('100%')
        Row() {
          Text('Lines:').fontSize(12).fontColor(this.editorTheme().text).layoutWeight(1)
          Text(this.editorStatsLines.toString()).fontSize(12).fontColor(this.editorTheme().keyword)
        }.width('100%')
        Row() {
          Text('Words:').fontSize(12).fontColor(this.editorTheme().text).layoutWeight(1)
          Text(this.editorStatsWords.toString()).fontSize(12).fontColor(this.editorTheme().keyword)
        }.width('100%')
        Row() {
          Text('Characters:').fontSize(12).fontColor(this.editorTheme().text).layoutWeight(1)
          Text(this.editorStatsChars.toString()).fontSize(12).fontColor(this.editorTheme().keyword)
        }.width('100%')
        Row() {
          Text('Bookmarks:').fontSize(12).fontColor(this.editorTheme().text).layoutWeight(1)
          Text(this.editorBookmarks.length.toString()).fontSize(12).fontColor(this.editorTheme().keyword)
        }.width('100%')
      }
      .width('70%').padding(12)
      .backgroundColor(this.editorTheme().currentLine)
      .borderRadius(12)
      .border({ width: 1, color: this.editorTheme().nullColor })
    }
    .width('100%').height('100%')
    .backgroundColor('#66000000')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => { this.editorStatsVisible = false; })
  }

  @Builder
  private EditorColorPickerPanel() {
    Column() {
      Column({ space: 8 }) {
        Row() {
          Text('Color Picker').fontSize(14).fontColor(this.editorTheme().text).layoutWeight(1)
          Image($rawfile('ic_close.svg')).width(16).height(16)
            .colorFilter(createStrokeIconColorFilter(this.iconColor('ic_close')))
            .onClick(() => { this.editorColorPickerVisible = false; })
        }
        .width('100%')
        Grid() {
          ForEach(['#F38BA8', '#A6E3A1', '#FAB387', '#CBA6F7', '#89DCEB', '#EBA0AC',
            '#F9E2AF', '#94E2D5', '#74C7EC', '#89B4FA', '#DC8A78', '#CDD6F4',
            '#FFFFFF', '#000000', '#FF0000', '#00FF00', '#0000FF', '#FFFF00',
            '#FF00FF', '#00FFFF', '#808080', '#C0C0C0', '#800000', '#008000',
            '#000080', '#808000', '#800080', '#008080', '#400000', '#004000'], (color: string) => {
            GridItem() {
              Column() {
                Stack() {
                  Circle().width(28).height(28).fill(color)
                  if (this.editorTheme().background === color) {
                    Circle().width(28).height(28).fill(Color.Transparent).stroke('#FFFFFF').strokeWidth(2)
                  }
                }.width(28).height(28)
                Text(color).fontSize(8).fontColor(this.editorTheme().text).margin({ top: 2 })
              }
              .width('100%')
              .onClick(() => {
                this.customRuleText = this.customRuleText + color;
                this.editorColorPickerVisible = false;
                this.refreshEditorLines();
                this.editorValidate();
              })
            }
          }, (color: string) => color)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')
        .rowsGap(4)
        .columnsGap(4)
        .width('100%')
        .height(200)
      }
      .width('70%').padding(12)
      .backgroundColor(this.editorTheme().currentLine)
      .borderRadius(12)
      .border({ width: 1, color: this.editorTheme().nullColor })
    }
    .width('100%').height('100%')
    .backgroundColor('#66000000')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => { this.editorColorPickerVisible = false; })
  }

  @Builder
  private EditorPreviewPanel() {
    Column() {
      Column({ space: 8 }) {
        Row() {
          Text('Preview').fontSize(14).fontColor(this.editorTheme().text).layoutWeight(1)
          Image($rawfile('ic_close.svg')).width(16).height(16)
            .colorFilter(createStrokeIconColorFilter(this.iconColor('ic_close')))
            .onClick(() => { this.editorPreviewVisible = false; })
        }
        .width('100%').height(36).padding({ left: 12, right: 8 })
        Scroll() {
          Column() {
            ForEach(this.editorLinesCache.slice(0, 500), (line: string, index: number) => {
              Row() {
                Text((index + 1).toString())
                  .fontSize(10).fontColor(this.editorTheme().lineNumber)
                  .width(30).textAlign(TextAlign.End)
                Row() {
                  ForEach(highlightLine(line, this.editorThemeCache, this.editorLanguage), (seg: HighlightSegment) => {
                    Text(seg.text).fontSize(12).fontColor(seg.color).fontFamily('monospace')
                  }, (seg: HighlightSegment, si: number) => 'pv_' + index + '_' + si)
                }
                .layoutWeight(1)
              }
              .width('100%')
              .backgroundColor(index === this.editorCursorLine ? this.editorThemeCache.currentLine : Color.Transparent)
            }, (line: string, index: number) => 'pvl_' + index)
            if (this.editorLinesCache.length > 500) {
              Text(`... ${this.editorLinesCache.length - 500} more lines not shown`)
                .fontSize(10).fontColor(this.editorTheme().nullColor)
                .width('100%').textAlign(TextAlign.Center).padding(8)
            }
          }.width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .scrollBarColor(this.scrollBarColor()).scrollBarWidth(6)
      }
      .width('80%')
      .height('70%')
      .backgroundColor(this.editorTheme().currentLine)
      .borderRadius(12)
      .border({ width: 1, color: this.editorTheme().nullColor })
    }
    .width('100%').height('100%')
    .backgroundColor('#66000000')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => { this.editorPreviewVisible = false; })
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
              .onFocus(() => { this.searchHistoryVisible = true; })
              .onChange((value: string) => { this.queryText = value; })
              .onSubmit(() => { this.startSearch(); })
            if (this.queryText.length > 0) {
              Row() {
                Column() {
                  Image($rawfile('ic_x.svg')).width(14).height(14).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_x')))
                }.width(32).height(32).justifyContent(FlexAlign.Center).margin({ right: 6 })
                  .onClick(() => { this.clearSearchAndReset(); })
              }.width('100%').justifyContent(FlexAlign.End).hitTestBehavior(HitTestMode.Transparent)
            }
          }.layoutWeight(1)
          Column() { this.SearchActionButton(44) }
            .margin({ left: 8 })
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      } else if (this.activeTab === 'shelf') {
        Row() {
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
          .layoutWeight(1)
          .padding({ top: 8, bottom: 8 })
          .backgroundColor(Color.Transparent)
          Button() {
            Image($rawfile('ic_more_vert.svg')).width(22).height(22).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_more_vert')))
          }
          .width(36).height(36).backgroundColor(Color.Transparent).borderWidth(0)
          .onClick(() => { this.shelfMenuVisible = !this.shelfMenuVisible; })
        }
        .width('100%')
        .padding({ right: 8, top: 0, bottom: 0 })
      } else if (this.activeTab === 'history') {
        Row() {
          Row({ space: 16 }) {
            if (this.historyTab === 'history') {
              Button(this.t('history'))
                .fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.primaryText())
                .backgroundColor(Color.Transparent).borderWidth(0)
                .onClick(() => { this.historyTab = 'history'; })
            } else {
              Button(this.t('history'))
                .fontSize(20).fontWeight(FontWeight.Normal).fontColor(this.secondaryText())
                .backgroundColor(Color.Transparent).borderWidth(0)
                .onClick(() => { this.historyTab = 'history'; })
            }
            if (this.historyTab === 'favorites') {
              Button(this.t('favorites'))
                .fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.primaryText())
                .backgroundColor(Color.Transparent).borderWidth(0)
                .onClick(() => { this.historyTab = 'favorites'; })
            } else {
              Button(this.t('favorites'))
                .fontSize(20).fontWeight(FontWeight.Normal).fontColor(this.secondaryText())
                .backgroundColor(Color.Transparent).borderWidth(0)
                .onClick(() => { this.historyTab = 'favorites'; })
            }
          }.layoutWeight(1)
          Button() {
            Image($rawfile('ic_more_vert.svg')).width(22).height(22).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_more_vert')))
          }
          .width(36).height(36).backgroundColor(Color.Transparent).borderWidth(0)
          .onClick(() => { this.historyMenuVisible = !this.historyMenuVisible; })
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
          Stack() {
            Column() {
              if (this.mode === 'home') this.SearchHome()
              else {
                Stack() {
                  // Keep the result Scroll mounted while reading. Recreating it
                  // caused a visible jump followed by a delayed offset restore.
                  Column() { this.ResultsPage() }
                    .width('100%').height('100%')
                    .visibility(this.mode === 'results' ? Visibility.Visible : Visibility.Hidden)
                  if (this.mode === 'chapters') this.ChaptersPage()
                  else if (this.mode === 'reader') this.ReaderPage()
                }.width('100%').height('100%')
              }
            }
            .width('100%').height('100%')
            .visibility(this.activeTab === 'search' ? Visibility.Visible : Visibility.Hidden)
            .hitTestBehavior(this.activeTab === 'search' ? HitTestMode.Default : HitTestMode.None)

            if (this.activeTab === 'shelf') {
              this.ShelfPage()
            } else if (this.activeTab === 'history') {
              this.HistoryPage()
            } else if (this.activeTab === 'settings') {
              this.SettingsPage()
            }
          }
          .width('100%').height('100%')
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.appBg())

        if (this.mode !== 'reader' && this.mode !== 'chapters') {
          Column() {
            this.BottomTabs()
          }
          .width('100%')
          .padding({ left: 10, right: 10, bottom: Math.max(0, this.bottomSafeInset - 2) })
          .backgroundColor(Color.Transparent)
          .markAnchor({ x: 0, y: '100%' })
          .position({ x: 0, y: '100%' })
        }

        if (this.mode !== 'reader' && this.mode !== 'chapters') {
          Column() {
            this.HeaderOverlay()
          }
          .width('100%')
          .height(this.headerOverlayHeight())
          .justifyContent(FlexAlign.Start)
          .backgroundColor(Color.Transparent)
          .position({ x: 0, y: 0 })
        }

        if (this.statusMessageVisible) {
          Column() { this.StatusMessageOverlay() }
            .width('100%').height('100%')
            .justifyContent(FlexAlign.End)
            .padding({ bottom: this.bottomSafeInset + 61 })
            .hitTestBehavior(HitTestMode.Transparent)
        }

        if (this.activeTab === 'search' && this.mode === 'results' && this.searchHistoryVisible && this.recentSearches.length > 0) {
          Column() {}
            .width('100%')
            .height('100%')
            .position({ x: 0, y: this.headerOverlayHeight() })
            .onClick(() => { this.searchHistoryVisible = false; })
          Column() { this.RecentSearchPanel() }
            .width('100%').padding({ left: 14, right: 14 })
            .position({ x: 0, y: this.headerOverlayHeight() })
        }

        if (this.historyMenuVisible) {
          Column() {
            Column() {
              Row({ space: 8 }) {
                Image($rawfile('ic_layout.svg')).width(16).height(16).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_layout')))
                Text(this.t('list_view')).fontSize(14).fontColor(this.historyViewMode === 'list' ? this.colorfulAccent('view-list') : this.primaryText())
              }.width('100%').height(44).padding({ left: 14, right: 14 }).onClick(() => { this.historyViewMode = 'list'; this.historyMenuVisible = false; })
              Row({ space: 8 }) {
                Image($rawfile('ic_shelf.svg')).width(16).height(16).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_shelf')))
                Text(this.t('grid_view')).fontSize(14).fontColor(this.historyViewMode === 'grid' ? this.colorfulAccent('view-grid') : this.primaryText())
              }.width('100%').height(44).padding({ left: 14, right: 14 }).onClick(() => { this.historyViewMode = 'grid'; this.historyMenuVisible = false; })
              Row({ space: 8 }) {
                Image($rawfile('ic_x.svg')).width(16).height(16).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_x')))
                Text(this.isEn() ? 'Clear all' : '全部清除').fontSize(14).fontColor(this.iconColor('ic_x'))
              }.width('100%').height(44).padding({ left: 14, right: 14 }).onClick(() => { this.clearVisibleHistory(); this.historyMenuVisible = false; })
            }
            .width(140)
            .backgroundColor(this.cardBg())
            .borderRadius(12)
            .shadow({ radius: 12, color: '#30000000', offsetY: 4 })
            .border({ width: 1, color: this.borderSubtle() })
            .position({ x: this.headerOverlayWidth() - 154, y: this.avoidStatusBarHeight + 44 })
          }
          .width('100%').height('100%')
          .backgroundColor(this.dialogOverlay())
          .onClick(() => { this.historyMenuVisible = false; })
        }

        if (this.shelfMenuVisible) {
          Column() {
            Column() {
              Row({ space: 8 }) {
                Image($rawfile('ic_layout.svg')).width(16).height(16).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_layout')))
                Text(this.t('list_view')).fontSize(14).fontColor(this.shelfDisplayMode === 'list' ? this.colorfulAccent('shelf-list') : this.primaryText())
              }.width('100%').height(44).padding({ left: 14, right: 14 }).onClick(() => { this.shelfDisplayMode = 'list'; this.shelfMenuVisible = false; this.persistData(); })
              Row({ space: 8 }) {
                Image($rawfile('ic_shelf.svg')).width(16).height(16).colorFilter(createStrokeIconColorFilter(this.iconColor('ic_shelf')))
                Text(this.t('grid_view')).fontSize(14).fontColor(this.shelfDisplayMode === 'grid' ? this.colorfulAccent('shelf-grid') : this.primaryText())
              }.width('100%').height(44).padding({ left: 14, right: 14 }).onClick(() => { this.shelfDisplayMode = 'grid'; this.shelfMenuVisible = false; this.persistData(); })
            }
            .width(140)
            .backgroundColor(this.cardBg())
            .borderRadius(12)
            .shadow({ radius: 12, color: '#30000000', offsetY: 4 })
            .border({ width: 1, color: this.borderSubtle() })
            .position({ x: this.headerOverlayWidth() - 154, y: this.avoidStatusBarHeight + 44 })
          }
          .width('100%').height('100%')
          .backgroundColor(this.dialogOverlay())
          .onClick(() => { this.shelfMenuVisible = false; })
        }

        if (this.bookLongPressVisible) {
          Column() {
            this.BookLongPressMenu()
          }
          .width('100%').height('100%')
          .backgroundColor(this.dialogOverlay())
          .onClick(() => { this.closeBookLongPressMenu(); })
        }

        if (this.editorFullscreen) {
          Column() { this.CodeEditorFullscreen() }
            .width('100%')
            .height('100%')
        }
      }, (item: string, index: number) => `${item}_${index}`)
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .id(`root_${this.uiVersion}`)
  }
}
