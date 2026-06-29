const fs = require('fs');
const path = require('path');

const INDEX_FILE = path.resolve(__dirname, '../entry/src/main/ets/pages/Index.ets');
const BACKUP_DIR = path.resolve(__dirname, '../.ui-backups');

function replaceOnce(content, from, to, label) {
  if (!content.includes(from)) {
    console.warn('ComicReader UI patch skipped missing marker: ' + label);
    return content;
  }
  return content.replace(from, to);
}

function replaceRegex(content, regex, to, label) {
  if (!regex.test(content)) {
    console.warn('ComicReader UI patch skipped missing regex marker: ' + label);
    return content;
  }
  return content.replace(regex, to);
}

function backupIndex(content) {
  fs.mkdirSync(BACKUP_DIR, { recursive: true });
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupFile = path.join(BACKUP_DIR, `Index.ets.${stamp}.bak`);
  fs.writeFileSync(backupFile, content);
  console.log('ComicReader UI source backup:', path.relative(path.resolve(__dirname, '..'), backupFile));
}

function ensureBuildInfoImport(content) {
  if (content.includes('../common/BuildInfo')) return content;
  return replaceOnce(
    content,
    "import { RemoteRuleService, DEFAULT_REMOTE_RULE_URL } from '../common/RemoteRuleService';\n",
    "import { RemoteRuleService, DEFAULT_REMOTE_RULE_URL } from '../common/RemoteRuleService';\n" +
      "import { APP_VERSION, APP_VERSION_CODE, APP_BUILD_TYPE, APP_BUILD_TIME, APP_BUILD_TARGET } from '../common/BuildInfo';\n",
    'BuildInfo import'
  );
}

function ensureUiState(content) {
  if (content.includes('@State private appTheme')) return content;
  return replaceOnce(
    content,
    "  @State private auditText: string = '审计状态：v5.8 已拆分 App 仓库与规则仓库。App 可从 GitHub Raw 远程更新 generated/index.json 规则，规则仓库可用 GitHub Actions 自动搜索/审计/生成公开源规则。';\n",
    "  @State private auditText: string = '审计状态：v5.8 已拆分 App 仓库与规则仓库。App 可从 GitHub Raw 远程更新 generated/index.json 规则，规则仓库可用 GitHub Actions 自动搜索/审计/生成公开源规则。';\n" +
      "  @State private appTheme: string = 'light';\n" +
      "  @State private appLanguage: string = 'zh';\n" +
      "  @State private fullscreenReader: boolean = true;\n" +
      "  @State private floatingReaderControls: boolean = true;\n",
    'UI state'
  );
}

function ensureUiHelpers(content) {
  const helperBlock = `
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
    this.appLanguage = this.appLanguage === 'en' ? 'zh' : 'en';
    this.statusText = this.appLanguage === 'en' ? 'Language switched to English.' : '语言已切换为中文。';
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
`;
  if (content.includes('private isDarkTheme(): boolean')) return content;
  return replaceOnce(content, '\n  @Builder\n  private StatusCard() {', helperBlock + '\n  @Builder\n  private StatusCard() {', 'UI helpers');
}

function patchCards(content) {
  content = replaceRegex(content, /  @Builder\n  private StatusCard\(\) \{[\s\S]*?\n  \}\n\n  @Builder\n  private AuditCard/, `  @Builder
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
  private AuditCard`, 'StatusCard');

  content = replaceRegex(content, /  @Builder\n  private AuditCard\(\) \{[\s\S]*?\n  \}\n\n  @Builder\n  private SearchHeader/, `  @Builder
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
  private SearchHeader`, 'AuditCard');

  content = replaceRegex(content, /  @Builder\n  private SettingCard\(title: string, desc: string, value: string\) \{[\s\S]*?\n  \}\n\n  @Builder\n  private SettingsPage/, `  @Builder
  private SettingCard(title: string, desc: string, value: string) {
    Column() {
      Row() {
        Column() {
          Text(title).fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.primaryText()).width('100%')
          Text(desc).fontSize(12).fontColor(this.secondaryText()).lineHeight(18).margin({ top: 4 }).width('100%')
        }.layoutWeight(1)
        Text(value)
          .fontSize(12)
          .fontColor('#FFFFFF')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.accent())
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
  private SettingsPage`, 'SettingCard');
  return content;
}

