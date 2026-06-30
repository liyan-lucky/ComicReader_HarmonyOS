#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

media = Path('entry/src/main/resources/base/media')
media.mkdir(parents=True, exist_ok=True)

svg_base = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">{}</svg>\n'
icons = {
  'ic_search.svg': '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
  'ic_shelf.svg': '<path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M4 4.5A2.5 2.5 0 0 1 6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5z"/>',
  'ic_settings.svg': '<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.38a2 2 0 0 0-.73-2.73l-.15-.09a2 2 0 0 1-1-1.74v-.51a2 2 0 0 1 1-1.72l.15-.1a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/>',
  'ic_about.svg': '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>',
  'ic_back.svg': '<path d="m15 18-6-6 6-6"/>',
  'ic_add_shelf.svg': '<path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h7"/><path d="M17 3v6"/><path d="M14 6h6"/>',
  'ic_refresh.svg': '<path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"/><path d="M3 21v-5h5"/><path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"/><path d="M16 8h5V3"/>',
  'ic_more.svg': '<circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/><circle cx="5" cy="12" r="1"/>',
  'ic_theme.svg': '<circle cx="12" cy="12" r="4"/><path d="M12 2v2"/><path d="M12 20v2"/><path d="m4.93 4.93 1.41 1.41"/><path d="m17.66 17.66 1.41 1.41"/><path d="M2 12h2"/><path d="M20 12h2"/><path d="m6.34 17.66-1.41 1.41"/><path d="m19.07 4.93-1.41 1.41"/>',
  'ic_language.svg': '<path d="m5 8 6 6"/><path d="m4 14 6-6 2-3"/><path d="M2 5h12"/><path d="M7 2h1"/><path d="m22 22-5-10-5 10"/><path d="M14 18h6"/>'
}
for name, body in icons.items():
    (media / name).write_text(svg_base.format(body), encoding='utf-8')

p = Path('entry/src/main/ets/pages/Index.ets')
s = p.read_text(encoding='utf-8')

ui_icon = '''
  @Builder
  private UiIcon(name: string, selected: boolean, size: number) {
    if (name === 'search') {
      Image($r('app.media.ic_search')).width(size).height(size).fillColor(selected ? '#FFFFFF' : this.secondaryText())
    } else if (name === 'shelf') {
      Image($r('app.media.ic_shelf')).width(size).height(size).fillColor(selected ? '#FFFFFF' : this.secondaryText())
    } else if (name === 'settings') {
      Image($r('app.media.ic_settings')).width(size).height(size).fillColor(selected ? '#FFFFFF' : this.secondaryText())
    } else if (name === 'about') {
      Image($r('app.media.ic_about')).width(size).height(size).fillColor(selected ? '#FFFFFF' : this.secondaryText())
    } else if (name === 'back') {
      Image($r('app.media.ic_back')).width(size).height(size).fillColor('#FFFFFF')
    } else if (name === 'add-shelf') {
      Image($r('app.media.ic_add_shelf')).width(size).height(size).fillColor('#FFFFFF')
    } else if (name === 'refresh') {
      Image($r('app.media.ic_refresh')).width(size).height(size).fillColor('#FFFFFF')
    } else if (name === 'more') {
      Image($r('app.media.ic_more')).width(size).height(size).fillColor('#FFFFFF')
    }
  }
'''
if 'private UiIcon(name: string' not in s:
    marker = '\n  @Builder\n  private TabPill('
    if marker not in s:
        raise SystemExit('TabPill marker not found')
    s = s.replace(marker, ui_icon + marker)

old_tab_sig = "  private TabPill(tab: string, icon: string, label: string) {"
s = s.replace(old_tab_sig, "  private TabPill(tab: string, label: string) {")
old_icon_block = """      Text(icon)
        .fontSize(18)
        .fontColor(this.activeTab === tab ? '#FFFFFF' : this.secondaryText())
        .textAlign(TextAlign.Center)"""
