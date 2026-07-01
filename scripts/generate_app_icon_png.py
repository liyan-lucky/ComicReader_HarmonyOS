#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Keep the uploaded PNG app icon as the source of truth.

The app icon is now committed as a real PNG file:
entry/src/main/resources/base/media/icon.png

This script no longer writes a bundled base64 fallback, because that previously
overrode the user's uploaded high-resolution icon with an old 128x128 icon.
It only removes `icon.svg` if present, avoiding `$media:icon` resource conflicts.
"""
from pathlib import Path

media_dir = Path('entry/src/main/resources/base/media')
icon_png = media_dir / 'icon.png'
icon_svg = media_dir / 'icon.svg'

if icon_svg.exists():
    icon_svg.unlink()
    print('Removed conflicting SVG icon:', icon_svg)

if not icon_png.exists():
    raise SystemExit('Missing entry/src/main/resources/base/media/icon.png. Please upload the approved PNG app icon.')

print('Keep uploaded PNG app icon:', icon_png)
