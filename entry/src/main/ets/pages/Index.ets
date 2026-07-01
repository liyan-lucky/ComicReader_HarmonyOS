import { ComicSourceRule, SearchResultItem, ChapterItem, ReaderImageItem, ReadingHistoryItem, BookshelfItem, SearchEngineConfig } from '../model/ComicModels';
import { DEFAULT_SOURCES, RULE_TEMPLATE, ruleForPublicUrl } from '../common/SourceRules';
import { HttpClient } from '../common/HttpClient';
import { parseSearchResults, parseChapters, parseImages, parseNextPageUrl } from '../common/HtmlParser';
import { looksLikeUrl, normalizeUserUrl } from '../common/UrlUtil';
import { DEFAULT_SEARCH_ENGINES, buildEngineQuery, buildSearchEngineUrl, parseSearchEngineResults, isEngineConfigured, engineHeaders, searchEngineUserAgent } from '../common/SearchEngines';
import { RemoteRuleService, DEFAULT_REMOTE_RULE_URL } from '../common/RemoteRuleService';
import { APP_VERSION, APP_BUILD_TIME } from '../common/BuildInfo';

@Entry
@Component
struct Index {
  @State private activeTab: string = 'search';
  @State private mode: string = 'home';
  @State private queryText: string = '';
  @State private searchTitle: string = '';
  @State private statusText: string = '输入漫画名称后搜索公开漫画网页。';
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

  @State private searchMode: string = '混合';
  @State private searchAllEngines: boolean = false;
  @State private languageMode: string = '中文';
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
  @State private remoteRuleStatus: string = '远程规则未更新';
  @State private remoteRuleCount: number = 0;
  @State private customRuleText: string = RULE_TEMPLATE;
  @State private settingsDialog: string = '';

  aboutToAppear(): void {
    this.queryText = '';
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

  private appBg(): string { return '#F6F8FA'; }
  private cardBg(): string { return '#FFFFFF'; }
  private accent(): string { return '#34C759'; }
  private primaryText(): string { return '#111827'; }
  private secondaryText(): string { return '#7A828C'; }
  private warnBg(): string { return '#FFF7E8'; }
  private warnText(): string { return '#8A5A12'; }
  private selectedSoftBg(): string { return '#E9FFF0'; }
  private glassBg(): string { return '#FFFFFFEE'; }

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
    return title.length > 0 ? title : '未命名漫画';
  }

  private resultAuthor(item: SearchResultItem): string {
    return item.author !== undefined && item.author.length > 0 ? item.author : '未知作者';
  }

  private resultLatest(item: SearchResultItem): string {
    if (item.latestChapter !== undefined && item.latestChapter.length > 0) return item.latestChapter;
    if (item.isChapter) return this.cleanTitle(item.title);
    return '最新章节待获取';
  }

  private resultUpdate(item: SearchResultItem): string {
    return item.updateTime !== undefined && item.updateTime.length > 0 ? item.updateTime : '更新时间待获取';
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
      category: item.category !== undefined ? item.category : '漫画'
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
    this.statusText = `正在搜索“${keyword}”...`;
  }

  private async startSearch(): Promise<void> {
    const keyword = this.queryText.trim();
    if (keyword.length === 0) {
      this.statusText = '请输入漫画名称。';
      return;
    }
    if (this.isLoading) return;
    if (looksLikeUrl(keyword)) {
      this.resetSearchState(keyword);
      this.isLoading = true;
      await this.loadDetail(normalizeUserUrl(keyword), '公开URL解析', ruleForPublicUrl(normalizeUserUrl(keyword), this.genericRule()));
      this.isLoading = false;
      return;
    }
    await this.searchKeyword(keyword);
  }

  private async searchKeyword(keyword: string): Promise<void> {
    this.resetSearchState(keyword);
    this.isLoading = true;
    try {
      if (this.searchMode !== '仅公开API') await this.searchSelectedEngines(keyword);
      if (this.searchMode !== '仅搜索引擎') await this.searchHtmlRuleSources(keyword);
      if (this.autoCoverEnabled) await this.enrichResultCovers(8);
    } finally {
      this.isLoading = false;
      this.statusText = this.results.length > 0 ? `搜索完成：${this.results.length} 个漫画相关条目。` : '没有找到漫画相关结果，换个关键词或站点提示试试。';
    }
  }

