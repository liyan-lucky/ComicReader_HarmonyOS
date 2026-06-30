#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from pathlib import Path

path = Path('entry/src/main/ets/pages/Index.ets')
text = path.read_text(encoding='utf-8')

old_intro = """        Text('搜索公开漫画资源')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ top: 10, bottom: 6 })
        Text('输入漫画名称后开始搜索，结果会按名称归类并支持卷轴阅读。')
          .fontSize(13)
          .fontColor('#666666')
          .lineHeight(20)
          .width('100%')
          .margin({ bottom: 12 })
        this.StatusCard()

        Grid() {
          GridItem() { this.StepCard('1', '搜索引擎', 'DuckDuckGo/Bing/Google/Yandex/Brave/Google CSE 可切换') }
          GridItem() { this.StepCard('2', '公开源聚合', 'Internet Archive/Open Library/LOC/Wikimedia/规则源') }
          GridItem() { this.StepCard('3', '封面归类', '按名称分组，支持封面+名称或纯封面') }
          GridItem() { this.StepCard('4', '卷轴阅读', '章节图片提取、多页追踪、连续滚动') }
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(10)
        .rowsGap(10)
        .width('100%')
        .margin({ bottom: 16 })



        Text('最近阅读')"""
new_intro = """        Column() {
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

if old_intro in text:
    text = text.replace(old_intro, new_intro, 1)
elif '今天想看什么漫画？' not in text:
    raise SystemExit('search home intro anchor not found')

anchor = """  @Builder
  private StepCard(num: string, title: string, desc: string) {"""
insert = """  @Builder
  private SearchChip(keyword: string) {
    Text(keyword)
      .fontSize(12)
      .fontColor(this.accent())
      .padding({ left: 12, right: 12, top: 7, bottom: 7 })
      .backgroundColor(this.selectedSoftBg())
      .borderRadius(16)
      .margin({ right: 8 })
      .onClick(() => { this.queryText = keyword; this.startSearch(); })
  }

"""
if 'private SearchChip(keyword: string)' not in text:
    if anchor not in text:
        raise SystemExit('StepCard anchor not found')
    text = text.replace(anchor, insert + anchor, 1)

text = text.replace(".backgroundColor('#F7F7F7')", ".backgroundColor(this.appBg())")
text = text.replace(
    ".backgroundColor('#FFFFFF')\n    .borderRadius(12)\n    .onClick(() => this.openSearchResult(item))",
    ".backgroundColor(this.cardBg())\n    .borderRadius(18)\n    .shadow({ radius: 8, color: '#12000000', offsetX: 0, offsetY: 3 })\n    .onClick(() => this.openSearchResult(item))"
)
text = text.replace(".columnsGap(10)\n      .rowsGap(10)", ".columnsGap(12)\n      .rowsGap(12)")
text = text.replace("Text(this.isLoading ? '正在抓取公开源...' : '暂无结果。')", "Text(this.isLoading ? '正在搜索公开来源...' : '没有找到结果，换个关键词试试。')")

# Settings page: make section hierarchy clearer and make off states gray instead of green.
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
if old_setting_value in text:
    text = text.replace(old_setting_value, new_setting_value, 1)

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
    if section_anchor not in text:
        raise SystemExit('SettingsPage anchor not found')
    text = text.replace(section_anchor, section_builder + section_anchor, 1)

section_replacements = {
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
}
for old, new in section_replacements.items():
    text = text.replace(old, new)

# Theme-aware cards and inputs inside Settings.
text = text.replace(".backgroundColor('#FFFFFF')", ".backgroundColor(this.cardBg())")
text = text.replace(".fontColor('#666666')", ".fontColor(this.secondaryText())")
text = text.replace(".fontColor('#777777')", ".fontColor(this.secondaryText())")
text = text.replace(".fontColor('#888888')", ".fontColor(this.secondaryText())")
text = text.replace(".fontColor('#999999')", ".fontColor(this.secondaryText())")

path.write_text(text, encoding='utf-8')
print('UI polish applied to', path)
