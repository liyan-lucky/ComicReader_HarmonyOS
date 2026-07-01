#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Unified idempotent UI polish script.

Do not add one-off UI patch scripts. Keep all UI polish here.

Current goals:
- Bottom tabs: 搜索 / 书架 / 历史 / 设置.
- Search home follows the original clean composition: illustration + title + search box only.
- Search results are list-only; no list/grid switch on the search page.
- Search classification/grouping is removed from search results and kept on Shelf topics.
- Result list item layout: cover + title / author / latest chapter / update time / type + source host.
- Settings page is compact: first-level category menu + second-level detail pages.
- About content lives inside Settings -> 关于.
- Search result model includes optional author/latestChapter/updateTime/category fields.
"""
from pathlib import Path

index_path = Path('entry/src/main/ets/pages/Index.ets')
model_path = Path('entry/src/main/ets/model/ComicModels.ets')
text = index_path.read_text(encoding='utf-8')
model_text = model_path.read_text(encoding='utf-8')


def replace_between(source: str, start: str, end: str, replacement: str) -> str:
    start_index = source.find(start)
    if start_index < 0:
        raise SystemExit(f'Start anchor not found: {start!r}')
    end_index = source.find(end, start_index)
    if end_index < 0:
        raise SystemExit(f'End anchor not found after {start!r}: {end!r}')
    return source[:start_index] + replacement + source[end_index:]


def ensure_model_fields(source: str) -> str:
    if 'author?: string;' in source:
        return source
    return source.replace(
        """  groupName?: string;
  description?: string;""",
        """  groupName?: string;
  description?: string;
  /** 作者，搜索源未提供时留空，UI 会显示未知作者。 */
  author?: string;
  /** 最新章节，搜索源未提供时留空，UI 会显示待获取。 */
  latestChapter?: string;
  /** 更新时间，搜索源未提供时留空，UI 会显示待获取。 */
  updateTime?: string;
  /** 题材分类，搜索页不再按此分组，后续用于书架题材推荐。 */
  category?: string;"""
    )


model_text = ensure_model_fields(model_text)

# State defaults.
text = text.replace('@State private coverOnlyMode: boolean = false;', '@State private coverOnlyMode: boolean = true;')
text = text.replace('@State private resultColumns: number = 2;', '@State private resultColumns: number = 3;')
text = text.replace("@State private resultViewMode: string = 'grid';", "@State private resultViewMode: string = 'list';")
if "@State private resultViewMode: string = 'list';" not in text:
    text = text.replace("@State private resultColumns: number = 3;", "@State private resultColumns: number = 3;\n  @State private resultViewMode: string = 'list';")
if "@State private settingsSection: string = 'menu';" not in text:
    text = text.replace("  @State private floatingReaderControls: boolean = true;\n", "  @State private floatingReaderControls: boolean = true;\n  @State private settingsSection: string = 'menu';\n")

# Back key: settings second-level page returns to settings menu first.
if "this.activeTab === 'settings' && this.settingsSection !== 'menu'" not in text:
    text = text.replace(
        "  onBackPress(): boolean {\n",
        """  onBackPress(): boolean {
    if (this.activeTab === 'settings' && this.settingsSection !== 'menu') {
      this.settingsSection = 'menu';
      return true;
    }
"""
    )

# Search header appears only on result page.
text = text.replace(
    "if (this.activeTab === 'search' && this.mode !== 'reader' && this.mode !== 'rendered_reader' && this.mode !== 'chapters') {\n        this.SearchHeader()\n      }",
    "if (this.activeTab === 'search' && this.mode === 'results') {\n        this.SearchHeader()\n      }"
)

# Bottom tab structure.
for old_tabs in [
    """      this.TabPill('search', this.t('search'))
      this.TabPill('shelf', this.t('shelf'))
      this.TabPill('settings', this.t('settings'))
      this.TabPill('about', this.t('about'))""",
    """      this.TabPill('search', '搜索')
      this.TabPill('shelf', '书架')
      this.TabPill('settings', '设置')
      this.TabPill('about', '关于')""",
    """      this.TabPill('search', '搜索')
      this.TabPill('shelf', '书架')
      this.TabPill('history', '历史')
      this.TabPill('settings', '设置')""",
]:
    text = text.replace(old_tabs, """      this.TabPill('search', '搜索')
      this.TabPill('shelf', '书架')
      this.TabPill('history', '历史')
      this.TabPill('settings', '设置')""")

if "name === 'history'" not in text:
    text = text.replace(
        """    } else if (name === 'settings') {
      Image($r('app.media.ic_settings')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())""",
        """    } else if (name === 'settings') {
      Image($r('app.media.ic_settings')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())
    } else if (name === 'history') {
      Image($r('app.media.ic_history')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())"""
    )

text = text.replace(
    """      } else if (this.activeTab === 'shelf') {
        this.ShelfPage()
      } else if (this.activeTab === 'settings') {
        this.SettingsPage()
      } else {
        this.AboutPage()
      }""",
    """      } else if (this.activeTab === 'shelf') {
        this.ShelfPage()
      } else if (this.activeTab === 'history') {
        this.HistoryPage()
      } else {
        this.SettingsPage()
      }"""
)

# Original clean SearchHome composition: no shortcuts, no settings entry, no mode chips.
search_home_block = r'''  @Builder
  private SearchHome() {
    Column() {
      Blank().layoutWeight(1)
      Column() {
        if (this.isDarkTheme()) {
          Image($r('app.media.search_home_illustration_dark'))
            .width(280)
            .height(122)
            .objectFit(ImageFit.Contain)
            .margin({ bottom: 18 })
        } else {
          Image($r('app.media.search_home_illustration_light'))
            .width(280)
            .height(122)
            .objectFit(ImageFit.Contain)
            .margin({ bottom: 18 })
        }
        Text('漫画浏览器')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.primaryText())
        Text('输入漫画名称，搜索公开可访问漫画')
          .fontSize(13)
          .fontColor(this.secondaryText())
          .margin({ top: 6, bottom: 22 })
        Row() {
          TextInput({ placeholder: this.t('searchPlaceholder'), text: this.queryText })
            .height(52)
            .layoutWeight(1)
            .fontSize(15)
            .backgroundColor(this.cardBg())
            .borderRadius(26)
            .padding({ left: 18, right: 18 })
            .onChange((value: string) => { this.queryText = value; })
            .onSubmit(() => { this.startSearch(); })
          Button(this.t('search'))
            .height(52)
            .fontSize(15)
            .fontColor('#FFFFFF')
            .backgroundColor(this.accent())
            .borderRadius(26)
            .margin({ left: 10 })
            .enabled(!this.isLoading)
            .onClick(() => { this.startSearch(); })
        }
        .width('100%')
        .padding({ left: 22, right: 22 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      Blank().layoutWeight(1)
    }
    .layoutWeight(1)
    .backgroundColor(this.appBg())
  }

'''
text = replace_between(text, "  @Builder\n  private SearchHome() {", "  @Builder\n  private SearchChip(keyword: string) {", search_home_block)

# Result helpers and list-only cards.
result_block = r'''  private cleanResultTitle(raw: string): string {
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
    return title;
  }

  private cleanResultTitleBySeparator(raw: string, separator: string): string {
    if (raw.indexOf(separator) < 0) return raw;
    let parts = raw.split(separator);
    let compactParts: string[] = [];
    for (let index = 0; index < parts.length; index++) {
      let part = parts[index].trim();
      if (part.length > 0 && (compactParts.length === 0 || compactParts[compactParts.length - 1] !== part)) {
        compactParts.push(part);
      }
    }
    return compactParts.join(separator);
  }

  private resultTitle(item: SearchResultItem): string { return this.cleanResultTitle(item.title); }
  private resultAuthor(item: SearchResultItem): string { return item.author !== undefined && item.author.length > 0 ? item.author : '未知作者'; }
  private resultLatestChapter(item: SearchResultItem): string {
    if (item.latestChapter !== undefined && item.latestChapter.length > 0) return item.latestChapter;
    if (item.isChapter) return this.resultTitle(item);
    return '最新章节待获取';
  }
  private resultUpdateTime(item: SearchResultItem): string { return item.updateTime !== undefined && item.updateTime.length > 0 ? item.updateTime : '更新时间待获取'; }
  private resultSourceHost(item: SearchResultItem): string {
    let host = item.url;
    let protocolIndex = host.indexOf('://');
    if (protocolIndex >= 0) host = host.substring(protocolIndex + 3);
    let slashIndex = host.indexOf('/');
    if (slashIndex >= 0) host = host.substring(0, slashIndex);
    let questionIndex = host.indexOf('?');
    if (questionIndex >= 0) host = host.substring(0, questionIndex);
    return host.length > 0 ? host : item.sourceName;
  }

  @Builder
  private ResultCard(item: SearchResultItem) {
    this.ResultListCard(item)
  }

  @Builder
  private ResultListCard(item: SearchResultItem) {
    Row() {
      Column() { this.CoverBox(item, 104) }
        .width(76)
        .height(104)
        .clip(true)
        .borderRadius(12)
      Column() {
        Text(this.resultTitle(item)).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
        Text('作者：' + this.resultAuthor(item)).fontSize(12).fontColor(this.secondaryText()).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 5 }).width('100%')
        Text('最新章节：' + this.resultLatestChapter(item)).fontSize(12).fontColor(this.secondaryText()).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 4 }).width('100%')
        Text('更新时间：' + this.resultUpdateTime(item)).fontSize(12).fontColor(this.secondaryText()).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 4 }).width('100%')
        Row() {
          Text('漫画').fontSize(11).fontColor('#FFFFFF').padding({ left: 8, right: 8, top: 3, bottom: 3 }).backgroundColor(this.accent()).borderRadius(10)
          Text(this.resultSourceHost(item)).fontSize(11).fontColor(this.secondaryText()).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1).margin({ left: 8 })
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
  private ResultGroupView(group: ResultGroup) {
    Column() {
      ForEach(group.items, (item: SearchResultItem) => { this.ResultListCard(item) }, (item: SearchResultItem) => item.url)
    }.width('100%')
  }

'''
text = replace_between(text, "  @Builder\n  private ResultCard(item: SearchResultItem) {", "  @Builder\n  private ResultsPage() {", result_block)

results_page_block = r'''  @Builder
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
            Text('默认列表显示，分类推荐已移动到书架。')
              .fontSize(12)
              .fontColor(this.secondaryText())
              .margin({ top: 3 })
          }.layoutWeight(1)
        }.width('100%').margin({ bottom: 8 })
        this.StatusCard()
        if (this.results.length === 0) {
          Text(this.isLoading ? '正在搜索公开来源...' : '没有找到结果，换个关键词试试。')
            .fontSize(14).fontColor(this.secondaryText()).width('100%').padding(12).backgroundColor(this.cardBg()).borderRadius(10)
        } else {
          ForEach(this.results, (item: SearchResultItem) => { this.ResultListCard(item) }, (item: SearchResultItem) => item.url)
        }
      }.width('100%').padding(14)
    }
    .layoutWeight(1)
    .backgroundColor(this.appBg())
  }

'''
text = replace_between(text, "  @Builder\n  private ResultsPage() {", "  @Builder\n  private ChaptersPage() {", results_page_block)

# Keep shelf wording aligned with classification responsibility.
text = text.replace('热门题材', '分类')
text = text.replace('这里将自动更新热门题材推荐，点击题材后进入搜索。收藏、历史和下载已统一放到历史页。', '分类和热门题材统一放在这里，点击题材后进入搜索。收藏、历史和下载已统一放到历史页。')
text = text.replace('后续会从规则仓库热门题材索引自动更新；当前先提供常用题材入口。', '后续会从规则仓库热门题材索引自动更新；当前先提供常用分类入口。')
text = text.replace('后续会从规则仓库热门题材索引自动更新；当前先提供常用分类入口。', '后续会从规则仓库热门题材索引自动更新；当前先提供常用分类入口。')

# Settings/About minimal enforcement. If compact settings already exists, keep it.
if "this.SettingMenuCard('关于'" not in text and "private SettingsMenuPage()" in text:
    text = text.replace(
        "    this.SettingMenuCard('高级规则', '查看内置规则源，粘贴自定义 JSON 规则。', this.rules.length + ' 个源', 'advanced')",
        "    this.SettingMenuCard('高级规则', '查看内置规则源，粘贴自定义 JSON 规则。', this.rules.length + ' 个源', 'advanced')\n    this.SettingMenuCard('关于', '版本、构建信息、界面风格和项目说明。', APP_VERSION, 'about')"
    )

# Validations.
required_index = [
    "@State private resultViewMode: string = 'list';",
    "app.media.search_home_illustration_light",
    "app.media.search_home_illustration_dark",
    "输入漫画名称，搜索公开可访问漫画",
    "private resultSourceHost(item: SearchResultItem): string",
    "作者：' + this.resultAuthor(item)",
    "最新章节：' + this.resultLatestChapter(item)",
    "更新时间：' + this.resultUpdateTime(item)",
    "ForEach(this.results, (item: SearchResultItem)",
]
for required in required_index:
    if required not in text:
        raise SystemExit(f'UI polish missing required content: {required}')

for forbidden in ["this.TabPill('about'", "Button('列表')", "Button('网格')", "ForEach(this.groupedResults()", "this.SearchChip('斗罗大陆')"]:
    if forbidden in text:
        raise SystemExit(f'UI polish still contains forbidden content: {forbidden}')

for required in ['author?: string;', 'latestChapter?: string;', 'updateTime?: string;', 'category?: string;']:
    if required not in model_text:
        raise SystemExit(f'Model missing required field: {required}')

model_path.write_text(model_text, encoding='utf-8')
index_path.write_text(text, encoding='utf-8')
print('Unified UI polish applied to', index_path, 'and', model_path)
