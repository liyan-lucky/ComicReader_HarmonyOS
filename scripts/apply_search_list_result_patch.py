#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Apply search result list-only layout.

Changes:
- Search result page no longer shows list/grid switch buttons.
- Search defaults to list mode.
- Search result classification/group display is removed from search page.
- List item layout: left cover, right title/author/latest chapter/update time/type + source host.
- Category/topic logic stays on Shelf page.
"""
from pathlib import Path

model_path = Path('entry/src/main/ets/model/ComicModels.ets')
index_path = Path('entry/src/main/ets/pages/Index.ets')

model_text = model_path.read_text(encoding='utf-8')
if 'author?: string;' not in model_text:
    model_text = model_text.replace(
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
    model_path.write_text(model_text, encoding='utf-8')

text = index_path.read_text(encoding='utf-8')


def replace_between(source: str, start: str, end: str, replacement: str) -> str:
    start_index = source.find(start)
    if start_index < 0:
        raise SystemExit(f'Start anchor not found: {start!r}')
    end_index = source.find(end, start_index)
    if end_index < 0:
        raise SystemExit(f'End anchor not found after {start!r}: {end!r}')
    return source[:start_index] + replacement + source[end_index:]

# Default to list mode.
text = text.replace("@State private resultViewMode: string = 'grid';", "@State private resultViewMode: string = 'list';")

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

  private resultAuthor(item: SearchResultItem): string {
    if (item.author !== undefined && item.author.length > 0) {
      return item.author;
    }
    return '未知作者';
  }

  private resultLatestChapter(item: SearchResultItem): string {
    if (item.latestChapter !== undefined && item.latestChapter.length > 0) {
      return item.latestChapter;
    }
    if (item.isChapter) {
      return this.resultTitle(item);
    }
    return '最新章节待获取';
  }

  private resultUpdateTime(item: SearchResultItem): string {
    if (item.updateTime !== undefined && item.updateTime.length > 0) {
      return item.updateTime;
    }
    return '更新时间待获取';
  }

  private resultSourceHost(item: SearchResultItem): string {
    let host = item.url;
    let protocolIndex = host.indexOf('://');
    if (protocolIndex >= 0) {
      host = host.substring(protocolIndex + 3);
    }
    let slashIndex = host.indexOf('/');
    if (slashIndex >= 0) {
      host = host.substring(0, slashIndex);
    }
    let questionIndex = host.indexOf('?');
    if (questionIndex >= 0) {
      host = host.substring(0, questionIndex);
    }
    if (host.length === 0) {
      return item.sourceName;
    }
    return host;
  }

  @Builder
  private ResultCard(item: SearchResultItem) {
    this.ResultListCard(item)
  }

  @Builder
  private ResultListCard(item: SearchResultItem) {
    Row() {
      Column() {
        this.CoverBox(item, 104)
      }
      .width(76)
      .height(104)
      .clip(true)
      .borderRadius(12)

      Column() {
        Text(this.resultTitle(item))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.primaryText())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text('作者：' + this.resultAuthor(item))
          .fontSize(12)
          .fontColor(this.secondaryText())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 5 })
          .width('100%')
        Text('最新章节：' + this.resultLatestChapter(item))
          .fontSize(12)
          .fontColor(this.secondaryText())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
          .width('100%')
        Text('更新时间：' + this.resultUpdateTime(item))
          .fontSize(12)
          .fontColor(this.secondaryText())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
          .width('100%')
        Row() {
          Text('漫画')
            .fontSize(11)
            .fontColor('#FFFFFF')
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor(this.accent())
            .borderRadius(10)
          Text(this.resultSourceHost(item))
            .fontSize(11)
            .fontColor(this.secondaryText())
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
            .margin({ left: 8 })
        }
        .width('100%')
        .margin({ top: 7 })
      }
      .layoutWeight(1)
      .margin({ left: 12 })
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
      ForEach(group.items, (item: SearchResultItem) => {
        this.ResultListCard(item)
      }, (item: SearchResultItem) => item.url)
    }
    .width('100%')
  }

'''

text = replace_between(
    text,
    "  @Builder\n  private ResultCard(item: SearchResultItem) {",
    "  @Builder\n  private ResultsPage() {",
    result_block,
)

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
          }
          .layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: 8 })

        this.StatusCard()

        if (this.results.length === 0) {
          Text(this.isLoading ? '正在搜索公开来源...' : '没有找到结果，换个关键词试试。')
            .fontSize(14)
            .fontColor(this.secondaryText())
            .width('100%')
            .padding(12)
            .backgroundColor(this.cardBg())
            .borderRadius(10)
        } else {
          ForEach(this.results, (item: SearchResultItem) => {
            this.ResultListCard(item)
          }, (item: SearchResultItem) => item.url)
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
    "  @Builder\n  private ResultsPage() {",
    "  @Builder\n  private ChaptersPage() {",
    results_page_block,
)

# Keep shelf wording aligned with classification/topic responsibility.
text = text.replace(
    "这里将自动更新热门题材推荐，点击题材后进入搜索。收藏、历史和下载已统一放到历史页。",
    "分类和热门题材统一放在这里，点击题材后进入搜索。收藏、历史和下载已统一放到历史页。"
)
text = text.replace(
    "后续会从规则仓库热门题材索引自动更新；当前先提供常用题材入口。",
    "后续会从规则仓库热门题材索引自动更新；当前先提供常用分类入口。"
)

for required in [
    "@State private resultViewMode: string = 'list';",
    "private resultSourceHost(item: SearchResultItem): string",
    "作者：' + this.resultAuthor(item)",
    "最新章节：' + this.resultLatestChapter(item)",
    "更新时间：' + this.resultUpdateTime(item)",
    "Text('漫画')",
    "ForEach(this.results, (item: SearchResultItem)",
    "分类和热门题材统一放在这里",
]:
    if required not in text:
        raise SystemExit(f'Search list patch missing: {required}')

for forbidden in [
    "Button('列表')",
    "Button('网格')",
    "ForEach(this.groupedResults()",
    ".columnsTemplate('1fr 1fr 1fr')\n        .columnsGap(10)\n        .rowsGap(12)\n        .width('100%')\n      }\n    }\n    .width('100%')\n    .margin({ bottom: 18 })",
]:
    if forbidden in text:
        raise SystemExit(f'Search result page still contains old list/grid/group UI: {forbidden}')

index_path.write_text(text, encoding='utf-8')
print('Search list-only result UI patch applied to', index_path)
