#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Idempotent UI polish script for the target development branch.

This script is intentionally conservative. It only normalizes already-agreed UI
structure and cleans leftovers created by earlier text patches. The fixed
workflow runs this script from the target branch, never from main.
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


# Defaults: search result page uses image-first grid.
text = text.replace('@State private coverOnlyMode: boolean = false;', '@State private coverOnlyMode: boolean = true;')
text = text.replace('@State private resultColumns: number = 2;', '@State private resultColumns: number = 3;')
if "@State private resultViewMode: string = 'grid';" not in text:
    text = text.replace("@State private resultColumns: number = 3;", "@State private resultColumns: number = 3;\n  @State private resultViewMode: string = 'grid';")

# Clean malformed old SearchHome leftovers from earlier migration.
leftovers = [
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
]
for block in leftovers:
    text = text.replace(block, '\n')

# Ensure SearchHeader is only used after results, not on the clean search home.
text = text.replace(
    "if (this.activeTab === 'search' && this.mode !== 'reader' && this.mode !== 'rendered_reader' && this.mode !== 'chapters') {\n        this.SearchHeader()\n      }",
    "if (this.activeTab === 'search' && this.mode === 'results') {\n        this.SearchHeader()\n      }"
)

# Bottom tab final structure: Search / Shelf / History / Settings.
text = text.replace(
    """      this.TabPill('search', this.t('search'))
      this.TabPill('shelf', this.t('shelf'))
      this.TabPill('settings', this.t('settings'))
      this.TabPill('about', this.t('about'))""",
    """      this.TabPill('search', '搜索')
      this.TabPill('shelf', '书架')
      this.TabPill('history', '历史')
      this.TabPill('settings', '设置')"""
)
text = text.replace(
    """      this.TabPill('search', '搜索')
      this.TabPill('shelf', '书架')
      this.TabPill('settings', '设置')
      this.TabPill('about', '关于')""",
    """      this.TabPill('search', '搜索')
      this.TabPill('shelf', '书架')
      this.TabPill('history', '历史')
      this.TabPill('settings', '设置')"""
)

# Add history icon mapping if missing.
if "name === 'history'" not in text:
    text = text.replace(
        """    } else if (name === 'settings') {
      Image($r('app.media.ic_settings')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())""",
        """    } else if (name === 'settings') {
      Image($r('app.media.ic_settings')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())
    } else if (name === 'history') {
      Image($r('app.media.ic_history')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())"""
    )

# Build routing: About is folded into Settings, History has its own page.
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

# Result header: arrange controls only when results exist.
text = text.replace(
    """          Button(this.groupByName ? '已归类' : '不归类')
            .height(32)
            .fontSize(12)
            .onClick(() => { this.groupByName = !this.groupByName; })""",
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
          }"""
)

# Settings section title helper, used by Settings and History pages.
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

# History owns previous shelf/history functions: clear history, clear favorites, open/remove favorites, downloads placeholder.
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
text = replace_between(
    text,
    """  @Builder
  private HistoryPage() {""",
    """  @Builder
  private ShelfPage() {""",
    history_page
)

# Shelf becomes the hot-topic recommendation entry. It no longer displays favorites/history.
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
text = replace_between(
    text,
    """  @Builder
  private ShelfPage() {""",
    """  @Builder
  private SettingCard(title: string, desc: string, value: string) {""",
    shelf_page
)

# Off / disabled status should be gray, not green.
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

# Validate no known malformed migration leftovers remain.
for marker in ['LegacySearchHomeRemoved', 'SearchHomeOldUnusedAnchor']:
    if marker in text:
        raise SystemExit(f'Unexpected leftover marker still present: {marker}')

# Validate ShelfPage does not contain old favorites/history display content.
shelf_start = text.find('private ShelfPage()')
shelf_end = text.find('private SettingCard(', shelf_start)
shelf_body = text[shelf_start:shelf_end]
for forbidden in ['this.HistoryList(true)', '清书架', '清历史', '收藏网格']:
    if forbidden in shelf_body:
        raise SystemExit(f'ShelfPage still contains old content: {forbidden}')
for required in ['热门题材', '自动推荐', '刷新热门题材']:
    if required not in shelf_body:
        raise SystemExit(f'ShelfPage missing recommendation content: {required}')

# Validate HistoryPage owns the migrated functions.
history_start = text.find('private HistoryPage()')
history_end = text.find('private ShelfPage()', history_start)
history_body = text[history_start:history_end]
for required in ['清历史', '清收藏', "Button('打开')", "Button('移除')", '下载']:
    if required not in history_body:
        raise SystemExit(f'HistoryPage missing migrated function: {required}')

path.write_text(text, encoding='utf-8')
print('UI polish cleanup applied to', path)