function patchSearchHeader(content) {
  return replaceRegex(content, /  @Builder\n  private SearchHeader\(\) \{[\s\S]*?\n  \}\n\n  @Builder\n  private SearchHome/, `  @Builder
  private SearchHeader() {
    Column() {
      Row() {
        Text(this.t('appTitle'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.primaryText())
          .layoutWeight(1)
        Row() {
          this.MiniPill('中', this.appLanguage === 'zh')
          Text('|').fontSize(11).fontColor(this.mutedText()).margin({ left: 4, right: 4 })
          this.MiniPill('EN', this.appLanguage === 'en')
        }
        .onClick(() => this.toggleLanguage())
        .margin({ right: 8 })
        Button(this.themeLabel())
          .height(32)
          .fontSize(11)
          .onClick(() => this.toggleTheme())
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

      Row() {
        Text(this.searchMode + ' · ' + this.sourceFilterMode + ' · ' + (this.searchAllEngines || this.searchMode === '全引擎+公开API' ? '全引擎' : this.selectedEngine().name) + ' · ' + this.totalSearchSourceCount() + '源')
          .fontSize(12)
          .fontColor(this.secondaryText())
          .layoutWeight(1)
        Button(this.coverOnlyMode ? '封面+名称' : '纯封面')
          .height(30)
          .fontSize(12)
          .onClick(() => { this.coverOnlyMode = !this.coverOnlyMode; })
        Button('演示')
          .height(30)
          .fontSize(12)
          .margin({ left: 8 })
          .onClick(() => this.runDemoSearch())
      }
      .width('100%')
      .padding({ left: 14, right: 14, bottom: 10 })
    }
    .backgroundColor(this.glassBg())
    .borderRadius({ bottomLeft: 22, bottomRight: 22 })
  }

  @Builder
  private SearchHome`, 'SearchHeader');
}

