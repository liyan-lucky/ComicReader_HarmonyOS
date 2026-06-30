#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Apply UI optimization patch for entry/src/main/ets/pages/Index.ets.

This script is intentionally kept as a deterministic text patch because Index.ets
is currently a very large single ArkTS file. It removes the visible Settings tab,
hides the home-page settings shortcut, locks the UI language to Chinese, changes
bottom-tab selection from green filled pill to green icon/text rendering, and
normalizes common red selected accents to the app green accent.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / "entry/src/main/ets/pages/Index.ets"


def replace_once(text: str, old: str, new: str) -> str:
    if old not in text:
        raise SystemExit(f"Patch anchor not found:\n{old[:240]}")
    return text.replace(old, new, 1)


def main() -> None:
    text = INDEX.read_text(encoding="utf-8")

    # 1) Lock visible UI language to Chinese and stop accidental English switching.
    text = text.replace("@State private appLanguage: string = 'zh';", "@State private appLanguage: string = 'zh';")
    text = replace_once(
        text,
        "  private toggleLanguage(): void {\n"
        "    this.appLanguage = this.appLanguage === 'en' ? 'zh' : 'en';\n"
        "    this.statusText = this.appLanguage === 'en' ? 'Language switched to English.' : '语言已切换为中文。';\n"
        "  }",
        "  private toggleLanguage(): void {\n"
        "    this.appLanguage = 'zh';\n"
        "    this.statusText = '界面语言已锁定为中文，避免误触后出现英文或中英文混排。';\n"
        "  }"
    )

    # 2) Remove visible language toggle from SearchHeader.
    text = replace_once(
        text,
        "        Row() {\n"
        "          this.MiniPill('中', this.appLanguage === 'zh')\n"
        "          Text('|').fontSize(11).fontColor(this.mutedText()).margin({ left: 4, right: 4 })\n"
        "          this.MiniPill('EN', this.appLanguage === 'en')\n"
        "        }\n"
        "        .onClick(() => this.toggleLanguage())\n"
        "        .margin({ right: 8 })\n"
        "        Button(this.themeLabel())",
        "        Button(this.themeLabel())"
    )

    # 3) Remove home-page settings shortcut.
    text = replace_once(
        text,
        "        Row() {\n"
        "          Button('搜索 little nemo')\n"
        "            .height(40)\n"
        "            .layoutWeight(1)\n"
        "            .fontSize(14)\n"
        "            .onClick(() => this.runDemoSearch())\n"
        "          Button('去设置引擎')\n"
        "            .height(40)\n"
        "            .layoutWeight(1)\n"
        "            .fontSize(14)\n"
        "            .margin({ left: 10 })\n"
        "            .onClick(() => { this.activeTab = 'settings'; })\n"
        "        }\n"
        "        .width('100%')\n"
        "        .margin({ bottom: 16 })",
        "        Button('搜索 little nemo')\n"
        "          .height(40)\n"
        "          .width('100%')\n"
        "          .fontSize(14)\n"
        "          .fontColor('#FFFFFF')\n"
        "          .backgroundColor(this.accent())\n"
        "          .borderRadius(20)\n"
        "          .onClick(() => this.runDemoSearch())\n"
        "          .margin({ bottom: 16 })"
    )

    # 4) Add a soft selected background helper after accent().
    text = replace_once(
        text,
        "  private accent(): string { return '#34C759'; }\n"
        "  private warnBg(): string { return this.isDarkTheme() ? '#332610' : '#FFF7E6'; }",
        "  private accent(): string { return '#34C759'; }\n"
        "  private selectedSoftBg(): string { return this.isDarkTheme() ? '#1F34C759' : '#1434C759'; }\n"
        "  private warnBg(): string { return this.isDarkTheme() ? '#332610' : '#FFF7E6'; }"
    )

    # 5) Convert Tab icon selected color from white-on-green to green-rendered icon.
    text = text.replace("fillColor(selected ? '#FFFFFF' : this.secondaryText())", "fillColor(selected ? this.accent() : this.secondaryText())")

    # Keep reader floating controls white, because they sit on dark image content.
    text = text.replace("Image($r('app.media.ic_back')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())", "Image($r('app.media.ic_back')).width(size).height(size).fillColor('#FFFFFF')")
    text = text.replace("Image($r('app.media.ic_add_shelf')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())", "Image($r('app.media.ic_add_shelf')).width(size).height(size).fillColor('#FFFFFF')")
    text = text.replace("Image($r('app.media.ic_refresh')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())", "Image($r('app.media.ic_refresh')).width(size).height(size).fillColor('#FFFFFF')")
    text = text.replace("Image($r('app.media.ic_more')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())", "Image($r('app.media.ic_more')).width(size).height(size).fillColor('#FFFFFF')")

    # 6) Bottom tabs: remove settings tab; selected text green; no green filled pill.
    text = replace_once(
        text,
        "        .fontColor(this.activeTab === tab ? '#FFFFFF' : this.secondaryText())",
        "        .fontColor(this.activeTab === tab ? this.accent() : this.secondaryText())"
    )
    text = replace_once(
        text,
        "    .backgroundColor(this.activeTab === tab ? this.accent() : '#00000000')",
        "    .backgroundColor(this.activeTab === tab ? this.selectedSoftBg() : '#00000000')"
    )
    text = replace_once(
        text,
        "      this.TabPill('search', this.t('search'))\n"
        "      this.TabPill('shelf', this.t('shelf'))\n"
        "      this.TabPill('settings', this.t('settings'))\n"
        "      this.TabPill('about', this.t('about'))",
        "      this.TabPill('search', this.t('search'))\n"
        "      this.TabPill('shelf', this.t('shelf'))\n"
        "      this.TabPill('about', this.t('about'))"
    )
    text = replace_once(
        text,
        "      } else if (this.activeTab === 'settings') {\n"
        "        this.SettingsPage()\n"
        "      } else {\n"
        "        this.AboutPage()\n"
        "      }",
        "      } else {\n"
        "        this.AboutPage()\n"
        "      }"
    )

    # 7) Normalize visible red selected/accent blocks to app green.
    text = text.replace("#E53935", "#34C759")
    text = text.replace("#FFF3F3", "#ECFFF1")

    INDEX.write_text(text, encoding="utf-8")
    print("UI optimization patch applied to", INDEX)


if __name__ == "__main__":
    main()
