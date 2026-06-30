#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from pathlib import Path

path = Path('entry/src/main/ets/pages/Index.ets')
text = path.read_text(encoding='utf-8')

# State defaults: search results use 3-column image grid by default.
text = text.replace("@State private coverOnlyMode: boolean = false;", "@State private coverOnlyMode: boolean = true;")
text = text.replace("@State private resultColumns: number = 2;", "@State private resultColumns: number = 3;")
if "@State private resultViewMode: string = 'grid';" not in text:
    text = text.replace("@State private resultColumns: number = 3;", "@State private resultColumns: number = 3;\n  @State private resultViewMode: string = 'grid';")

# Search home: center icon + one clean search area.
old_home_start = """  @Builder
  private SearchHome() {
    Scroll() {
      Column() {
        Column() {
          Text('今天想看什么漫画？')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.primaryText())
            .width('100%')
          Text('输入作品名，自动聚合公开来源并整理成封面列表。')
            .fontSize(13)
            .fontColor(this.secondaryText())
            .lineHeight(20)
            .width('100%')
            .margin({ top: 6 })
          Row() {
            this.SearchChip('斗罗大陆')
            this.SearchChip('火影忍者')
            this.SearchChip('one piece')
          }
          .width('100%')
          .margin({ top: 14 })
        }
        .width('100%')
        .padding(18)
        .backgroundColor(this.cardBg())
        .borderRadius(22)
        .margin({ top: 10, bottom: 14 })

        this.StatusCard()

        Text('最近阅读')"""
new_home_start = """  @Builder
  private SearchHome() {
    Column() {
      Blank().layoutWeight(1)
      Column() {
        Image($r('app.media.icon'))
          .width(92)
          .height(92)
          .margin({ bottom: 18 })
        Text('漫画浏览器')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.primaryText())
        Text('输入漫画名称，开始搜索公开资源')
          .fontSize(13)
          .fontColor(this.secondaryText())
          .margin({ top: 6, bottom: 20 })
        Row() {
          TextInput({ placeholder: this.t('searchPlaceholder'), text: this.queryText })
            .height(50)
            .layoutWeight(1)
            .fontSize(15)
            .backgroundColor(this.cardBg())
            .borderRadius(25)
            .padding({ left: 16, right: 16 })
            .onChange((value: string) => { this.queryText = value; })
            .onSubmit(() => { this.startSearch(); })
          Button(this.t('search'))
            .height(50)
            .fontSize(15)
            .fontColor('#FFFFFF')
            .backgroundColor(this.accent())
            .borderRadius(25)
            .margin({ left: 10 })
            .enabled(!this.isLoading)
            .onClick(() => { this.startSearch(); })
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
        Row() {
          this.SearchChip('斗罗大陆')
          this.SearchChip('火影忍者')
          this.SearchChip('one piece')
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .margin({ top: 16 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      Blank().layoutWeight(1)
    }
    .layoutWeight(1)
    .backgroundColor(this.appBg())
  }

  @Builder
  private LegacySearchHomeRemoved() {
    Text('')
  }

  @Builder
  private SearchHomeOldUnusedAnchor() {
    Text('最近阅读')"""
if old_home_start in text:
    # Replace only the first part, then remove old trailing body by a secondary cleanup below.
    text = text.replace(old_home_start, new_home_start, 1)

# If the old SearchHome body was transformed into dummy anchors, remove the leftover block by normalizing it.
old_leftover = """        this.HistoryList(false)
      }
      .width('100%')
      .padding(14)
    }
    .layoutWeight(1)
    .backgroundColor(this.appBg())
  }"""
if old_leftover in text and "private LegacySearchHomeRemoved" in text:
    text = text.replace(old_leftover, "      }\n  }", 1)

# More robust replacement if previous home still exists.
if "Text('搜索公开漫画资源')" in text:
    text = text.replace("Text('搜索公开漫画资源')", "Text('漫画浏览器')")

