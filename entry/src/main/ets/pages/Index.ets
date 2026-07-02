import { ComicSourceRule, SearchResultItem, ChapterItem, ReaderImageItem, ReadingHistoryItem, BookshelfItem, SearchEngineConfig } from '../model/ComicModels';
import { DEFAULT_SOURCES, RULE_TEMPLATE, ruleForPublicUrl } from '../common/SourceRules';
import { HttpClient } from '../common/HttpClient';
import { parseSearchResults, parseChapters, parseImages, parseNextPageUrl } from '../common/HtmlParser';
import { looksLikeUrl, normalizeUserUrl } from '../common/UrlUtil';
import { DEFAULT_SEARCH_ENGINES, buildEngineQuery, buildSearchEngineUrl, parseSearchEngineResults, isEngineConfigured, engineHeaders, searchEngineUserAgent } from '../common/SearchEngines';
import { RemoteRuleService, DEFAULT_REMOTE_RULE_URL } from '../common/RemoteRuleService';
import { APP_VERSION, APP_BUILD_TIME } from '../common/BuildInfo';
import drawing from '@ohos.graphics.drawing';
import common from '@ohos.app.ability.common';
import window from '@ohos.window';

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
  @State private statusText: string = '';
  @State private rules: ComicSourceRule[] = DEFAULT_SOURCES;
  @State private searchEngines: SearchEngineConfig[] = DEFAULT_SEARCH_ENGINES;
  @State private selectedEngineIndex: number = 0;
  @State private results: SearchResultItem[] = [];
  @State private chapters: ChapterItem[] = [];
  @State private images: ReaderImageItem[] = [];
  @State private history: ReadingHistoryItem[] = [];
  @State private bookshelf: BookshelfItem[] = [];
  @State private currentTitle: string = '';
  @State private currentUrl: string = '';
  @State private currentChapterTitle: string = '';
  @State private currentCover: string = '';
  @State private currentSourceId: string = '';
  @State private currentSourceName: string = '';
  @State private isLoading: boolean = false;

  @State private searchMode: string = 'mixed';
  @State private searchAllEngines: boolean = false;
  @State private languageMode: string = 'chinese';
  @State private extraSearchTerms: string = '漫画 在线 阅读 章节 manhua manga read chapter';
  @State private siteHint: string = '';
  @State private braveApiKey: string = '';
  @State private googleApiKey: string = '';
  @State private googleCx: string = '';
  @State private enableSearchEngines: boolean = true;
  @State private enableHtmlRules: boolean = true;
  @State private autoCoverEnabled: boolean = false;
  @State private maxSearchResults: number = 40;
  @State private maxReaderPages: number = 6;
  @State private showImageIndex: boolean = true;
  @State private readerDarkMode: boolean = true;
  @State private fullscreenReader: boolean = true;
  @State private floatingReaderControls: boolean = true;
  @State private appTheme: string = 'light';
  @State private appLanguage: string = 'zh';
  @State private remoteRuleUrl: string = DEFAULT_REMOTE_RULE_URL;
  @State private remoteRuleStatus: string = '';
  @State private remoteRuleCount: number = 0;
  @State private customRuleText: string = RULE_TEMPLATE;
  @State private settingsDialog: string = '';
  @State private themeDialogVisible: boolean = false;
  @State private languageDialogVisible: boolean = false;
  @State private avoidStatusBarHeight: number = 0;

  @State private systemColorMode: string = 'light';

  aboutToAppear(): void {
    this.queryText = '';
    this.statusText = this.t('initial_status');
    this.remoteRuleStatus = this.t('remote_not_updated');
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const config = context.config;
      if (config && config.colorMode !== undefined && config.colorMode === -1) {
        this.systemColorMode = 'dark';
      }
      const mainWindow = context.windowStage.getMainWindowSync();
      const avoidArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      this.avoidStatusBarHeight = px2vp(avoidArea.topRect.height);
    } catch (e) {
    }
  }

  onBackPress(): boolean {
    if (this.settingsDialog.length > 0) {
      this.settingsDialog = '';
      return true;
    }
    if (this.mode === 'reader') {
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

  private isEn(): boolean {
    return this.appLanguage === 'en';
  }

  private t(key: string): string {
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
      if (key === 'no_chapters') return 'No chapters. This may be a single chapter, or the rule doesn\'t match.';
      if (key === 'basic_settings') return 'Basic';
      if (key === 'app_settings') return 'App Settings';
      if (key === 'about') return 'About';
      if (key === 'theme') return 'Theme';
      if (key === 'language') return 'Language';
      if (key === 'light') return 'Light';
      if (key === 'dark') return 'Dark';
      if (key === 'follow_system') return 'System';
      if (key === 'reader_fullscreen') return 'Fullscreen Reader';
      if (key === 'floating_controls') return 'Floating Controls';
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
    if (key === 'no_chapters') return '没有章节。可能该结果本身就是单话漫画，或目录规则不匹配。';
    if (key === 'basic_settings') return '基础设置';
    if (key === 'app_settings') return 'APP设置';
    if (key === 'about') return '关于';
    if (key === 'theme') return '主题';
    if (key === 'language') return '语言';
    if (key === 'light') return '明亮';
    if (key === 'dark') return '暗黑';
    if (key === 'follow_system') return '跟随系统';
    if (key === 'reader_fullscreen') return '阅读页全屏';
    if (key === 'floating_controls') return '悬浮控制';
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
  private secondaryText(): string { return this.isDark() ? '#7A828C' : '#7A828C'; }
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
      if (this.searchMode !== 'api_only') await this.searchSelectedEngines(keyword);
      if (this.searchMode !== 'engine_only') await this.searchHtmlRuleSources(keyword);
      if (this.autoCoverEnabled) await this.enrichResultCovers(8);
    } finally {
      this.isLoading = false;
      this.statusText = this.results.length > 0 ? this.t('search_complete') + this.results.length + this.t('results_suffix') : this.t('no_comic_results');
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
    for (let i = 0; i < engines.length; i++) {
      const engine = engines[i];
      if (!isEngineConfigured(engine, this.braveApiKey, this.googleApiKey, this.googleCx)) continue;
      try {
        const url = buildSearchEngineUrl(engine, query, this.braveApiKey, this.googleApiKey, this.googleCx);
        const body = await HttpClient.getTextWithHeaders(url, searchEngineUserAgent(), '', engineHeaders(engine, this.braveApiKey));
        const parsed = parseSearchEngineResults(body, engine, keyword, url);
        this.appendResults(parsed);
        this.statusText = engine.name + this.t('engine_returned') + parsed.length + this.t('engine_current') + this.results.length + this.t('items_unit');
      } catch (err) {
        this.statusText = engine.name + this.t('engine_failed');
      }
    }
  }

  private async searchHtmlRuleSources(keyword: string): Promise<void> {
    if (!this.enableHtmlRules) return;
    let success = 0;
    for (let i = 0; i < this.rules.length; i++) {
      const rule = this.rules[i];
      if (rule.searchUrl.trim().length === 0) continue;
      try {
        const searchUrl = rule.searchUrl.replace('{keyword}', encodeURIComponent(keyword));
        const html = await HttpClient.getText(searchUrl, rule.userAgent, rule.referer.length > 0 ? rule.referer : rule.homepage);
        const parsed = parseSearchResults(html, rule, searchUrl, keyword);
        if (parsed.length > 0) {
          success++;
          this.appendResults(parsed);
          this.statusText = this.t('rule_progress') + success + this.t('rule_succeeded') + this.results.length + this.t('rule_current');
        }
      } catch (err) {
      }
    }
  }

  private async enrichResultCovers(maxCount: number): Promise<void> {
    const count = Math.min(maxCount, this.results.length, 8);
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
    this.currentTitle = this.cleanTitle(title);
    this.currentSourceId = rule.id;
    this.currentSourceName = rule.name;
    this.chapters = [];
    this.images = [];
    this.mode = 'chapters';
    this.statusText = this.t('reading_chapters');
    try {
      const html = await HttpClient.getText(url, rule.userAgent, rule.referer.length > 0 ? rule.referer : url);
      const parsedChapters = parseChapters(html, rule, url);
      this.chapters = parsedChapters;
      if (parsedChapters.length === 0) {
        await this.loadChapter({ title: this.currentTitle, url: url, index: 1, sourceId: rule.id, sourceName: rule.name }, rule);
      } else {
        this.statusText = this.t('found_chapters') + parsedChapters.length + this.t('chapters_unit') + '.';
      }
    } catch (err) {
      this.statusText = this.t('chapter_failed');
    }
  }

  private mergeReaderImages(base: ReaderImageItem[], incoming: ReaderImageItem[]): ReaderImageItem[] {
    const next: ReaderImageItem[] = [];
    for (let i = 0; i < base.length && next.length < 120; i++) next.push({ url: base[i].url, index: next.length + 1, status: base[i].status });
    for (let j = 0; j < incoming.length && next.length < 120; j++) {
      const image = incoming[j];
      if (!next.some((oldItem: ReaderImageItem) => oldItem.url === image.url)) next.push({ url: image.url, index: next.length + 1, status: 'waiting' });
    }
    return next;
  }

  private async fetchReaderImagesWithPagination(firstUrl: string, rule: ComicSourceRule): Promise<ReaderImageItem[]> {
    let pageUrl = firstUrl;
    let allImages: ReaderImageItem[] = [];
    const visited: string[] = [];
    const maxPages = Math.min(rule.maxReaderPages !== undefined && rule.maxReaderPages > 0 ? rule.maxReaderPages : this.maxReaderPages, this.maxReaderPages, 8);
    for (let page = 0; page < maxPages; page++) {
      if (pageUrl.length === 0 || visited.indexOf(pageUrl) >= 0) break;
      visited.push(pageUrl);
      const html = await HttpClient.getText(pageUrl, rule.userAgent, rule.referer.length > 0 ? rule.referer : pageUrl);
      const pageImages = parseImages(html, rule, pageUrl);
      allImages = this.mergeReaderImages(allImages, pageImages);
      const nextUrl = parseNextPageUrl(html, rule, pageUrl);
      if (nextUrl.length === 0 || nextUrl === pageUrl) break;
      pageUrl = nextUrl;
      this.statusText = this.t('tracking_pages') + (page + 2) + this.t('pages_unit') + this.t('extracted_images') + allImages.length + this.t('images_unit_full') + '.';
    }
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
    this.statusText = this.t('generating_scroll');
    try {
      const parsedImages = await this.fetchReaderImagesWithPagination(chapter.url, rule);
      this.images = parsedImages;
      this.statusText = parsedImages.length > 0 ? this.t('scroll_complete') + parsedImages.length + this.t('images_unit_full') + '.' : this.t('no_images');
      this.addHistory(chapter, parsedImages.length);
    } catch (err) {
      this.statusText = this.t('scroll_failed');
    }
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
    if (changed) this.images = next;
  }

  private openSearchResult(item: SearchResultItem): void {
    const rule = this.ruleForItemUrl(item.url, item.sourceId);
    if (item.isChapter) this.loadChapter({ title: item.title, url: item.url, index: 1, sourceId: item.sourceId, sourceName: item.sourceName }, rule);
    else this.loadDetail(item.url, item.title, rule);
  }

  private addHistory(chapter: ChapterItem, imageCount: number): void {
    const item: ReadingHistoryItem = {
      title: this.currentTitle.length > 0 ? this.currentTitle : chapter.title,
      url: chapter.url,
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
  }

  private addCurrentToShelf(): void {
    if (this.currentUrl.length === 0) return;
    const item: BookshelfItem = {
      title: this.currentTitle.length > 0 ? this.currentTitle : this.t('unnamed_comic'),
      url: this.currentUrl,
      sourceId: this.currentSourceId,
      sourceName: this.currentSourceName,
      cover: this.currentCover,
      lastChapterTitle: this.currentChapterTitle,
      lastChapterUrl: this.currentUrl,
      addedAt: this.nowText(),
      lastReadAt: this.nowText(),
      imageCount: this.images.length,
      progressPercent: this.images.length > 0 ? 100 : 0
    };
    const next = [item];
    for (let i = 0; i < this.bookshelf.length; i++) {
      if (this.bookshelf[i].url !== item.url) next.push(this.bookshelf[i]);
    }
    this.bookshelf = next;
    this.statusText = this.t('added_shelf');
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

  private toggleTheme(): void {
    this.appTheme = this.appTheme === 'light' ? 'dark' : 'light';
    this.statusText = this.t('theme_switched');
  }

  private async updateRemoteRules(): Promise<void> {
    this.remoteRuleStatus = this.t('remote_updating');
    try {
      const loaded = await RemoteRuleService.fetchRemoteRules(this.remoteRuleUrl);
      if (loaded.length > 0) {
        this.rules = loaded.concat(DEFAULT_SOURCES);
        this.remoteRuleCount = loaded.length;
        this.remoteRuleStatus = this.t('remote_updated') + loaded.length + this.t('rules_unit');
      } else {
        this.remoteRuleStatus = this.t('remote_empty');
      }
    } catch (err) {
      this.remoteRuleStatus = this.t('remote_failed');
    }
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
  private SearchActionButton(heightValue: number) {
    Button(this.isLoading ? '' : this.t('search'))
      .height(heightValue)
      .fontSize(15)
      .fontColor(this.isLoading ? Color.Transparent : '#FFFFFF')
      .backgroundColor(this.isLoading ? Color.Transparent : this.accent())
      .borderRadius(heightValue / 2)
      .padding({ left: 20, right: 20 })
      .border({ width: 2, color: this.accent() })
      .enabled(!this.isLoading)
      .onClick(() => { this.startSearch(); })
  }

  private headerGradientColors(): Array<[string, number]> {
    return this.isDark()
      ? [['#BB111318', 0.0], ['#AA111318', 0.05], ['#99111318', 0.12], ['#88111318', 0.22], ['#77111318', 0.35], ['#66111318', 0.52], ['#55111318', 0.72], ['#33111318', 0.88], ['#00111318', 1.0]] as Array<[string, number]>
      : [['#C0F6F8FA', 0.0], ['#B0F6F8FA', 0.05], ['#A0F6F8FA', 0.12], ['#90F6F8FA', 0.22], ['#80F6F8FA', 0.35], ['#70F6F8FA', 0.52], ['#50F6F8FA', 0.72], ['#30F6F8FA', 0.88], ['#00F6F8FA', 1.0]] as Array<[string, number]>;
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
              .backgroundColor(this.searchInputBg())
              .borderRadius(22)
              .padding({ left: 14, right: this.queryText.length > 0 ? 40 : 14 })
              .onChange((value: string) => { this.queryText = value; })
              .onSubmit(() => { this.startSearch(); })
            if (this.queryText.length > 0) {
              Column() {
                Image($rawfile('ic_x.svg')).width(14).height(14).colorFilter(createStrokeIconColorFilter(this.secondaryText()))
              }.width(32).height(32).justifyContent(FlexAlign.Center).margin({ right: 6 })
                .onClick(() => { this.queryText = ''; })
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
    Stack() {
      Column() {
        Blank().layoutWeight(1)
        Image($r('app.media.search_home_illustration_light'))
          .width(220)
          .height(180)
          .objectFit(ImageFit.Contain)
          .margin({ bottom: 24 })
        Row() {
          Stack() {
            TextInput({ placeholder: this.t('search_placeholder'), text: this.queryText })
              .height(52)
              .fontSize(15)
              .backgroundColor(this.cardBg())
              .borderRadius(26)
              .padding({ left: 18, right: this.queryText.length > 0 ? 44 : 18 })
              .onChange((value: string) => { this.queryText = value; })
              .onSubmit(() => { this.startSearch(); })
            if (this.queryText.length > 0) {
              Column() {
                Image($rawfile('ic_x.svg')).width(16).height(16).colorFilter(createStrokeIconColorFilter(this.secondaryText()))
              }.width(36).height(36).justifyContent(FlexAlign.Center).margin({ right: 8 })
                .onClick(() => { this.queryText = ''; })
            }
          }.layoutWeight(1)
          Column() { this.SearchActionButton(52) }
            .margin({ left: 10 })
        }
        .width('100%')
        .padding({ left: 22, right: 22 })
        Blank().layoutWeight(1)
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(this.appBg())

      Column() {
        Column() {
          Text(this.t('app_title'))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.primaryText())
            .width('100%')
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      }
      .width('100%')
      .padding({ top: this.avoidStatusBarHeight })
      .linearGradient({ angle: 180, colors: this.headerGradientColors() })
    }
    .width('100%')
    .layoutWeight(1)
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
          Text(this.t('comic_tag')).fontSize(11).fontColor('#FFFFFF').padding({ left: 8, right: 8, top: 3, bottom: 3 }).backgroundColor(this.accent()).borderRadius(10)
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
        Text(this.searchTitle.length > 0 ? this.t('search_prefix') + this.searchTitle : this.t('search_results'))
          .fontSize(21)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.primaryText())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(this.t('results_hint'))
          .fontSize(12)
          .fontColor(this.secondaryText())
          .margin({ top: 3, bottom: 10 })
        this.StatusCard()
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
      }.width('100%').padding(14)
    }
    .layoutWeight(1)
    .backgroundColor(this.appBg())
  }

  @Builder
  private ChaptersPage() {
    Column() {
      Row() {
        Column() {
          Image($rawfile('ic_back.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.primaryText()))
        }.padding({ left: 12, right: 8, top: 6, bottom: 6 }).onClick(() => { this.mode = 'results'; })
        Text(this.currentTitle.length > 0 ? this.currentTitle : this.t('chapter_list'))
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .margin({ left: 6 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Column() {
          Image($rawfile('ic_add_shelf.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.accent()))
        }.padding({ left: 8, right: 12, top: 6, bottom: 6 }).onClick(() => this.addCurrentToShelf())
      }.width('100%').padding({ left: 4, right: 4, top: 10, bottom: 8 })
      Column() { this.StatusCard() }.padding({ left: 14, right: 14 })
      Scroll() {
        Column() {
          if (this.chapters.length === 0) {
            Text(this.t('no_chapters')).fontSize(14).fontColor(this.secondaryText()).width('100%').padding(12).backgroundColor(this.cardBg()).borderRadius(10)
          } else {
            ForEach(this.chapters, (chapter: ChapterItem) => {
              Row() {
                Text(chapter.index + '').fontSize(13).fontColor('#FFFFFF').textAlign(TextAlign.Center).width(32).height(32).backgroundColor(this.accent()).borderRadius(16)
                Text(chapter.title).fontSize(15).fontWeight(FontWeight.Medium).layoutWeight(1).margin({ left: 10 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
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
      }.layoutWeight(1)
    }
    .layoutWeight(1)
    .backgroundColor(this.appBg())
  }

  @Builder
  private ReaderPage() {
    Column() {
      Row() {
        Column() {
          Image($rawfile('ic_back.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.primaryText()))
        }.padding({ left: 12, right: 8, top: 6, bottom: 6 }).onClick(() => { this.mode = this.chapters.length > 0 ? 'chapters' : 'results'; })
        Text(this.currentChapterTitle.length > 0 ? this.currentChapterTitle : this.currentTitle).fontSize(16).fontWeight(FontWeight.Bold).layoutWeight(1).margin({ left: 6 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Column() {
          Image($rawfile('ic_add_shelf.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.accent()))
        }.padding({ left: 8, right: 12, top: 6, bottom: 6 }).onClick(() => this.addCurrentToShelf())
      }.width('100%').padding(10).backgroundColor(this.readerBarBg())
      Scroll() {
        Column() {
          this.StatusCard()
          ForEach(this.images, (item: ReaderImageItem) => {
            Column() {
              if (this.showImageIndex) Text('#' + item.index + ' · ' + item.status).fontSize(11).fontColor(this.secondaryText()).margin({ bottom: 4 })
              Image(item.url)
                .width('100%')
                .objectFit(ImageFit.Contain)
                .backgroundColor(this.readerDarkMode ? '#111111' : '#FFFFFF')
                .onComplete(() => this.markImage(item.index, 'ok'))
                .onError(() => this.markImage(item.index, 'error'))
            }.width('100%').margin({ bottom: 8 })
          }, (item: ReaderImageItem) => item.url + item.index)
        }.width('100%').padding(10)
      }.layoutWeight(1).backgroundColor(this.readerDarkMode ? '#050505' : this.appBg())
    }.layoutWeight(1)
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
      Image($rawfile(icon + '.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.secondaryText()))
      Column({ space: 4 }) {
        Text(label).fontSize(16).fontColor(this.primaryText()).width('100%')
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      Text(value).fontSize(13).fontColor(this.secondaryText()).textAlign(TextAlign.End)
      Image($rawfile('ic_more.svg')).width(16).height(16).colorFilter(createStrokeIconColorFilter(this.secondaryText()))
    }
    .width('100%')
    .height(50)
    .border(showTopBorder ? { width: { top: 1 }, color: this.borderSubtle() } : { width: 0 })
  }

  @Builder
  private ToggleSettingRow(icon: string, label: string, isOn: boolean, showTopBorder: boolean) {
    Row({ space: 12 }) {
      Image($rawfile(icon + '.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.secondaryText()))
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
        this.statusText = this.t('theme_switched');
      }
      this.themeDialogVisible = false;
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
      this.languageDialogVisible = false;
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
          Text(this.t('settings')).fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).width('100%').margin({ top: 12, bottom: 6 })
          this.StatusCard()

          this.SectionLabel(this.t('basic_settings'))
          Column({ space: 0 }) {
            Column() { this.LinkRow('ic_moon', this.t('theme'), this.themeDisplay(), false) }.onClick(() => { this.themeDialogVisible = true; })
            Column() { this.LinkRow('ic_language', this.t('language'), this.languageDisplay(), true) }.onClick(() => { this.languageDialogVisible = true; })
            Column() { this.ToggleSettingRow('ic_fullscreen', this.t('reader_fullscreen'), this.fullscreenReader, true) }.onClick(() => { this.fullscreenReader = !this.fullscreenReader; })
            Column() { this.ToggleSettingRow('ic_layout', this.t('floating_controls'), this.floatingReaderControls, true) }.onClick(() => { this.floatingReaderControls = !this.floatingReaderControls; })
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

          this.SectionLabel(this.t('about'))
          Column({ space: 0 }) {
            Row({ space: 12 }) {
              Image($rawfile('ic_info.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.secondaryText()))
              Text(this.t('version')).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
              Text(APP_VERSION).fontSize(13).fontColor(this.secondaryText())
            }.width('100%').height(50)
            Divider().color(this.borderSubtle()).width('100%').padding({ left: 32 })
            Row({ space: 12 }) {
              Image($rawfile('ic_clock.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.secondaryText()))
              Text(this.t('build_time')).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
              Text(APP_BUILD_TIME).fontSize(13).fontColor(this.secondaryText())
            }.width('100%').height(50)
          }.width('100%').padding({ left: 18, right: 18 }).backgroundColor(this.cardBg()).borderRadius(18)
        }.width('100%').padding(14)
      }.layoutWeight(1).padding({ bottom: 100 })
      if (this.settingsDialog.length > 0) this.SettingsDialog()
      if (this.themeDialogVisible) this.ThemeDialog()
      if (this.languageDialogVisible) this.LanguageDialog()
    }.layoutWeight(1).backgroundColor(this.appBg())
  }

  @Builder
  private DialogLinkRow(label: string, value: string, showTopBorder: boolean) {
    Row() {
      Text(label).fontSize(16).fontColor(this.primaryText()).layoutWeight(1)
      Text(value).fontSize(13).fontColor(this.secondaryText())
      Image($rawfile('ic_more.svg')).width(16).height(16).colorFilter(createStrokeIconColorFilter(this.secondaryText())).margin({ left: 4 })
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
      Image($rawfile('ic_close.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.secondaryText())).onClick(() => { this.settingsDialog = ''; })
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
          TextInput({ placeholder: this.t('extra_terms'), text: this.extraSearchTerms }).height(42).backgroundColor(this.inputBg()).borderRadius(12).padding({ left: 10, right: 10 }).onChange((value: string) => { this.extraSearchTerms = value; })
          TextInput({ placeholder: this.t('site_hint'), text: this.siteHint }).height(42).backgroundColor(this.inputBg()).borderRadius(12).padding({ left: 10, right: 10 }).onChange((value: string) => { this.siteHint = value; })
        } else if (this.settingsDialog === 'sources') {
          this.DialogHeader(this.t('source_switch'))
          Column({ space: 0 }) {
            Column() { this.DialogToggleRow(this.t('search_engine'), this.enableSearchEngines, false) }.onClick(() => { this.enableSearchEngines = !this.enableSearchEngines; })
            Column() { this.DialogToggleRow(this.t('html_rules'), this.enableHtmlRules, true) }.onClick(() => { this.enableHtmlRules = !this.enableHtmlRules; })
            Column() { this.DialogLinkRow(this.t('remote_rules'), this.remoteRuleCount + this.t('rules_unit'), true) }.onClick(() => this.updateRemoteRules())
          }.width('100%').padding({ left: 4, right: 4 }).backgroundColor(this.cardBg()).borderRadius(18)
          Text(this.remoteRuleStatus).fontSize(12).fontColor(this.secondaryText()).width('100%')
        } else if (this.settingsDialog === 'reader') {
          this.DialogHeader(this.t('display_reading'))
          Column({ space: 0 }) {
            Column() { this.DialogToggleRow(this.t('auto_cover'), this.autoCoverEnabled, false) }.onClick(() => { this.autoCoverEnabled = !this.autoCoverEnabled; })
            Column() { this.DialogToggleRow(this.t('show_page_num'), this.showImageIndex, true) }.onClick(() => { this.showImageIndex = !this.showImageIndex; })
            Column() { this.DialogLinkRow(this.t('reading_bg'), this.readerDarkMode ? this.t('dark_color') : this.t('light_color'), true) }.onClick(() => { this.readerDarkMode = !this.readerDarkMode; })
            Column() { this.DialogLinkRow(this.t('max_results'), this.maxSearchResults + this.t('items_unit'), true) }.onClick(() => { this.maxSearchResults = this.maxSearchResults === 40 ? 80 : 40; })
            Column() { this.DialogLinkRow(this.t('chapter_pages'), this.maxReaderPages + this.t('pages_unit'), true) }.onClick(() => { this.maxReaderPages = this.maxReaderPages === 6 ? 8 : 6; })
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
          TextInput({ placeholder: this.t('remote_url'), text: this.remoteRuleUrl }).height(42).backgroundColor(this.inputBg()).borderRadius(12).padding({ left: 10, right: 10 }).onChange((value: string) => { this.remoteRuleUrl = value; })
          Text(this.remoteRuleStatus).fontSize(12).fontColor(this.secondaryText()).width('100%')
        } else {
          this.DialogHeader(this.t('advanced_rules'))
          TextInput({ placeholder: this.t('custom_json'), text: this.customRuleText }).height(120).backgroundColor(this.inputBg()).borderRadius(12).padding(10).onChange((value: string) => { this.customRuleText = value; })
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
          Image($rawfile('ic_close.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.primaryText())).onClick(() => { this.themeDialogVisible = false; })
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
          Image($rawfile('ic_close.svg')).width(20).height(20).colorFilter(createStrokeIconColorFilter(this.primaryText())).onClick(() => { this.languageDialogVisible = false; })
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
  private ShelfPage() {
    Scroll() {
      Column() {
        Row() {
          Image($rawfile('ic_shelf.svg')).width(22).height(22).colorFilter(createStrokeIconColorFilter(this.accent())).margin({ right: 8 })
          Text(this.t('shelf')).fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).layoutWeight(1)
        }.width('100%').margin({ top: 12, bottom: 12 })
        if (this.bookshelf.length === 0) {
          Text(this.t('shelf_empty')).fontSize(14).fontColor(this.secondaryText()).width('100%').padding(14).backgroundColor(this.cardBg()).borderRadius(16)
        } else {
          ForEach(this.bookshelf, (item: BookshelfItem) => {
            Column() { this.SettingCard(item.title, item.sourceName + ' · ' + item.lastReadAt, item.progressPercent + '%') }
              .onClick(() => this.loadDetail(item.url, item.title, this.findRule(item.sourceId)))
          }, (item: BookshelfItem) => item.url)
        }
      }.width('100%').padding(14)
    }.layoutWeight(1).backgroundColor(this.appBg()).padding({ bottom: 100 })
  }

  @Builder
  private HistoryPage() {
    Scroll() {
      Column() {
        Row() {
          Image($rawfile('ic_history.svg')).width(22).height(22).colorFilter(createStrokeIconColorFilter(this.accent())).margin({ right: 8 })
          Text(this.t('history')).fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).layoutWeight(1)
        }.width('100%').margin({ top: 12, bottom: 12 })
        if (this.history.length === 0) {
          Text(this.t('history_empty')).fontSize(14).fontColor(this.secondaryText()).width('100%').padding(14).backgroundColor(this.cardBg()).borderRadius(16)
        } else {
          ForEach(this.history, (item: ReadingHistoryItem) => {
            Column() { this.SettingCard(item.title, item.chapterTitle + ' · ' + item.lastReadAt, item.imageCount + this.t('images_unit')) }
              .onClick(() => this.loadChapter({ title: item.chapterTitle, url: item.url, index: 1, sourceId: item.sourceId, sourceName: item.sourceName }, this.findRule(item.sourceId)))
          }, (item: ReadingHistoryItem) => item.url)
        }
      }.width('100%').padding(14)
    }.layoutWeight(1).backgroundColor(this.appBg()).padding({ bottom: 100 })
  }

  @Builder
  private UiIcon(name: string, selected: boolean, size: number) {
    if (name === 'search') Image($rawfile('ic_search.svg')).width(size).height(size).colorFilter(createStrokeIconColorFilter(selected ? this.accent() : this.secondaryText()))
    else if (name === 'shelf') Image($rawfile('ic_shelf.svg')).width(size).height(size).colorFilter(createStrokeIconColorFilter(selected ? this.accent() : this.secondaryText()))
    else if (name === 'history') Image($rawfile('ic_history.svg')).width(size).height(size).colorFilter(createStrokeIconColorFilter(selected ? this.accent() : this.secondaryText()))
    else Image($rawfile('ic_settings.svg')).width(size).height(size).colorFilter(createStrokeIconColorFilter(selected ? this.accent() : this.secondaryText()))
  }

  @Builder
  private TabPill(tab: string, label: string) {
    Column({ space: 3 }) {
      this.UiIcon(tab, this.activeTab === tab, 22)
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
    .backgroundColor(this.isDark() ? '#20000000' : '#30FFFFFF')
    .backgroundBlurStyle(BlurStyle.Thin, { colorMode: this.isDark() ? ThemeColorMode.DARK : ThemeColorMode.LIGHT, adaptiveColor: AdaptiveColor.AVERAGE })
    .border({ width: 1, color: this.isDark() ? '#18FFFFFF' : '#28FFFFFF' })
    .shadow({ radius: 8, color: '#18000000', offsetY: 3 })
  }

  build() {
    Stack() {
      Column() {
        if (this.activeTab === 'search' && this.mode === 'results') this.SearchHeader()
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
          Blank()
          this.BottomTabs()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.End)
        .padding({ left: 14, right: 14, bottom: 14 })
        .hitTestBehavior(HitTestMode.Transparent)
      }
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
