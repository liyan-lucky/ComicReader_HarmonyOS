#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Apply UI optimization patch for entry/src/main/ets/pages/Index.ets.

This script is intentionally kept as a deterministic text patch because Index.ets
is currently a very large single ArkTS file. It keeps the Settings tab/function,
makes the Search page search-only, locks the visible UI language to Chinese,
changes bottom-tab selection from green filled pill to green icon/text rendering,
and normalizes common red selected accents to the app green accent.
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

    # 2) Search header must contain search only: remove language/theme/settings-like controls.
    text = replace_once(
        text,
        "        Row() {\n"
        "          this.MiniPill('中', this.appLanguage === 'zh')\n"
        "          Text('|').fontSize(11).fontColor(this.mutedText()).margin({ left: 4, right: 4 })\n"
        "          this.MiniPill('EN', this.appLanguage === 'en')\n"
        "        }\n"
        "        .onClick(() => this.toggleLanguage())\n"
        "        .margin({ right: 8 })\n"
        "        Button(this.themeLabel())\n"
        "          .height(32)\n"
        "          .fontSize(11)\n"
        "          .onClick(() => this.toggleTheme())",
        "        // 搜索页只保留搜索功能，不放语言/主题/设置类入口。"
    )

    # 3) Remove search-page setting/status controls below the search box.
    text = replace_once(
        text,
        "\n\n      Row() {\n"
        "        Text(this.searchMode + ' · ' + this.sourceFilterMode + ' · ' + (this.searchAllEngines || this.searchMode === '全引擎+公开API' ? '全引擎' : this.selectedEngine().name) + ' · ' + this.totalSearchSourceCount() + '源')\n"
        "          .fontSize(12)\n"
        "          .fontColor(this.secondaryText())\n"
        "          .layoutWeight(1)\n"
        "        Button(this.coverOnlyMode ? '封面+名称' : '纯封面')\n"
        "          .height(30)\n"
        "          .fontSize(12)\n"
        "          .onClick(() => { this.coverOnlyMode = !this.coverOnlyMode; })\n"
        "        Button('演示')\n"
        "          .height(30)\n"
        "          .fontSize(12)\n"
        "          .margin({ left: 8 })\n"
        "          .onClick(() => this.runDemoSearch())\n"
        "      }\n"
        "      .width('100%')\n"
        "      .padding({ left: 14, right: 14, bottom: 10 })",
        ""
    )

    # 4) Search home: remove explanatory setting text and demo/settings shortcut row.
    text = replace_once(
        text,
        "        Text('使用设置中选择的现有搜索引擎，同时聚合公开API/公开HTML源；搜索发现页会按域名自动匹配专用规则。结果按名称归类，显示封面卡片，点击进入章节或卷轴阅读。')",
        "        Text('输入漫画名称后开始搜索，结果会按名称归类并支持卷轴阅读。')"
    )
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
        ""
    )

    # 5) Add a soft selected background helper after accent().
    text = replace_once(
        text,
        "  private accent(): string { return '#34C759'; }\n"
        "  private warnBg(): string { return this.isDarkTheme() ? '#332610' : '#FFF7E6'; }",
        "  private accent(): string { return '#34C759'; }\n"
        "  private selectedSoftBg(): string { return this.isDarkTheme() ? '#1F34C759' : '#1434C759'; }\n"
        "  private warnBg(): string { return this.isDarkTheme() ? '#332610' : '#FFF7E6'; }"
    )

    # 6) Convert Tab icon selected color from white-on-green to green-rendered icon.
    text = text.replace("fillColor(selected ? '#FFFFFF' : this.secondaryText())", "fillColor(selected ? this.accent() : this.secondaryText())")

    # Keep reader floating controls white, because they sit on dark image content.
    text = text.replace("Image($r('app.media.ic_back')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())", "Image($r('app.media.ic_back')).width(size).height(size).fillColor('#FFFFFF')")
    text = text.replace("Image($r('app.media.ic_add_shelf')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())", "Image($r('app.media.ic_add_shelf')).width(size).height(size).fillColor('#FFFFFF')")
    text = text.replace("Image($r('app.media.ic_refresh')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())", "Image($r('app.media.ic_refresh')).width(size).height(size).fillColor('#FFFFFF')")
    text = text.replace("Image($r('app.media.ic_more')).width(size).height(size).fillColor(selected ? this.accent() : this.secondaryText())", "Image($r('app.media.ic_more')).width(size).height(size).fillColor('#FFFFFF')")

    # 7) Bottom tabs: keep settings tab; selected text/icon green; no solid green fill.
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

    # 8) Normalize visible red selected/accent blocks to app green.
    text = text.replace("#E53935", "#34C759")
    text = text.replace("#FFF3F3", "#ECFFF1")

    INDEX.write_text(text, encoding="utf-8")
    print("UI optimization patch applied to", INDEX)


if __name__ == "__main__":
    main()