# Results page: show arrange toggle only when results exist, grid/list switch, 3-column image grid default.
if "private ResultListCard(item: SearchResultItem)" not in text:
    result_card_anchor = """  @Builder
  private ResultGroupView(group: ResultGroup) {"""
    list_card = """  @Builder
  private ResultListCard(item: SearchResultItem) {
    Row() {
      this.CoverBox(item, 108)
      Column() {
        Text(item.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.primaryText())
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(item.sourceName)
          .fontSize(12)
          .fontColor(this.secondaryText())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 6 })
        Button('阅读')
          .height(30)
          .fontSize(12)
          .fontColor('#FFFFFF')
          .backgroundColor(this.accent())
          .borderRadius(15)
          .margin({ top: 10 })
          .onClick(() => this.openSearchResult(item))
      }
      .layoutWeight(1)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(10)
    .backgroundColor(this.cardBg())
    .borderRadius(18)
    .margin({ bottom: 10 })
    .onClick(() => this.openSearchResult(item))
  }

"""
    if result_card_anchor in text:
        text = text.replace(result_card_anchor, list_card + result_card_anchor, 1)

text = text.replace(".columnsTemplate(this.resultColumns === 3 || this.coverOnlyMode ? '1fr 1fr 1fr' : '1fr 1fr')", ".columnsTemplate(this.resultColumns === 3 ? '1fr 1fr 1fr' : '1fr 1fr')")
old_grid = """      Grid() {
        ForEach(group.items, (item: SearchResultItem) => {
          GridItem() { this.ResultCard(item) }
        }, (item: SearchResultItem) => item.url)
      }
      .columnsTemplate(this.resultColumns === 3 ? '1fr 1fr 1fr' : '1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .width('100%')"""
new_grid = """      if (this.resultViewMode === 'list') {
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
        .columnsTemplate(this.resultColumns === 3 ? '1fr 1fr 1fr' : '1fr 1fr')
        .columnsGap(12)
        .rowsGap(12)
        .width('100%')
      }"""
if old_grid in text:
    text = text.replace(old_grid, new_grid, 1)

old_result_header_button = """          Button(this.groupByName ? '已归类' : '不归类')
            .height(32)
            .fontSize(12)
            .onClick(() => { this.groupByName = !this.groupByName; })"""
