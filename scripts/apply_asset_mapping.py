#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Apply PNG asset mapping for app icon and search-home illustration.

Expected resources:
- entry/src/main/resources/base/media/icon.png
- entry/src/main/resources/base/media/search_home_illustration_light.png
- entry/src/main/resources/base/media/search_home_illustration_dark.png

The module icon keeps using `$media:icon`.
The search home illustration switches between light/dark PNG resources.
"""
from pathlib import Path

index_path = Path('entry/src/main/ets/pages/Index.ets')
text = index_path.read_text(encoding='utf-8')

old_icon_block = """        Image($r('app.media.icon'))
          .width(92)
          .height(92)
          .margin({ bottom: 18 })"""

new_illustration_block = """        if (this.isDarkTheme()) {
          Image($r('app.media.search_home_illustration_dark'))
            .width(220)
            .height(96)
            .objectFit(ImageFit.Contain)
            .margin({ bottom: 18 })
        } else {
          Image($r('app.media.search_home_illustration_light'))
            .width(220)
            .height(96)
            .objectFit(ImageFit.Contain)
            .margin({ bottom: 18 })
        }"""

if old_icon_block in text:
    text = text.replace(old_icon_block, new_illustration_block)

# Keep the script idempotent if it has already been applied.
if "app.media.search_home_illustration_light" not in text:
    raise SystemExit('Search home light illustration resource was not applied.')
if "app.media.search_home_illustration_dark" not in text:
    raise SystemExit('Search home dark illustration resource was not applied.')
if old_icon_block in text:
    raise SystemExit('Search home still uses app icon instead of illustration.')

index_path.write_text(text, encoding='utf-8')
print('Search home PNG illustration mapping applied to', index_path)
