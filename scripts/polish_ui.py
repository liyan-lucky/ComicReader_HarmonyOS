#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Stability sanitizer for develop.

Temporary safety pass after runtime crash report:
- Reduce background network/image work.
- Stop repeated full-array state rebuilds when image status does not change.
- Remove grouped result calculation from final search status.

Next source edits should replace full files directly instead of patching snippets.
"""
from pathlib import Path

index_path = Path('entry/src/main/ets/pages/Index.ets')
text = index_path.read_text(encoding='utf-8')

replacements = {
    "@State private enableRenderedWebFallback: boolean = true;": "@State private enableRenderedWebFallback: boolean = false;",
    "@State private autoCoverEnabled: boolean = true;": "@State private autoCoverEnabled: boolean = false;",
    "@State private maxSearchResults: number = 80;": "@State private maxSearchResults: number = 40;",
    "@State private maxCoverEnrich: number = 30;": "@State private maxCoverEnrich: number = 8;",
    "@State private maxReaderPagesSetting: number = 8;": "@State private maxReaderPagesSetting: number = 4;",
    "this.statusText = `已找到 ${this.results.length} 个条目，正在补全封面并按名称归类...`;": "this.statusText = `已找到 ${this.results.length} 个条目，正在补全封面...`;",
    "this.statusText = `搜索完成：${this.results.length} 个条目，归类为 ${this.groupedResults().length} 组。点击封面进入章节或卷轴阅读。`;": "this.statusText = `搜索完成：${this.results.length} 个条目。点击条目进入章节或卷轴阅读。`;",
    "const maxPages = Math.min(Math.max(ruleMax, this.maxReaderPagesSetting), 30);": "const maxPages = Math.min(Math.max(ruleMax, this.maxReaderPagesSetting), 8);",
}

for old, new in replacements.items():
    if old in text:
        text = text.replace(old, new)

old_mark = """  private markImage(index: number, status: string): void {
    const next: ReaderImageItem[] = [];
    for (let i = 0; i < this.images.length; i++) {
      const item = this.images[i];
      next.push(item.index === index ? { url: item.url, index: item.index, status: status } : item);
    }
    this.images = next;
  }
"""
new_mark = """  private markImage(index: number, status: string): void {
    let changed = false;
    const next: ReaderImageItem[] = [];
    for (let i = 0; i < this.images.length; i++) {
      const item = this.images[i];
      if (item.index === index) {
        if (item.status !== status) {
          changed = true;
          next.push({ url: item.url, index: item.index, status: status });
        } else {
          next.push(item);
        }
      } else {
        next.push(item);
      }
    }
    if (changed) {
      this.images = next;
    }
  }
"""
if old_mark in text:
    text = text.replace(old_mark, new_mark)

old_enrich = """  private async enrichResultCovers(maxCount: number): Promise<void> {
    const count = Math.min(maxCount, this.results.length);
    let done = 0;
    for (let i = 0; i < count; i++) {
      const item = this.results[i];
      if (item.cover.length > 0 || item.sourceId === internetArchiveSourceId() || item.sourceId === openLibrarySourceId() || item.sourceId === wikimediaSourceId() || item.sourceId === libraryOfCongressSourceId() || item.sourceId === pepperSourceId()) {
        continue;
      }
      const rule = this.ruleForItemUrl(item.url, item.sourceId);
      try {
        const html = await HttpClient.getText(item.url, rule.userAgent, rule.referer.length > 0 ? rule.referer : item.url);
        const parsedImages = parseImages(html, rule, item.url);
        if (parsedImages.length > 0) {
          this.updateResultCover(item.url, parsedImages[0].url);
          done++;
          this.statusText = `正在补全封面：已补全 ${done} 张，结果 ${this.results.length} 个。`;
        }
      } catch (err) {
      }
    }
  }
"""
new_enrich = """  private async enrichResultCovers(maxCount: number): Promise<void> {
    const count = Math.min(Math.min(maxCount, this.results.length), 8);
    let done = 0;
    for (let i = 0; i < count; i++) {
      if (!this.isLoading) {
        break;
      }
      const item = this.results[i];
      if (item.cover.length > 0 || item.sourceId === internetArchiveSourceId() || item.sourceId === openLibrarySourceId() || item.sourceId === wikimediaSourceId() || item.sourceId === libraryOfCongressSourceId() || item.sourceId === pepperSourceId()) {
        continue;
      }
      const rule = this.ruleForItemUrl(item.url, item.sourceId);
      try {
        const html = await HttpClient.getText(item.url, rule.userAgent, rule.referer.length > 0 ? rule.referer : item.url);
        const parsedImages = parseImages(html, rule, item.url);
        if (parsedImages.length > 0) {
          this.updateResultCover(item.url, parsedImages[0].url);
          done++;
          this.statusText = `正在补全封面：已补全 ${done} 张，结果 ${this.results.length} 个。`;
        }
      } catch (err) {
      }
    }
  }
"""
if old_enrich in text:
    text = text.replace(old_enrich, new_enrich)

old_merge = """  private mergeReaderImages(base: ReaderImageItem[], incoming: ReaderImageItem[]): ReaderImageItem[] {
    const next: ReaderImageItem[] = [];
    for (let i = 0; i < base.length; i++) {
      next.push({ url: base[i].url, index: next.length + 1, status: base[i].status });
    }
    for (let j = 0; j < incoming.length; j++) {
      const image = incoming[j];
      if (!this.dedupeImages || !next.some((oldItem: ReaderImageItem) => oldItem.url === image.url)) {
        next.push({ url: image.url, index: next.length + 1, status: 'waiting' });
      }
    }
    return next;
  }
"""
new_merge = """  private mergeReaderImages(base: ReaderImageItem[], incoming: ReaderImageItem[]): ReaderImageItem[] {
    const next: ReaderImageItem[] = [];
    for (let i = 0; i < base.length && next.length < 120; i++) {
      next.push({ url: base[i].url, index: next.length + 1, status: base[i].status });
    }
    for (let j = 0; j < incoming.length && next.length < 120; j++) {
      const image = incoming[j];
      if (!this.dedupeImages || !next.some((oldItem: ReaderImageItem) => oldItem.url === image.url)) {
        next.push({ url: image.url, index: next.length + 1, status: 'waiting' });
      }
    }
    return next;
  }
"""
if old_merge in text:
    text = text.replace(old_merge, new_merge)

required = [
    "@State private enableRenderedWebFallback: boolean = false;",
    "@State private autoCoverEnabled: boolean = false;",
    "@State private maxSearchResults: number = 40;",
    "@State private maxCoverEnrich: number = 8;",
    "@State private maxReaderPagesSetting: number = 4;",
    "const maxPages = Math.min(Math.max(ruleMax, this.maxReaderPagesSetting), 8);",
    "if (changed) {",
]
for item in required:
    if item not in text:
        raise SystemExit('Missing stability change: ' + item)

for forbidden in [
    "@State private autoCoverEnabled: boolean = true;",
    "@State private maxSearchResults: number = 80;",
    "@State private maxCoverEnrich: number = 30;",
    "const maxPages = Math.min(Math.max(ruleMax, this.maxReaderPagesSetting), 30);",
    "归类为 ${this.groupedResults().length} 组",
]:
    if forbidden in text:
        raise SystemExit('Forbidden unstable content remains: ' + forbidden)

index_path.write_text(text, encoding='utf-8')
print('Applied stability sanitizer to', index_path)