if old_icon_block not in s:
    raise SystemExit('tab text icon block not found')
s = s.replace(old_icon_block, "      this.UiIcon(tab, this.activeTab === tab, 20)")
s = s.replace("      this.TabPill('search', '⌕', this.t('search'))", "      this.TabPill('search', this.t('search'))")
s = s.replace("      this.TabPill('shelf', '▣', this.t('shelf'))", "      this.TabPill('shelf', this.t('shelf'))")
s = s.replace("      this.TabPill('settings', '⚙', this.t('settings'))", "      this.TabPill('settings', this.t('settings'))")
s = s.replace("      this.TabPill('about', 'ⓘ', this.t('about'))", "      this.TabPill('about', this.t('about'))")

old_reader = """  @Builder
  private ReaderFloatingButton(text: string) {
    Text(text)
      .fontSize(14)
      .fontColor('#FFFFFF')
      .textAlign(TextAlign.Center)
      .width(44)
      .height(44)
      .backgroundColor('#88000000')
      .borderRadius(22)
  }
"""
new_reader = """  @Builder
  private ReaderFloatingButton(action: string) {
    Column() {
      if (action === 'back') {
        this.UiIcon('back', true, 22)
      } else if (action === 'add-shelf') {
        this.UiIcon('add-shelf', true, 22)
      } else if (action === 'refresh') {
        this.UiIcon('refresh', true, 22)
      } else {
        this.UiIcon('more', true, 22)
      }
    }
    .width(44)
    .height(44)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#88000000')
    .borderRadius(22)
  }
"""
if old_reader not in s:
    raise SystemExit('reader floating button block not found')
s = s.replace(old_reader, new_reader)
s = s.replace("this.ReaderFloatingButton('···')", "this.ReaderFloatingButton('more')")
s = s.replace("this.ReaderFloatingButton('‹')", "this.ReaderFloatingButton('back')")
s = s.replace("this.ReaderFloatingButton('＋')", "this.ReaderFloatingButton('add-shelf')")
s = s.replace("this.ReaderFloatingButton('↻')", "this.ReaderFloatingButton('refresh')")

for bad in ["'⌕'", "'▣'", "'⚙'", "'ⓘ'", "'‹'", "'＋'", "'↻'", "'···'"]:
    if bad in s:
        raise SystemExit('temporary character icon remains: ' + bad)

p.write_text(s, encoding='utf-8')

