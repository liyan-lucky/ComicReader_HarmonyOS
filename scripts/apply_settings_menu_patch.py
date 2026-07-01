#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Compact the Settings page into a first-level menu + second-level detail pages.

This keeps Settings short:
- Main settings page only shows category cards.
- Tapping a category opens a secondary settings menu.
- Back behavior returns from secondary settings to the settings menu first.
"""
from pathlib import Path

path = Path('entry/src/main/ets/pages/Index.ets')
text = path.read_text(encoding='utf-8')


def replace_between(source: str, start: str, end: str, replacement: str) -> str:
    start_index = source.find(start)
    if start_index < 0:
        raise SystemExit(f'Start anchor not found: {start!r}')
    end_index = source.find(end, start_index)
    if end_index < 0:
        raise SystemExit(f'End anchor not found after {start!r}: {end!r}')
    return source[:start_index] + replacement + source[end_index:]

# Add state for settings secondary pages.
state_anchor = "  @State private floatingReaderControls: boolean = true;\n"
if "@State private settingsSection: string = 'menu';" not in text:
    text = text.replace(state_anchor, state_anchor + "  @State private settingsSection: string = 'menu';\n")

# Back key returns from secondary settings pages to the settings menu.
back_anchor = "  onBackPress(): boolean {\n"
back_insert = """  onBackPress(): boolean {
    if (this.activeTab === 'settings' && this.settingsSection !== 'menu') {
      this.settingsSection = 'menu';
      return true;
    }
"""
if "this.activeTab === 'settings' && this.settingsSection !== 'menu'" not in text:
    text = text.replace(back_anchor, back_insert)

settings_block = r'''  @Builder
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
  private SettingMenuCard(title: string, desc: string, value: string, section: string) {
    Column() {
      Row() {
        Column() {
          Text(title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.primaryText())
            .width('100%')
          Text(desc)
            .fontSize(12)
            .fontColor(this.secondaryText())
            .lineHeight(18)
            .margin({ top: 5 })
            .width('100%')
        }
        .layoutWeight(1)
        Text(value)
          .fontSize(12)
          .fontColor(this.secondaryText())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ left: 10, right: 8 })
        Text('›')
          .fontSize(24)
          .fontColor(this.secondaryText())
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.cardBg())
    .borderRadius(18)
    .margin({ bottom: 10 })
    .onClick(() => { this.settingsSection = section; })
  }

  @Builder
  private SettingBackHeader(title: string, desc: string) {
    Column() {
      Row() {
        Button('设置')
          .height(34)
          .fontSize(12)
          .onClick(() => { this.settingsSection = 'menu'; })
        Column() {
          Text(title)
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.primaryText())
            .width('100%')
          Text(desc)
            .fontSize(12)
            .fontColor(this.secondaryText())
            .lineHeight(18)
            .margin({ top: 3 })
            .width('100%')
        }
        .layoutWeight(1)
        .margin({ left: 10 })
      }
      .width('100%')
      .margin({ top: 12, bottom: 12 })
    }
    .width('100%')
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
  private SettingsMenuPage() {
    Text('设置')
      .fontSize(22)
      .fontWeight(FontWeight.Bold)
      .width('100%')
      .margin({ top: 12, bottom: 6 })
    Text('设置已改为一级分类入口，点击分类后进入二级菜单，避免主设置页过长。')
      .fontSize(13)
      .fontColor(this.secondaryText())
      .lineHeight(20)
      .width('100%')
      .margin({ bottom: 12 })
    this.StatusCard()
    this.SettingMenuCard('基础设置', '主题、语言、阅读页全屏与悬浮控制。', this.themeLabel(), 'basic')
    this.SettingMenuCard('搜索设置', '搜索模式、搜索引擎、语言倾向和额外关键词。', this.searchMode + ' · ' + this.selectedEngine().name, 'search')
    this.SettingMenuCard('公开源开关', '公开馆藏、HTML规则源、官方试读和搜索发现过滤。', this.enableSearchEngines ? '已启用' : '已关闭', 'sources')
    this.SettingMenuCard('显示与阅读', '结果展示、封面补全、卷轴阅读和历史保留。', this.resultViewMode === 'grid' ? '网格' : '列表', 'reader')
    this.SettingMenuCard('搜索引擎清单', '查看搜索引擎，选择当前引擎或启用/停用。', this.selectedEngine().name, 'engines')
    this.SettingMenuCard('远程规则', '从 GitHub Raw 拉取规则仓库生成的公开源规则。', this.remoteRuleCount + ' 条', 'remote')
    this.SettingMenuCard('高级规则', '查看内置规则源，粘贴自定义 JSON 规则。', this.rules.length + ' 个源', 'advanced')
  }

  @Builder
  private SettingsBasicPage() {
    this.SettingBackHeader('基础设置', '只保留常用基础项，语言入口暂时保留在二级菜单。')
    Column() { this.SettingCard(this.t('theme'), '明亮 / 暗黑双主题，阅读页会自动跟随。', this.themeLabel()) }.onClick(() => this.toggleTheme())
    Column() { this.SettingCard(this.t('language'), '当前支持中文 / English，后续可扩展更多语言。', this.languageLabel()) }.onClick(() => this.toggleLanguage())
    Column() { this.SettingCard(this.t('fullReader'), '阅读页默认全屏，顶部和底部使用悬浮独立按钮。', this.fullscreenReader ? '开' : '关') }.onClick(() => { this.fullscreenReader = !this.fullscreenReader; })
    Column() { this.SettingCard(this.t('floatingControls'), '隐藏传统标题栏，使用胶囊悬浮控制。', this.floatingReaderControls ? '开' : '关') }.onClick(() => { this.floatingReaderControls = !this.floatingReaderControls; })
  }

  @Builder
  private SettingsSearchPage() {
    this.SettingBackHeader('搜索设置', '搜索相关选项集中在这里，主设置页只显示一个入口。')
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
    this.SettingSectionTitle('API Key', '普通用户可以不填；需要 Brave / Google 可在这里配置。')
    TextInput({ placeholder: 'Brave Search API Key（可选）', text: this.braveApiKey })
      .height(42).fontSize(13).backgroundColor(this.cardBg()).borderRadius(10).padding({ left: 10, right: 10 }).margin({ bottom: 8 })
      .onChange((value: string) => { this.braveApiKey = value; })
    TextInput({ placeholder: 'Google Programmable Search API Key（可选）', text: this.googleApiKey })
      .height(42).fontSize(13).backgroundColor(this.cardBg()).borderRadius(10).padding({ left: 10, right: 10 }).margin({ bottom: 8 })
      .onChange((value: string) => { this.googleApiKey = value; })
    TextInput({ placeholder: 'Google CX / Search Engine ID（可选）', text: this.googleCx })
      .height(42).fontSize(13).backgroundColor(this.cardBg()).borderRadius(10).padding({ left: 10, right: 10 }).margin({ bottom: 14 })
      .onChange((value: string) => { this.googleCx = value; })
  }

  @Builder
  private SettingsSourcesPage() {
    this.SettingBackHeader('公开源开关', '公开来源、官方试读、搜索发现和过滤模式集中在这里。')
    Column() { this.SettingCard('搜索引擎总开关', '关闭后只用公开API/规则源。', this.enableSearchEngines ? '开' : '关') }.onClick(() => { this.enableSearchEngines = !this.enableSearchEngines; })
    Column() { this.SettingCard('Internet Archive', '公开馆藏，IIIF/metadata卷轴。', this.enableInternetArchive ? '开' : '关') }.onClick(() => { this.enableInternetArchive = !this.enableInternetArchive; })
    Column() { this.SettingCard('Open Library', '公开书目，带IA馆藏时转卷轴。', this.enableOpenLibrary ? '开' : '关') }.onClick(() => { this.enableOpenLibrary = !this.enableOpenLibrary; })
    Column() { this.SettingCard('Library of Congress', '公开影像/图书结果。', this.enableLibraryOfCongress ? '开' : '关') }.onClick(() => { this.enableLibraryOfCongress = !this.enableLibraryOfCongress; })
    Column() { this.SettingCard('Wikimedia Commons', '公开图片资源。', this.enableWikimedia ? '开' : '关') }.onClick(() => { this.enableWikimedia = !this.enableWikimedia; })
    Column() { this.SettingCard('Pepper&Carrot', '公开网页漫画演示目录。', this.enablePepper ? '开' : '关') }.onClick(() => { this.enablePepper = !this.enablePepper; })
    Column() { this.SettingCard('HTML规则源', '开启后使用下方自定义公开源规则。', this.enableHtmlRules ? '开' : '关') }.onClick(() => { this.enableHtmlRules = !this.enableHtmlRules; })
    Column() { this.SettingCard('来源过滤模式', '控制显示官方/公共馆藏、公开可访问或搜索发现全部。', this.sourceFilterMode) }.onClick(() => this.nextSourceFilterMode())
    Column() { this.SettingCard('未核验公开源', '开启后包含搜索发现的公开可访问页。', this.includeUnverifiedPublicSources ? '开' : '关') }.onClick(() => { this.includeUnverifiedPublicSources = !this.includeUnverifiedPublicSources; })
    Column() { this.SettingCard('官方公开/试读源', '开启后包含腾讯动漫、WEBTOON、起点漫画等官方公开目录或试读页面。', this.includeOfficialPreviewSources ? '开' : '关') }.onClick(() => { this.includeOfficialPreviewSources = !this.includeOfficialPreviewSources; })
    Column() { this.SettingCard('搜索引擎发现页', '把搜索引擎发现的漫画页面纳入结果并按域名自动套用解析规则。', this.includeSearchEngineDiscovered ? '开' : '关') }.onClick(() => { this.includeSearchEngineDiscovered = !this.includeSearchEngineDiscovered; })
    Column() { this.SettingCard('排除登录/付费结果', '自动过滤 VIP、Premium、商城、百科、视频、社区等非完全公开阅读结果。', this.excludeLoginPayResults ? '开' : '关') }.onClick(() => { this.excludeLoginPayResults = !this.excludeLoginPayResults; })
  }

  @Builder
  private SettingsReaderPage() {
    this.SettingBackHeader('显示与阅读', '结果列表、卷轴阅读器、封面补全和历史数量集中在这里。')
    Column() { this.SettingCard('列表样式', '搜索结果列表显示模式。', this.coverOnlyMode ? '纯封面' : '封面+名称') }.onClick(() => { this.coverOnlyMode = !this.coverOnlyMode; })
    Column() { this.SettingCard('列表列数', '结果卡片列数。', this.resultColumns === 2 ? '2列' : '3列') }.onClick(() => { this.resultColumns = this.resultColumns === 2 ? 3 : 2; })
    Column() { this.SettingCard('按名称归类', '关闭后按每个URL单独显示。', this.groupByName ? '开' : '关') }.onClick(() => { this.groupByName = !this.groupByName; })
    Column() { this.SettingCard('自动补封面', '结果没封面时访问详情页提取第一张图。', this.autoCoverEnabled ? '开' : '关') }.onClick(() => { this.autoCoverEnabled = !this.autoCoverEnabled; })
    Column() { this.SettingCard('阅读器背景', '深色适合漫画阅读，浅色适合图书影像。', this.readerDarkMode ? '深色' : '浅色') }.onClick(() => { this.readerDarkMode = !this.readerDarkMode; })
    Column() { this.SettingCard('图片适配', 'Contain完整显示，Cover填满宽度。', this.readerFitContain ? 'Contain' : 'Cover') }.onClick(() => { this.readerFitContain = !this.readerFitContain; })
    Column() { this.SettingCard('显示页码', '控制卷轴中每张图上方编号。', this.showImageIndex ? '开' : '关') }.onClick(() => { this.showImageIndex = !this.showImageIndex; })
    Column() { this.SettingCard('图片去重', '章节多页追踪时去掉重复图片URL。', this.dedupeImages ? '开' : '关') }.onClick(() => { this.dedupeImages = !this.dedupeImages; })
    Column() { this.SettingCard('渲染卷轴兜底', '公开站点若静态HTML拿不到图片，使用无地址栏Web渲染并隐藏导航。', this.enableRenderedWebFallback ? '开' : '关') }.onClick(() => { this.enableRenderedWebFallback = !this.enableRenderedWebFallback; })
    Column() { this.SettingCard('封面补全数量', '控制搜索后自动补封面数量，越大越慢。', this.maxCoverEnrich + '个') }.onClick(() => { this.maxCoverEnrich = this.maxCoverEnrich === 12 ? 30 : (this.maxCoverEnrich === 30 ? 60 : 12); })
    Column() { this.SettingCard('最大结果数', '控制每次搜索合并后的最大条目数。', this.maxSearchResults + '个') }.onClick(() => { this.maxSearchResults = this.maxSearchResults === 40 ? 80 : (this.maxSearchResults === 80 ? 150 : 40); })
    Column() { this.SettingCard('章节追踪页数', '控制下一页追踪上限，避免死循环。', this.maxReaderPagesSetting + '页') }.onClick(() => { this.maxReaderPagesSetting = this.maxReaderPagesSetting === 4 ? 8 : (this.maxReaderPagesSetting === 8 ? 16 : 4); })
    Column() { this.SettingCard('历史保留数', '控制阅读历史最大数量。', this.keepHistoryCount + '条') }.onClick(() => { this.keepHistoryCount = this.keepHistoryCount === 20 ? 40 : (this.keepHistoryCount === 40 ? 80 : 20); this.history = this.history.slice(0, this.keepHistoryCount); })
  }

  @Builder
  private SettingsEnginesPage() {
    this.SettingBackHeader('搜索引擎清单', '点击卡片切换当前搜索引擎，按钮用于启用或停用。')
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
  }

  @Builder
  private SettingsRemotePage() {
    this.SettingBackHeader('远程规则', '从可信 GitHub index.json 拉取公开源规则，失败时保留内置规则。')
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
  }

  @Builder
  private SettingsAdvancedPage() {
    this.SettingBackHeader('高级规则', '展示当前公开 HTML 源，也可以粘贴自定义 JSON 规则。')
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

  @Builder
  private SettingsDetailPage() {
    if (this.settingsSection === 'basic') {
      this.SettingsBasicPage()
    } else if (this.settingsSection === 'search') {
      this.SettingsSearchPage()
    } else if (this.settingsSection === 'sources') {
      this.SettingsSourcesPage()
    } else if (this.settingsSection === 'reader') {
      this.SettingsReaderPage()
    } else if (this.settingsSection === 'engines') {
      this.SettingsEnginesPage()
    } else if (this.settingsSection === 'remote') {
      this.SettingsRemotePage()
    } else if (this.settingsSection === 'advanced') {
      this.SettingsAdvancedPage()
    } else {
      this.settingsSection = 'menu';
      this.SettingsMenuPage()
    }
  }

  @Builder
  private SettingsPage() {
    Scroll() {
      Column() {
        if (this.settingsSection === 'menu') {
          this.SettingsMenuPage()
        } else {
          this.SettingsDetailPage()
        }
      }
      .width('100%')
      .padding(14)
    }
    .layoutWeight(1)
    .backgroundColor(this.appBg())
  }

'''

text = replace_between(
    text,
    "  @Builder\n  private SettingCard(title: string, desc: string, value: string) {",
    "  @Builder\n  private AboutInfoRow(label: string, value: string) {",
    settings_block,
)

for required in [
    "@State private settingsSection: string = 'menu';",
    "private SettingMenuCard(",
    "private SettingsMenuPage()",
    "private SettingsDetailPage()",
    "this.activeTab === 'settings' && this.settingsSection !== 'menu'",
]:
    if required not in text:
        raise SystemExit(f'Settings compact patch missing: {required}')

path.write_text(text, encoding='utf-8')
print('Compact settings menu patch applied to', path)
