#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Idempotent UI polish script for the target development branch.

Goals:
- Bottom tabs: 搜索 / 书架 / 历史 / 设置
- Search home stays clean; search header only appears on result page
- Search results: list/grid only; grid fixed to 3 columns; compact list cards
- Display-only title cleanup for repeated long names
- Shelf becomes hot-topic recommendation entry
- History owns history / favorites / download placeholders
"""
from pathlib import Path

path = Path('entry/src/main/ets/pages/Index.ets')
text = path.read_text(encoding='utf-8')


def replace_between(source: str, start: str, end: str, replacement: str) -> str:
    start_index = source.find(start)
    if start_index < 0:
        return source
    end_index = source.find(end, start_index)
    if end_index < 0:
        raise SystemExit(f'End anchor not found after {start!r}: {end!r}')
    return source[:start_index] + replacement + source[end_index:]


# Defaults: search result page uses image-first 3-column grid.
text = text.replace('@State private coverOnlyMode: boolean = false;', '@State private coverOnlyMode: boolean = true;')
text = text.replace('@State private resultColumns: number = 2;', '@State private resultColumns: number = 3;')
if "@State private resultViewMode: string = 'grid';" not in text:
    text = text.replace("@State private resultColumns: number = 3;", "@State private resultColumns: number = 3;\n  @State private resultViewMode: string = 'grid';")

# Clean old malformed migration leftovers.
for marker_block in [
    """
  @Builder
  private LegacySearchHomeRemoved() {
    Text('')
  }

  @Builder
  private SearchHomeOldUnusedAnchor() {
    Text('最近阅读')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .margin({ bottom: 8 })
      }
  }
""",
    """
  @Builder
  private LegacySearchHomeRemoved() {
    Text('')
  }
""",
]:
    text = text.replace(marker_block, '\n')

# Search header only appears on the result page.
text = text.replace(
    "if (this.activeTab === 'search' && this.mode !== 'reader' && this.mode !== 'rendered_reader' && this.mode !== 'chapters') {\n        this.SearchHeader()\n      }",
    "if (this.activeTab === 'search' && this.mode === 'results') {\n        this.SearchHeader()\n      }"
)

# Bottom tab final structure.
for old_tabs in [
    """      this.TabPill('search', this.t('search'))
      this.TabPill('shelf', this.t('shelf'))
      this.TabPill('settings', this.t('settings'))
      this.TabPill('about', this.t('about'))""",
    """      this.TabPill('search', '搜索')
      this.TabPill('shelf', '书架')
      this.TabPill('settings', '设置')
      this.TabPill('about', '关于')""",
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

# Result view switch: only list/grid, visible only when results exist.
for old_switch in [
    """          if (this.results.length > 0) {
            Button(this.resultViewMode === 'grid' ? '网格' : '列表')
              .height(32)
              .fontSize(12)
              .fontColor('#FFFFFF')
              .backgroundColor(this.accent())
              .borderRadius(16)
              .onClick(() => { this.resultViewMode = this.resultViewMode === 'grid' ? 'list' : 'grid'; })
            Button(this.resultColumns === 3 ? '三列' : '两列')
              .height(32)
              .fontSize(12)
              .margin({ left: 8 })
              .onClick(() => { this.resultColumns = this.resultColumns === 3 ? 2 : 3; })
          }""",
    """          Button(this.groupByName ? '已归类' : '不归类')
            .height(32)
            .fontSize(12)
            .onClick(() => { this.groupByName = !this.groupByName; })""",
]:
    text = text.replace(old_switch, """          if (this.results.length > 0) {
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
          }""")

# Shared section title helper.
if 'private SettingSectionTitle(title: string, desc: string)' not in text:
    text = text.replace(
        """  @Builder
  private SettingsPage() {""",
        """  @Builder
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
  private SettingsPage() {"""
    )

result_card_block = """  private cleanResultTitle(raw: string): string {
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

"""
text = replace_between(text, """  @Builder
  private ResultCard(item: SearchResultItem) {""", """  @Builder
  private ResultsPage() {""", result_card_block)

history_page = """  @Builder
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

"""
text = replace_between(text, """  @Builder
  private HistoryPage() {""", """  @Builder
  private ShelfPage() {""", history_page)

shelf_page = """  @Builder
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

"""
text = replace_between(text, """  @Builder
  private ShelfPage() {""", """  @Builder
  private SettingCard(title: string, desc: string, value: string) {""", shelf_page)

text = text.replace(
    """        Text(value)
          .fontSize(12)
          .fontColor('#FFFFFF')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.accent())
          .borderRadius(14)""",
    """        Text(value)
          .fontSize(12)
          .fontColor((value === '关' || value === '停用') ? this.secondaryText() : '#FFFFFF')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor((value === '关' || value === '停用') ? (this.isDarkTheme() ? '#2A333D' : '#EEF1F4') : this.accent())
          .borderRadius(14)"""
)

for marker in ['LegacySearchHomeRemoved', 'SearchHomeOldUnusedAnchor']:
    if marker in text:
        raise SystemExit(f'Unexpected leftover marker still present: {marker}')

result_start = text.find('private cleanResultTitle(')
result_end = text.find('private ResultsPage()', result_start)
result_body = text[result_start:result_end]
for required in ['private cleanResultTitle(', 'private ResultListCard(', ".columnsTemplate('1fr 1fr 1fr')", 'height(94)', 'this.resultTitle(item)']:
    if required not in result_body:
        raise SystemExit(f'Result UI missing required content: {required}')
for forbidden in ['this.coverOnlyMode ? 150 : 185', "this.resultColumns === 3 ? '1fr 1fr 1fr' : '1fr 1fr'", "Button('书架')"]:
    if forbidden in result_body:
        raise SystemExit(f'Result UI still contains old content: {forbidden}')

shelf_start = text.find('private ShelfPage()')
shelf_end = text.find('private SettingCard(', shelf_start)
shelf_body = text[shelf_start:shelf_end]
for forbidden in ['this.HistoryList(true)', '清书架', '清历史', '收藏网格']:
    if forbidden in shelf_body:
        raise SystemExit(f'ShelfPage still contains old content: {forbidden}')
for required in ['热门题材', '自动推荐', '刷新热门题材']:
    if required not in shelf_body:
        raise SystemExit(f'ShelfPage missing recommendation content: {required}')

history_start = text.find('private HistoryPage()')
history_end = text.find('private ShelfPage()', history_start)
history_body = text[history_start:history_end]
for required in ['清历史', '清收藏', "Button('打开')", "Button('移除')", '下载']:
    if required not in history_body:
        raise SystemExit(f'HistoryPage missing migrated function: {required}')

path.write_text(text, encoding='utf-8')
print('UI polish cleanup applied to', path)