function patchAboutPage(content) {
  const aboutBuilder = `
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
`;
  if (content.includes('private AboutInfoRow(')) {
    content = replaceRegex(content, /\n  @Builder\n  private AboutInfoRow\(label: string, value: string\) \{[\s\S]*?\n  @Builder\n  private BottomTabs\(\) \{/, aboutBuilder + '\n  @Builder\n  private BottomTabs() {', 'replace AboutPage');
  } else {
    content = replaceOnce(content, '\n  @Builder\n  private BottomTabs() {', aboutBuilder + '\n  @Builder\n  private BottomTabs() {', 'insert AboutPage');
  }
  return content;
}

function patchBottomTabs(content) {
  return replaceRegex(content, /  @Builder\n  private BottomTabs\(\) \{[\s\S]*?\n  \}\n\n  build\(\) \{/, `  @Builder
  private TabPill(tab: string, icon: string, label: string) {
    Column() {
      Text(icon)
        .fontSize(18)
        .fontColor(this.activeTab === tab ? '#FFFFFF' : this.secondaryText())
        .textAlign(TextAlign.Center)
      Text(label)
        .fontSize(10)
        .fontColor(this.activeTab === tab ? '#FFFFFF' : this.secondaryText())
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .height(56)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.activeTab === tab ? this.accent() : '#00000000')
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
      this.TabPill('search', '⌕', this.t('search'))
      this.TabPill('shelf', '▣', this.t('shelf'))
      this.TabPill('settings', '⚙', this.t('settings'))
      this.TabPill('about', 'ⓘ', this.t('about'))
    }
    .width('92%')
    .height(68)
    .padding(6)
    .backgroundColor(this.glassBg())
    .borderRadius(34)
    .margin({ left: 16, right: 16, bottom: 10 })
  }

  build() {`, 'BottomTabs');
}

function patchReaderPage(content) {
  return replaceRegex(content, /  @Builder\n  private ReaderPage\(\) \{[\s\S]*?\n  \}\n\n  @Builder\n  private HistoryList/, `  @Builder
  private ReaderFloatingButton(text: string) {
    Text(text)
      .fontSize(14)
      .fontColor('#FFFFFF')
      .textAlign(TextAlign.Center)
      .width(44)
      .height(44)
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
                    .fontColor(item.status === 'error' ? '#E53935' : '#FFFFFF')
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
          this.ReaderFloatingButton('···')
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 10 })
      }

      if (this.floatingReaderControls) {
        Row() {
          this.ReaderFloatingButton('‹')
            .onClick(() => { this.mode = this.chapters.length > 0 ? 'chapters' : (this.results.length > 0 ? 'results' : 'home'); })
          Blank().layoutWeight(1)
          this.ReaderFloatingButton('＋')
            .onClick(() => this.addCurrentToShelf())
          this.ReaderFloatingButton('↻')
            .margin({ left: 10 })
            .onClick(() => this.loadChapterByUrl(this.currentUrl, this.currentChapterTitle, this.findRule(this.currentSourceId)))
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 14 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#050607')
  }

  @Builder
  private HistoryList`, 'ReaderPage');
}

function patchShelfProgress(content) {
  const oldAdd = `    filtered.unshift({
      title: item.title,
      url: item.url,
      cover: item.cover,
      sourceId: item.sourceId,
      sourceName: item.sourceName,
      lastChapterTitle: '',
      addedTimeText: this.nowText(),
      lastReadTimeText: ''
    });`;
  const newAdd = `    filtered.unshift({
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
    });`;
  content = replaceOnce(content, oldAdd, newAdd, 'bookshelf add progress');

  const oldTouch = `        next.push({
          title: item.title,
          url: item.url,
          cover: item.cover.length > 0 ? item.cover : this.currentCover,
          sourceId: item.sourceId,
          sourceName: item.sourceName,
          lastChapterTitle: chapterTitle,
          addedTimeText: item.addedTimeText,
          lastReadTimeText: this.nowText()
        });`;
  const newTouch = `        next.push({
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
        });`;
  content = replaceOnce(content, oldTouch, newTouch, 'bookshelf touch progress');

  const oldOpen = `  private async openShelf(item: BookshelfItem): Promise<void> {
    this.currentTitle = item.title;
    this.currentCover = item.cover;
    this.currentSourceId = item.sourceId;
    this.currentSourceName = item.sourceName;
    await this.loadDetail(item.url, item.title, this.ruleForItemUrl(item.url, item.sourceId));
  }`;
  const newOpen = `  private async openShelf(item: BookshelfItem): Promise<void> {
    this.currentTitle = item.title;
    this.currentCover = item.cover;
    this.currentSourceId = item.sourceId;
    this.currentSourceName = item.sourceName;
    if (item.lastReadUrl !== undefined && item.lastReadUrl.length > 0) {
      await this.loadChapterByUrl(item.lastReadUrl, item.lastChapterTitle.length > 0 ? item.lastChapterTitle : item.title, this.ruleForItemUrl(item.lastReadUrl, item.sourceId));
      return;
    }
    await this.loadDetail(item.url, item.title, this.ruleForItemUrl(item.url, item.sourceId));
  }`;
  content = replaceOnce(content, oldOpen, newOpen, 'open shelf continue');
  return content;
}

function patchSettings(content) {
  if (content.includes("Text('外观与语言')")) return content;
  return replaceOnce(
    content,
    "        this.StatusCard()\n        this.AuditCard()\n\n        Text('搜索引擎')",
    "        this.StatusCard()\n        this.AuditCard()\n\n        Text('外观与语言')\n          .fontSize(18)\n          .fontWeight(FontWeight.Medium)\n          .fontColor(this.primaryText())\n          .width('100%')\n          .margin({ bottom: 8 })\n        Column() { this.SettingCard(this.t('theme'), '明亮 / 暗黑双主题，阅读页会自动跟随。', this.themeLabel()) }.onClick(() => this.toggleTheme())\n        Column() { this.SettingCard(this.t('language'), '当前支持中文 / English，后续可扩展更多语言。', this.languageLabel()) }.onClick(() => this.toggleLanguage())\n        Column() { this.SettingCard(this.t('fullReader'), '阅读页默认全屏，顶部和底部使用悬浮独立按钮。', this.fullscreenReader ? '开' : '关') }.onClick(() => { this.fullscreenReader = !this.fullscreenReader; })\n        Column() { this.SettingCard(this.t('floatingControls'), '隐藏传统标题栏，使用胶囊悬浮控制。', this.floatingReaderControls ? '开' : '关') }.onClick(() => { this.floatingReaderControls = !this.floatingReaderControls; })\n\n        Text('搜索引擎')",
    'settings appearance section'
  );
}

function patchBuild(content) {
  return replaceRegex(content, /  build\(\) \{[\s\S]*?\n  \}\n\}/, `  build() {
    Column() {
      if (this.activeTab === 'search' && this.mode !== 'reader' && this.mode !== 'rendered_reader' && this.mode !== 'chapters') {
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
      } else if (this.activeTab === 'settings') {
        this.SettingsPage()
      } else {
        this.AboutPage()
      }

      if (this.mode !== 'reader' && this.mode !== 'rendered_reader' && this.mode !== 'chapters') {
        this.BottomTabs()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.appBg())
  }
}`, 'build switch');
}

function patchIndexUi() {
  if (!fs.existsSync(INDEX_FILE)) {
    console.warn('ComicReader UI patch skipped; Index.ets not found.');
    return;
  }

  const originalContent = fs.readFileSync(INDEX_FILE, 'utf8');
  let content = originalContent;
  content = ensureBuildInfoImport(content);
  content = ensureUiState(content);
  content = ensureUiHelpers(content);
  content = patchCards(content);
  content = patchSearchHeader(content);
  content = patchShelfProgress(content);
  content = patchSettings(content);
  content = patchReaderPage(content);
  content = patchAboutPage(content);
  content = patchBottomTabs(content);
  content = patchBuild(content);

  if (content !== originalContent) {
    backupIndex(originalContent);
    fs.writeFileSync(INDEX_FILE, content);
    console.log('ComicReader CI ensured HarmonyOS style UI, theme, language, shelf progress, reader and about page.');
  } else {
    console.log('ComicReader CI UI source patch made no changes.');
  }
}

patchIndexUi();

module.exports = { patchIndexUi };