new_result_header_button = """          if (this.results.length > 0) {
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
if old_result_header_button in text:
    text = text.replace(old_result_header_button, new_result_header_button, 1)

# Shelf page: keep function, but no longer show收藏内容 there.
old_shelf_empty = """        Text('书架')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ top: 12, bottom: 6 })
        Text('搜索结果、章节页或阅读页可加入书架；书架会显示封面、名称、来源和最近阅读章节。')"""
new_shelf_empty = """        Text('书架')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ top: 12, bottom: 6 })
        Text('书架能力保留，收藏内容已移动到历史页的收藏记录中管理。')"""
text = text.replace(old_shelf_empty, new_shelf_empty)

# Add HistoryPage with history / favorites / downloads.
if "private HistoryPage()" not in text:
    history_anchor = """  @Builder
  private ShelfPage() {"""
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
            }
            .width('100%')
            .padding(14)
            .backgroundColor(this.cardBg())
            .borderRadius(16)
            .margin({ bottom: 8 })
            .onClick(() => this.loadChapterByUrl(item.lastChapterUrl.length > 0 ? item.lastChapterUrl : item.url, item.lastChapterTitle, ruleForPublicUrl(item.url, this.genericRule())))
          }, (item: BookshelfItem) => item.url)
        }

        this.SettingSectionTitle('下载', '下载能力暂时保留，后续接入离线章节。')
        Text('暂无下载任务。')
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
    if history_anchor in text:
        text = text.replace(history_anchor, history_page + history_anchor, 1)

# Merge About into Settings: keep AboutPage code but expose its core info inside Settings.
about_insert_anchor = """        Text('GitHub 远程规则')"""
about_block = """        this.SettingSectionTitle('关于', '版本、构建和界面信息。')
        Column() {
          this.AboutInfoRow('版本', APP_VERSION)
          this.AboutInfoRow('versionCode', APP_VERSION_CODE + '')
          this.AboutInfoRow('构建类型', APP_BUILD_TYPE)
          this.AboutInfoRow('构建目标', APP_BUILD_TARGET)
          this.AboutInfoRow('构建时间', APP_BUILD_TIME)
        }
        .width('100%')
        .padding(14)
        .backgroundColor(this.cardBg())
        .borderRadius(18)
        .margin({ bottom: 12 })

"""
if about_insert_anchor in text and "this.AboutInfoRow('版本', APP_VERSION)" not in text:
    text = text.replace(about_insert_anchor, about_block + about_insert_anchor, 1)

# UiIcon and BottomTabs: search / shelf / history / settings. About removed from tab.
old_about_icon = """    } else if (name === 'about') {
      Image($r('app.media.ic_about')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())"""
new_history_icon = """    } else if (name === 'history') {
      Image($r('app.media.ic_history')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())
    } else if (name === 'about') {
      Image($r('app.media.ic_about')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())"""
if old_about_icon in text and "name === 'history'" not in text:
    text = text.replace(old_about_icon, new_history_icon, 1)

text = text.replace("""      this.TabPill('search', this.t('search'))
      this.TabPill('shelf', this.t('shelf'))
      this.TabPill('settings', this.t('settings'))
      this.TabPill('about', this.t('about'))""", """      this.TabPill('search', '搜索')
      this.TabPill('shelf', '书架')
      this.TabPill('history', '历史')
      this.TabPill('settings', '设置')""")

text = text.replace("""      if (this.activeTab === 'search' && (this.mode === 'chapters' || this.mode === 'reader' || this.mode === 'rendered_reader')) {""", """      if (tab === 'search' && (this.mode === 'chapters' || this.mode === 'reader' || this.mode === 'rendered_reader')) {""")

old_build = """      if (this.activeTab === 'search' && this.mode !== 'reader' && this.mode !== 'rendered_reader' && this.mode !== 'chapters') {
        this.SearchHeader()
      }"""
new_build = """      if (this.activeTab === 'search' && this.mode === 'results') {
        this.SearchHeader()
      }"""
text = text.replace(old_build, new_build)

text = text.replace("""      } else if (this.activeTab === 'shelf') {
        this.ShelfPage()
      } else if (this.activeTab === 'settings') {
        this.SettingsPage()
      } else {
        this.AboutPage()
      }""", """      } else if (this.activeTab === 'shelf') {
        this.ShelfPage()
      } else if (this.activeTab === 'history') {
        this.HistoryPage()
      } else {
        this.SettingsPage()
      }""")

# Settings page polish if not already applied.
old_setting_value = """        Text(value)
          .fontSize(12)
          .fontColor('#FFFFFF')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(this.accent())
          .borderRadius(14)"""
new_setting_value = """        Text(value)
          .fontSize(12)
          .fontColor((value === '关' || value === '停用') ? this.secondaryText() : '#FFFFFF')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor((value === '关' || value === '停用') ? (this.isDarkTheme() ? '#2A333D' : '#EEF1F4') : this.accent())
          .borderRadius(14)"""
text = text.replace(old_setting_value, new_setting_value)

section_anchor = """  @Builder
  private SettingsPage() {"""
section_builder = """  @Builder
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

"""
if 'private SettingSectionTitle(title: string, desc: string)' not in text:
    text = text.replace(section_anchor, section_builder + section_anchor, 1)

for old, new in {
"""        Text('外观与语言')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.primaryText())
          .width('100%')
          .margin({ bottom: 8 })""": """        this.SettingSectionTitle('基础设置', '主题、语言与阅读页悬浮控制。')""",
"""        Text('搜索引擎')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .margin({ bottom: 8 })""": """        this.SettingSectionTitle('搜索设置', '控制默认搜索方式、语言倾向和搜索引擎。')""",
"""        Text('公开源开关')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .margin({ bottom: 8 })""": """        this.SettingSectionTitle('公开源开关', '选择参与搜索的公开 API、馆藏和 HTML 规则源。')""",
"""        Text('显示与阅读')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .margin({ top: 10, bottom: 8 })""": """        this.SettingSectionTitle('显示与阅读', '控制结果卡片、卷轴阅读器和历史保留。')""",
"""        Text('搜索引擎清单')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .margin({ top: 10, bottom: 8 })""": """        this.SettingSectionTitle('搜索引擎清单', '点击卡片切换当前搜索引擎，按钮用于启用或停用。')""",
"""        Text('GitHub 远程规则')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .margin({ top: 10, bottom: 8 })""": """        this.SettingSectionTitle('远程规则', '从可信 GitHub index.json 拉取公开源规则，失败时保留内置规则。')""",
"""        Text('公开HTML源规则')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .margin({ top: 10, bottom: 8 })""": """        this.SettingSectionTitle('高级规则', '展示当前公开 HTML 源，也可以粘贴自定义 JSON 规则。')"""
}.items():
    text = text.replace(old, new)

path.write_text(text, encoding='utf-8')
print('Navigation and layout polish applied to', path)
