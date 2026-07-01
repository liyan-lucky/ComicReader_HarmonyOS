#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Unified idempotent UI polish script.

Do not add one-off UI patch scripts. Keep all UI polish here.

This script is intentionally idempotent. It rewrites the known UI regions instead
of appending duplicate builders/helpers.
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

# Result helpers/list cards. Replace from the first helper, not ResultCard, to remove old duplicates.
result_region = r'''  private cleanResultTitle(raw: string): string {
    let title = raw.trim();
    while (title.indexOf('  ') >= 0) title = title.replace('  ', ' ');
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
      if (part.length > 0 && (compactParts.length === 0 || compactParts[compactParts.length - 1] !== part)) compactParts.push(part);
    }
    return compactParts.join(separator);
  }

  private metadataText(item: SearchResultItem): string {
    let text = item.title;
    if (item.description !== undefined && item.description.length > 0) text += ' ' + item.description;
    if (item.groupName !== undefined && item.groupName.length > 0) text += ' ' + item.groupName;
    text += ' ' + item.sourceName + ' ' + item.url;
    return text;
  }

  private pickAfterKeyword(text: string, keywords: string[]): string {
    for (let i = 0; i < keywords.length; i++) {
      let key = keywords[i];
      let index = text.indexOf(key);
      if (index < 0) continue;
      let value = text.substring(index + key.length).trim();
      if (value.indexOf('：') === 0 || value.indexOf(':') === 0) value = value.substring(1).trim();
      let stops = [' ', '　', '，', ',', '。', '；', ';', '|', '｜', '/', '\n', '\t'];
      let cut = value.length;
      for (let j = 0; j < stops.length; j++) {
        let stopIndex = value.indexOf(stops[j]);
        if (stopIndex >= 0 && stopIndex < cut) cut = stopIndex;
      }
      value = value.substring(0, cut).trim();
      if (value.length > 0 && value.length <= 32) return value;
    }
    return '';
  }

  private extractAuthor(item: SearchResultItem): string {
    if (item.author !== undefined && item.author.length > 0) return item.author;
    return this.pickAfterKeyword(this.metadataText(item), ['作者', '原作', 'Author', 'author', 'By ', 'by ']);
  }

  private extractLatestChapter(item: SearchResultItem): string {
    if (item.latestChapter !== undefined && item.latestChapter.length > 0) return item.latestChapter;
    let text = this.metadataText(item);
    let fromKeyword = this.pickAfterKeyword(text, ['最新章节', '最新话', '更新至', '连载至', 'Last Chapter', 'Chapter']);
    if (fromKeyword.length > 0) return fromKeyword;
    if (item.isChapter) return this.resultTitle(item);
    return '';
  }

  private extractUpdateTime(item: SearchResultItem): string {
    if (item.updateTime !== undefined && item.updateTime.length > 0) return item.updateTime;
    let text = this.metadataText(item);
    let fromKeyword = this.pickAfterKeyword(text, ['更新时间', '更新', 'Updated', 'updated']);
    if (fromKeyword.length > 0) return fromKeyword;
    return '';
  }

  private enrichResultItem(item: SearchResultItem): SearchResultItem {
    return {
      title: item.title,
      url: item.url,
      cover: item.cover,
      sourceId: item.sourceId,
      sourceName: item.sourceName,
      isChapter: item.isChapter,
      resultType: item.resultType,
      groupName: item.groupName,
      description: item.description,
      author: this.extractAuthor(item),
      latestChapter: this.extractLatestChapter(item),
      updateTime: this.extractUpdateTime(item),
      category: item.category !== undefined ? item.category : '漫画'
    };
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
  private ResultCard(item: SearchResultItem) { this.ResultListCard(item) }

  @Builder
  private ResultListCard(item: SearchResultItem) {
    Row() {
      Column() { this.CoverBox(item, 104) }.width(76).height(104).clip(true).borderRadius(12)
      Column() {
        Text(this.resultTitle(item)).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryText()).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
        Text('作者：' + this.resultAuthor(item)).fontSize(12).fontColor(this.secondaryText()).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 5 }).width('100%')
        Text('最新章节：' + this.resultLatestChapter(item)).fontSize(12).fontColor(this.secondaryText()).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 4 }).width('100%')
        Text('更新时间：' + this.resultUpdateTime(item)).fontSize(12).fontColor(this.secondaryText()).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 4 }).width('100%')
        Row() {
          Text(item.category !== undefined && item.category.length > 0 ? item.category : '漫画').fontSize(11).fontColor('#FFFFFF').padding({ left: 8, right: 8, top: 3, bottom: 3 }).backgroundColor(this.accent()).borderRadius(10)
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
    Column() { ForEach(group.items, (item: SearchResultItem) => { this.ResultListCard(item) }, (item: SearchResultItem) => item.url) }.width('100%')
  }

'''
text = replace_between(text, "  private cleanResultTitle(raw: string): string {", "  @Builder\n  private ResultsPage() {", result_region)

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