  private async searchSelectedEngines(keyword: string): Promise<void> {
    if (!this.enableSearchEngines) return;
    const query = buildEngineQuery(keyword, this.extraSearchTerms, this.languageMode, this.siteHint);
    const engines: SearchEngineConfig[] = [];
    if (this.searchAllEngines || this.searchMode === '全引擎+公开API') {
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
        this.statusText = `${engine.name} 返回 ${parsed.length} 个漫画相关网页，当前 ${this.results.length} 个。`;
      } catch (err) {
        this.statusText = `${engine.name} 检索失败，继续其它源。`;
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
          this.statusText = `规则源整理中：成功 ${success} 个源，当前 ${this.results.length} 个结果。`;
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
    this.statusText = '正在读取章节目录...';
    try {
      const html = await HttpClient.getText(url, rule.userAgent, rule.referer.length > 0 ? rule.referer : url);
      const parsedChapters = parseChapters(html, rule, url);
      this.chapters = parsedChapters;
      if (parsedChapters.length === 0) {
        await this.loadChapter({ title: this.currentTitle, url: url, index: 1, sourceId: rule.id, sourceName: rule.name }, rule);
      } else {
        this.statusText = `已找到 ${parsedChapters.length} 个章节。`;
      }
    } catch (err) {
      this.statusText = '章节读取失败。';
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
      this.statusText = `正在追踪章节分页：第 ${page + 2} 页，已提取 ${allImages.length} 张图片。`;
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
    this.statusText = '正在生成卷轴...';
    try {
      const parsedImages = await this.fetchReaderImagesWithPagination(chapter.url, rule);
      this.images = parsedImages;
      this.statusText = parsedImages.length > 0 ? `卷轴生成完成：${parsedImages.length} 张图片。` : '没有提取到图片。';
      this.addHistory(chapter, parsedImages.length);
    } catch (err) {
      this.statusText = '卷轴生成失败。';
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
      title: this.currentTitle.length > 0 ? this.currentTitle : '未命名漫画',
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
    this.statusText = '已加入书架。';
  }

  private cycleEngine(): void {
    this.selectedEngineIndex = (this.selectedEngineIndex + 1) % this.searchEngines.length;
  }

  private nextSearchMode(): void {
    if (this.searchMode === '混合') this.searchMode = '仅搜索引擎';
    else if (this.searchMode === '仅搜索引擎') this.searchMode = '仅公开API';
    else this.searchMode = '混合';
  }

  private nextLanguageMode(): void {
    if (this.languageMode === '中文') this.languageMode = '英文';
    else if (this.languageMode === '英文') this.languageMode = '自动';
    else this.languageMode = '中文';
  }

  private toggleTheme(): void {
    this.appTheme = this.appTheme === 'light' ? 'dark' : 'light';
    this.statusText = '主题已切换。';
  }

  private async updateRemoteRules(): Promise<void> {
    this.remoteRuleStatus = '正在更新远程规则...';
    try {
      const loaded = await RemoteRuleService.fetchRemoteRules(this.remoteRuleUrl);
      if (loaded.length > 0) {
        this.rules = loaded.concat(DEFAULT_SOURCES);
        this.remoteRuleCount = loaded.length;
        this.remoteRuleStatus = '远程规则已更新：' + loaded.length + ' 条';
      } else {
        this.remoteRuleStatus = '远程规则为空，继续使用内置规则。';
      }
    } catch (err) {
      this.remoteRuleStatus = '远程规则更新失败。';
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
    Stack() {
      if (this.isLoading) {
        LoadingProgress()
          .width(heightValue + 8)
          .height(heightValue + 8)
      }
      Button(this.isLoading ? '搜索中' : '搜索')
        .height(heightValue)
        .fontSize(15)
        .fontColor('#FFFFFF')
        .backgroundColor(this.accent())
        .borderRadius(heightValue / 2)
        .padding({ left: 20, right: 20 })
        .border({ width: this.isLoading ? 2 : 0, color: this.isLoading ? '#0EA84A' : this.accent() })
        .enabled(!this.isLoading)
        .onClick(() => { this.startSearch(); })
    }
    .height(heightValue + 8)
  }

  @Builder
  private SearchHeader() {
    Column() {
      Text('漫画浏览器')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.primaryText())
        .width('100%')
        .padding({ left: 14, right: 14, top: 12, bottom: 6 })
      Row() {
        TextInput({ placeholder: '输入漫画名称', text: this.queryText })
          .height(44)
          .layoutWeight(1)
          .fontSize(15)
          .backgroundColor('#F0F3F6')
          .borderRadius(22)
          .padding({ left: 14, right: 14 })
          .onChange((value: string) => { this.queryText = value; })
          .onSubmit(() => { this.startSearch(); })
        Column() { this.SearchActionButton(44) }
          .margin({ left: 10 })
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
      Text('漫画浏览器')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.primaryText())
      Text('输入漫画名称，搜索公开可访问漫画')
        .fontSize(13)
        .fontColor(this.secondaryText())
        .margin({ top: 8, bottom: 24 })
      Row() {
        TextInput({ placeholder: '输入漫画名称', text: this.queryText })
          .height(52)
          .layoutWeight(1)
          .fontSize(15)
          .backgroundColor(this.cardBg())
          .borderRadius(26)
          .padding({ left: 18, right: 18 })
          .onChange((value: string) => { this.queryText = value; })
          .onSubmit(() => { this.startSearch(); })
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
        Text('无封面')
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

  @Builder
  private ResultListCard(item: SearchResultItem) {
    Row() {
      Column() { this.CoverBox(item, 104) }.width(76).height(104).clip(true).borderRadius(12)
      Column() {
        Text(this.cleanTitle(item.title)).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
        Text('作者：' + this.resultAuthor(item)).fontSize(12).fontColor(this.secondaryText()).margin({ top: 5 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text('最新章节：' + this.resultLatest(item)).fontSize(12).fontColor(this.secondaryText()).margin({ top: 4 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text('更新时间：' + this.resultUpdate(item)).fontSize(12).fontColor(this.secondaryText()).margin({ top: 4 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row() {
          Text('漫画').fontSize(11).fontColor('#FFFFFF').padding({ left: 8, right: 8, top: 3, bottom: 3 }).backgroundColor(this.accent()).borderRadius(10)
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
        Text(this.searchTitle.length > 0 ? '搜索：' + this.searchTitle : '漫画结果')
          .fontSize(21)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.primaryText())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text('默认列表显示，分类推荐已移动到书架。')
          .fontSize(12)
          .fontColor(this.secondaryText())
          .margin({ top: 3, bottom: 10 })
        this.StatusCard()
        if (this.results.length === 0) {
          Text(this.isLoading ? '正在搜索公开漫画来源...' : '没有找到结果，换个关键词试试。')
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
        Button('结果').height(34).fontSize(12).onClick(() => { this.mode = 'results'; })
        Text(this.currentTitle.length > 0 ? this.currentTitle : '章节目录')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .margin({ left: 10 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Button('书架').height(34).fontSize(12).onClick(() => this.addCurrentToShelf())
      }.width('100%').padding({ left: 12, right: 12, top: 10, bottom: 8 })
      Column() { this.StatusCard() }.padding({ left: 14, right: 14 })
      Scroll() {
        Column() {
          if (this.chapters.length === 0) {
            Text('没有章节。可能该结果本身就是单话漫画，或目录规则不匹配。').fontSize(14).fontColor(this.secondaryText()).width('100%').padding(12).backgroundColor(this.cardBg()).borderRadius(10)
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
        Button('返回').height(34).fontSize(12).onClick(() => { this.mode = this.chapters.length > 0 ? 'chapters' : 'results'; })
        Text(this.currentChapterTitle.length > 0 ? this.currentChapterTitle : this.currentTitle).fontSize(16).fontWeight(FontWeight.Bold).layoutWeight(1).margin({ left: 10 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Button('书架').height(34).fontSize(12).onClick(() => this.addCurrentToShelf())
      }.width('100%').padding(10).backgroundColor('#FFFFFF')
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
          Text('设置').fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).width('100%').margin({ top: 12, bottom: 6 })
          Text('基础设置和 APP 设置直接展开；搜索、源、阅读、引擎和规则使用弹出对话框。').fontSize(13).fontColor(this.secondaryText()).lineHeight(20).width('100%').margin({ bottom: 12 })
          this.StatusCard()

          Text('基础设置').fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).width('100%').margin({ top: 8, bottom: 8 })
          Column() { this.SettingCard('主题', '明亮 / 暗黑双主题。', this.appTheme === 'light' ? '明亮' : '暗黑') }.onClick(() => this.toggleTheme())
          Column() { this.SettingCard('语言', '界面语言固定中文。', '中文') }
          Column() { this.SettingCard('阅读页全屏', '阅读时隐藏多余控件。', this.fullscreenReader ? '开' : '关') }.onClick(() => { this.fullscreenReader = !this.fullscreenReader; })
          Column() { this.SettingCard('悬浮控制', '阅读页使用悬浮控制按钮。', this.floatingReaderControls ? '开' : '关') }.onClick(() => { this.floatingReaderControls = !this.floatingReaderControls; })

          Text('APP设置').fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).width('100%').margin({ top: 14, bottom: 8 })
          Column() { this.SettingCard('搜索菜单', '搜索模式、搜索引擎、语言倾向和额外关键词。', this.searchMode + ' · ' + this.selectedEngine().name) }.onClick(() => { this.settingsDialog = 'search'; })
          Column() { this.SettingCard('源开关', '搜索引擎、HTML规则源和远程规则。', this.enableSearchEngines ? '已启用' : '已关闭') }.onClick(() => { this.settingsDialog = 'sources'; })
          Column() { this.SettingCard('显示与阅读', '封面补全、卷轴阅读、页码和图片上限。', '阅读设置') }.onClick(() => { this.settingsDialog = 'reader'; })
          Column() { this.SettingCard('搜索引擎', '查看和切换当前搜索引擎。', this.selectedEngine().name) }.onClick(() => { this.settingsDialog = 'engines'; })
          Column() { this.SettingCard('规则设置', '远程规则仓库和规则更新。', this.remoteRuleCount + ' 条') }.onClick(() => { this.settingsDialog = 'rules'; })
          Column() { this.SettingCard('高级规则', '自定义 JSON 规则文本。', this.rules.length + ' 个源') }.onClick(() => { this.settingsDialog = 'advanced'; })

          Text('关于').fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).width('100%').margin({ top: 14, bottom: 8 })
          Column() {
            this.InfoRow('版本号', APP_VERSION)
            this.InfoRow('构建时间', APP_BUILD_TIME)
          }
          .width('100%')
          .padding(14)
          .backgroundColor(this.cardBg())
          .borderRadius(18)
          .margin({ bottom: 14 })
        }.width('100%').padding(14)
      }.layoutWeight(1)
      if (this.settingsDialog.length > 0) this.SettingsDialog()
    }.layoutWeight(1).backgroundColor(this.appBg())
  }

  @Builder
  private DialogRow(title: string, value: string) {
    Row() {
      Text(title).fontSize(15).fontColor(this.primaryText()).layoutWeight(1)
      Text(value).fontSize(13).fontColor(this.secondaryText())
    }.width('100%').padding({ top: 10, bottom: 10 })
  }

  @Builder
  private SettingsDialog() {
    Column() {
      Blank().layoutWeight(1)
      Column() {
        Row() {
          Text(this.settingsDialog === 'search' ? '搜索菜单' : (this.settingsDialog === 'sources' ? '源开关' : (this.settingsDialog === 'reader' ? '显示与阅读' : (this.settingsDialog === 'engines' ? '搜索引擎' : (this.settingsDialog === 'rules' ? '规则设置' : '高级规则')))))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
          Button('关闭').height(32).fontSize(12).onClick(() => { this.settingsDialog = ''; })
        }.width('100%').margin({ bottom: 12 })
        if (this.settingsDialog === 'search') {
          Column() { this.DialogRow('搜索模式', this.searchMode) }.onClick(() => this.nextSearchMode())
          Column() { this.DialogRow('当前搜索引擎', this.selectedEngine().name) }.onClick(() => this.cycleEngine())
          Column() { this.DialogRow('全引擎搜索', this.searchAllEngines ? '开' : '关') }.onClick(() => { this.searchAllEngines = !this.searchAllEngines; })
          Column() { this.DialogRow('语言倾向', this.languageMode) }.onClick(() => this.nextLanguageMode())
          TextInput({ placeholder: '额外搜索词', text: this.extraSearchTerms }).height(42).backgroundColor('#F2F4F7').borderRadius(12).padding({ left: 10, right: 10 }).margin({ top: 8 }).onChange((value: string) => { this.extraSearchTerms = value; })
          TextInput({ placeholder: '站点提示 site:example.com', text: this.siteHint }).height(42).backgroundColor('#F2F4F7').borderRadius(12).padding({ left: 10, right: 10 }).margin({ top: 8 }).onChange((value: string) => { this.siteHint = value; })
        } else if (this.settingsDialog === 'sources') {
          Column() { this.DialogRow('搜索引擎', this.enableSearchEngines ? '开' : '关') }.onClick(() => { this.enableSearchEngines = !this.enableSearchEngines; })
          Column() { this.DialogRow('HTML规则源', this.enableHtmlRules ? '开' : '关') }.onClick(() => { this.enableHtmlRules = !this.enableHtmlRules; })
          Column() { this.DialogRow('远程规则', this.remoteRuleCount + ' 条') }.onClick(() => this.updateRemoteRules())
          Text(this.remoteRuleStatus).fontSize(12).fontColor(this.secondaryText()).width('100%').margin({ top: 8 })
        } else if (this.settingsDialog === 'reader') {
          Column() { this.DialogRow('自动补封面', this.autoCoverEnabled ? '开' : '关') }.onClick(() => { this.autoCoverEnabled = !this.autoCoverEnabled; })
          Column() { this.DialogRow('显示页码', this.showImageIndex ? '开' : '关') }.onClick(() => { this.showImageIndex = !this.showImageIndex; })
          Column() { this.DialogRow('阅读背景', this.readerDarkMode ? '深色' : '浅色') }.onClick(() => { this.readerDarkMode = !this.readerDarkMode; })
          Column() { this.DialogRow('最大结果数', this.maxSearchResults + ' 个') }.onClick(() => { this.maxSearchResults = this.maxSearchResults === 40 ? 80 : 40; })
          Column() { this.DialogRow('章节追踪页数', this.maxReaderPages + ' 页') }.onClick(() => { this.maxReaderPages = this.maxReaderPages === 6 ? 8 : 6; })
        } else if (this.settingsDialog === 'engines') {
          Column() { this.DialogRow('当前搜索引擎', this.selectedEngine().name) }.onClick(() => this.cycleEngine())
          ForEach(this.searchEngines, (engine: SearchEngineConfig) => {
            this.DialogRow(engine.name, engine.enabled ? '开' : '关')
          }, (engine: SearchEngineConfig) => engine.id)
        } else if (this.settingsDialog === 'rules') {
          Column() { this.DialogRow('远程规则数量', this.remoteRuleCount + ' 条') }.onClick(() => this.updateRemoteRules())
          TextInput({ placeholder: '远程规则地址', text: this.remoteRuleUrl }).height(42).backgroundColor('#F2F4F7').borderRadius(12).padding({ left: 10, right: 10 }).margin({ top: 8 }).onChange((value: string) => { this.remoteRuleUrl = value; })
          Text(this.remoteRuleStatus).fontSize(12).fontColor(this.secondaryText()).width('100%').margin({ top: 8 })
        } else {
          TextInput({ placeholder: '自定义 JSON 规则', text: this.customRuleText }).height(120).backgroundColor('#F2F4F7').borderRadius(12).padding(10).onChange((value: string) => { this.customRuleText = value; })
        }
      }
      .width('92%')
      .padding(18)
      .backgroundColor('#FFFFFF')
      .borderRadius(22)
      .margin({ bottom: 36 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#66000000')
  }

  @Builder
  private ShelfPage() {
    Scroll() {
      Column() {
        Text('书架').fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).width('100%').margin({ top: 12, bottom: 12 })
        if (this.bookshelf.length === 0) {
          Text('书架为空。阅读章节后可加入书架。').fontSize(14).fontColor(this.secondaryText()).width('100%').padding(14).backgroundColor(this.cardBg()).borderRadius(16)
        } else {
          ForEach(this.bookshelf, (item: BookshelfItem) => {
            Column() { this.SettingCard(item.title, item.sourceName + ' · ' + item.lastReadAt, item.progressPercent + '%') }
              .onClick(() => this.loadDetail(item.url, item.title, this.findRule(item.sourceId)))
          }, (item: BookshelfItem) => item.url)
        }
      }.width('100%').padding(14)
    }.layoutWeight(1).backgroundColor(this.appBg())
  }

  @Builder
  private HistoryPage() {
    Scroll() {
      Column() {
        Text('历史').fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).width('100%').margin({ top: 12, bottom: 12 })
        if (this.history.length === 0) {
          Text('暂无阅读历史。').fontSize(14).fontColor(this.secondaryText()).width('100%').padding(14).backgroundColor(this.cardBg()).borderRadius(16)
        } else {
          ForEach(this.history, (item: ReadingHistoryItem) => {
            Column() { this.SettingCard(item.title, item.chapterTitle + ' · ' + item.lastReadAt, item.imageCount + '图') }
              .onClick(() => this.loadChapter({ title: item.chapterTitle, url: item.url, index: 1, sourceId: item.sourceId, sourceName: item.sourceName }, this.findRule(item.sourceId)))
          }, (item: ReadingHistoryItem) => item.url)
        }
      }.width('100%').padding(14)
    }.layoutWeight(1).backgroundColor(this.appBg())
  }

  @Builder
  private UiIcon(name: string, selected: boolean, size: number) {
    if (name === 'search') Image($r('app.media.ic_search')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())
    else if (name === 'shelf') Image($r('app.media.ic_shelf')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())
    else if (name === 'history') Image($r('app.media.ic_history')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())
    else Image($r('app.media.ic_settings')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())
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
      if (tab === 'search' && this.mode === 'reader') this.mode = this.results.length > 0 ? 'results' : 'home';
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
      if (this.mode !== 'reader' && this.mode !== 'chapters') this.BottomTabs()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.appBg())
  }
}
