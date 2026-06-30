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

path.write_text(text, encoding='utf-8')
print('UI polish cleanup applied to', path)