append_results_block = r'''  private appendResults(sourceItems: SearchResultItem[]): void {
    const next: SearchResultItem[] = [];
    for (let i = 0; i < this.results.length; i++) {
      next.push(this.enrichResultItem(this.results[i]));
    }
    for (let j = 0; j < sourceItems.length; j++) {
      if (next.length >= this.maxSearchResults) break;
      const item = this.enrichResultItem(sourceItems[j]);
      if (!this.resultMatchesSourceFilter(item)) continue;
      if (!next.some((oldItem: SearchResultItem) => oldItem.url === item.url || (oldItem.sourceName === item.sourceName && oldItem.title === item.title))) {
        next.push(item);
      }
    }
    this.results = next;
  }

'''
text = replace_between(text, "  private appendResults(sourceItems: SearchResultItem[]): void {", "  private updateResultCover(url: string, cover: string): void {", append_results_block)

update_cover_block = r'''  private updateResultCover(url: string, cover: string): void {
    const next: SearchResultItem[] = [];
    for (let i = 0; i < this.results.length; i++) {
      const item = this.results[i];
      if (item.url === url) {
        next.push(this.enrichResultItem({
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
        }));
      } else {
        next.push(this.enrichResultItem(item));
      }
    }
    this.results = next;
  }

'''
text = replace_between(text, "  private updateResultCover(url: string, cover: string): void {", "  private async searchSelectedEngines(keyword: string): Promise<void> {", update_cover_block)

# Keep shelf wording aligned with classification responsibility.
text = text.replace('这里将自动更新热门题材推荐，点击题材后进入搜索。收藏、历史和下载已统一放到历史页。', '分类和热门题材统一放在这里，点击题材后进入搜索。收藏、历史和下载已统一放到历史页。')
text = text.replace('后续会从规则仓库热门题材索引自动更新；当前先提供常用题材入口。', '后续会从规则仓库热门题材索引自动更新；当前先提供常用分类入口。')

# Fixed list mode should not be exposed as a selectable setting.
text = text.replace(
    "this.SettingMenuCard('显示与阅读', '结果展示、封面补全、卷轴阅读和历史保留。', this.resultViewMode === 'grid' ? '网格' : '列表', 'reader')",
    "this.SettingMenuCard('显示与阅读', '封面补全、卷轴阅读、页码和历史保留。', '阅读设置', 'reader')"
)
text = text.replace("    Column() { this.SettingCard('列表样式', '搜索结果固定为列表显示。', '列表') }.onClick(() => { this.resultViewMode = 'list'; })\n", '')
text = text.replace("    Column() { this.SettingCard('按名称归类', '搜索页不再分类，分类统一放到书架。', '已移至书架') }.onClick(() => { this.groupByName = false; })\n", '')

# Settings/About minimal enforcement. If compact settings already exists, keep it.
if "this.SettingMenuCard('关于'" not in text and "private SettingsMenuPage()" in text:
    text = text.replace(
        "    this.SettingMenuCard('高级规则', '查看内置规则源，粘贴自定义 JSON 规则。', this.rules.length + ' 个源', 'advanced')",
        "    this.SettingMenuCard('高级规则', '查看内置规则源，粘贴自定义 JSON 规则。', this.rules.length + ' 个源', 'advanced')\n    this.SettingMenuCard('关于', '版本、构建信息、界面风格和项目说明。', APP_VERSION, 'about')"
    )

# Validations: count helpers exactly once in the final text.
required_index = [
    "@State private resultViewMode: string = 'list';",
    "app.media.search_home_illustration_light",
    "app.media.search_home_illustration_dark",
    "输入漫画名称，搜索公开可访问漫画",
    "private enrichResultItem(item: SearchResultItem): SearchResultItem",
    "private appendResults(sourceItems: SearchResultItem[]): void",
    "author: this.extractAuthor(item)",
    "latestChapter: this.extractLatestChapter(item)",
    "updateTime: this.extractUpdateTime(item)",
    "ForEach(this.results, (item: SearchResultItem)",
]
for required in required_index:
    if required not in text:
        raise SystemExit(f'UI polish missing required content: {required}')

exact_once = [
    "private cleanResultTitle(raw: string): string",
    "private cleanResultTitleBySeparator(raw: string, separator: string): string",
    "private resultTitle(item: SearchResultItem): string",
    "private enrichResultItem(item: SearchResultItem): SearchResultItem",
]
for marker in exact_once:
    count = text.count(marker)
    if count != 1:
        raise SystemExit(f'Expected exactly one {marker}, found {count}')

for forbidden in ["this.TabPill('about'", "Button('列表')", "Button('网格')", "ForEach(this.groupedResults()", "this.SearchChip('斗罗大陆')", "SettingCard('列表样式'", "SettingCard('按名称归类'", "this.resultViewMode === 'grid' ? '网格' : '列表'"]:
    if forbidden in text:
        raise SystemExit(f'UI polish still contains forbidden content: {forbidden}')

for required in ['author?: string;', 'latestChapter?: string;', 'updateTime?: string;', 'category?: string;']:
    if required not in model_text:
        raise SystemExit(f'Model missing required field: {required}')

model_path.write_text(model_text, encoding='utf-8')
index_path.write_text(text, encoding='utf-8')
print('Unified UI polish applied to', index_path, 'and', model_path)