third = Path('THIRD_PARTY_NOTICES.md')
ts = third.read_text(encoding='utf-8')
old_table = """| 资源名 | ProIcons 集合 | 原作者/项目 | 许可证 | 来源页面 | 是否随 App 分发 |
| --- | --- | --- | --- | --- | --- |
| 待添加 | 待确认 | 待确认 | 待确认 | 待确认 | 是 |"""
new_table = """| 资源名 | ProIcons 集合 | 原作者/项目 | 许可证 | 来源页面 | 是否随 App 分发 |
| --- | --- | --- | --- | --- | --- |
| `ic_search.svg` | Lucide Icons | Lucide Icons and Contributors；Feather/Cole Bemis 派生图标 | ISC；部分 Feather 派生图标 MIT | `https://proicons.com/icon-collections/lucide-icons/`；`https://lucide.dev/license` | 是 |
| `ic_shelf.svg` | Lucide Icons | Lucide Icons and Contributors | ISC | `https://proicons.com/icon-collections/lucide-icons/`；`https://lucide.dev/license` | 是 |
| `ic_settings.svg` | Lucide Icons | Lucide Icons and Contributors | ISC | `https://proicons.com/icon-collections/lucide-icons/`；`https://lucide.dev/license` | 是 |
| `ic_about.svg` | Lucide Icons | Lucide Icons and Contributors；Feather/Cole Bemis 派生图标 | ISC；部分 Feather 派生图标 MIT | `https://proicons.com/icon-collections/lucide-icons/`；`https://lucide.dev/license` | 是 |
| `ic_back.svg` | Lucide Icons | Lucide Icons and Contributors；Feather/Cole Bemis 派生图标 | ISC；部分 Feather 派生图标 MIT | `https://proicons.com/icon-collections/lucide-icons/`；`https://lucide.dev/license` | 是 |
| `ic_add_shelf.svg` | Lucide Icons | Lucide Icons and Contributors | ISC | `https://proicons.com/icon-collections/lucide-icons/`；`https://lucide.dev/license` | 是 |
| `ic_refresh.svg` | Lucide Icons | Lucide Icons and Contributors | ISC | `https://proicons.com/icon-collections/lucide-icons/`；`https://lucide.dev/license` | 是 |
| `ic_more.svg` | Lucide Icons | Lucide Icons and Contributors；Feather/Cole Bemis 派生图标 | ISC；部分 Feather 派生图标 MIT | `https://proicons.com/icon-collections/lucide-icons/`；`https://lucide.dev/license` | 是 |
| `ic_theme.svg` | Lucide Icons | Lucide Icons and Contributors | ISC | `https://proicons.com/icon-collections/lucide-icons/`；`https://lucide.dev/license` | 是 |
| `ic_language.svg` | Lucide Icons | Lucide Icons and Contributors | ISC | `https://proicons.com/icon-collections/lucide-icons/`；`https://lucide.dev/license` | 是 |"""
if old_table in ts:
    ts = ts.replace(old_table, new_table)
elif 'ic_search.svg' not in ts:
    raise SystemExit('third party icon table marker not found')
license_block = """

## Lucide Icons 许可证摘录

Lucide Icons 使用 ISC License。部分从 Feather 项目派生的图标同时保留 Feather/Cole Bemis 的 MIT License 归属说明。

ISC 归属：Copyright (c) 2026 Lucide Icons and Contributors。
MIT 归属：Copyright (c) 2013-present Cole Bemis。

仓库仅分发上述 SVG 图标资源，不分发 Lucide 字体包、完整图标包或第三方品牌 Logo。
"""
if '## Lucide Icons 许可证摘录' not in ts:
    ts = ts.replace('\n## CI 依赖说明\n', license_block + '\n## CI 依赖说明\n')
third.write_text(ts, encoding='utf-8')

ui = Path('docs/UI.md')
us = ui.read_text(encoding='utf-8')
us = us.replace('所有 App 图标资源必须来自：\n\n```text\nhttps://proicons.com/\n```', '所有 App 图标资源必须来自 ProIcons。当前统一使用 ProIcons 上的 Lucide Icons SVG 集合：\n\n```text\nhttps://proicons.com/icon-collections/lucide-icons/\n```')
us = us.replace('Tab 图标必须使用 ProIcons 来源的 SVG，不使用字符图标长期替代。', 'Tab 图标使用 ProIcons / Lucide Icons 来源的 SVG，不使用字符图标长期替代。')
us = us.replace('阅读页悬浮按钮必须使用 ProIcons SVG 图标。', '阅读页悬浮按钮使用 ProIcons / Lucide Icons 来源的 SVG 图标。')
ui.write_text(us, encoding='utf-8')
PY

node - <<'NODE'
const fs = require('fs');
const index = fs.readFileSync('entry/src/main/ets/pages/Index.ets', 'utf8');
const required = ['ic_search','ic_shelf','ic_settings','ic_about','ic_back','ic_add_shelf','ic_refresh','ic_more'];
for (const marker of required) {
  if (!index.includes(marker)) throw new Error('Index missing icon marker: ' + marker);
}
for (const bad of ["'⌕'","'▣'","'⚙'","'ⓘ'","'‹'","'＋'","'↻'","'···'"]) {
  if (index.includes(bad)) throw new Error('temporary character icon remains: ' + bad);
}
NODE
