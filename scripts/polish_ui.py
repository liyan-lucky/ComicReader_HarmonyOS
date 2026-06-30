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

path.write_text(text, encoding='utf-8')
print('UI polish applied to', path)
