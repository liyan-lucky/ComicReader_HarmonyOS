#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Move About content into Settings secondary menu.

The bottom tabs remain: 搜索 / 书架 / 历史 / 设置.
About becomes a Settings menu item and opens as a second-level Settings page.
"""
from pathlib import Path

path = Path('entry/src/main/ets/pages/Index.ets')
text = path.read_text(encoding='utf-8')

# The compact settings patch must run before this script.
if 'private SettingsMenuPage()' not in text or 'private SettingsDetailPage()' not in text:
    raise SystemExit('Settings menu patch must be applied before about-in-settings patch.')

menu_anchor = "    this.SettingMenuCard('高级规则', '查看内置规则源，粘贴自定义 JSON 规则。', this.rules.length + ' 个源', 'advanced')"
menu_replacement = menu_anchor + "\n    this.SettingMenuCard('关于', '版本、构建信息、界面风格和项目说明。', APP_VERSION, 'about')"
if "this.SettingMenuCard('关于'" not in text:
    if menu_anchor not in text:
        raise SystemExit('Settings menu advanced anchor not found.')
    text = text.replace(menu_anchor, menu_replacement)

about_page_block = r'''  @Builder
  private SettingsAboutPage() {
    this.SettingBackHeader('关于', '版本、构建信息、界面风格和项目说明。')
    Text(this.appLanguage === 'en' ? 'Public comic search and scroll reading for HarmonyOS / OpenHarmony.' : '漫画浏览器 HarmonyOS / OpenHarmony 公开漫画搜索与卷轴阅读项目。')
      .fontSize(13)
      .fontColor(this.secondaryText())
      .lineHeight(20)
      .width('100%')
      .padding(14)
      .backgroundColor(this.cardBg())
      .borderRadius(18)
      .margin({ bottom: 12 })

    Column() {
      Text(this.appLanguage === 'en' ? 'Build Info' : '构建信息')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.primaryText())
        .width('100%')
        .margin({ bottom: 8 })
      this.AboutInfoRow(this.appLanguage === 'en' ? 'Version' : '版本', APP_VERSION)
      this.AboutInfoRow(this.appLanguage === 'en' ? 'Version Rule' : '版本结构', this.appLanguage === 'en' ? 'major.full.incremental' : '主版本.全量构建号.增量构建号')
      this.AboutInfoRow('versionCode', APP_VERSION_CODE + '')
      this.AboutInfoRow(this.appLanguage === 'en' ? 'Build Type' : '构建类型', APP_BUILD_TYPE)
      this.AboutInfoRow(this.appLanguage === 'en' ? 'Build Target' : '构建目标', APP_BUILD_TARGET)
      this.AboutInfoRow(this.appLanguage === 'en' ? 'Build Time' : '构建时间', APP_BUILD_TIME)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.cardBg())
    .borderRadius(18)
    .margin({ bottom: 12 })

    Column() {
      Text(this.appLanguage === 'en' ? 'UI Style' : '界面风格')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.primaryText())
        .width('100%')
        .margin({ bottom: 8 })
      this.AboutInfoRow(this.t('theme'), this.themeLabel())
      this.AboutInfoRow(this.t('language'), this.languageLabel())
      this.AboutInfoRow(this.t('fullReader'), this.fullscreenReader ? 'ON' : 'OFF')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.cardBg())
    .borderRadius(18)
    .margin({ bottom: 20 })
  }

'''
if 'private SettingsAboutPage()' not in text:
    detail_anchor = "  @Builder\n  private SettingsDetailPage() {"
    if detail_anchor not in text:
        raise SystemExit('SettingsDetailPage anchor not found.')
    text = text.replace(detail_anchor, about_page_block + detail_anchor)

advanced_branch = """    } else if (this.settingsSection === 'advanced') {
      this.SettingsAdvancedPage()"""
about_branch = """    } else if (this.settingsSection === 'advanced') {
      this.SettingsAdvancedPage()
    } else if (this.settingsSection === 'about') {
      this.SettingsAboutPage()"""
if "this.settingsSection === 'about'" not in text:
    if advanced_branch not in text:
        raise SystemExit('SettingsDetailPage advanced branch not found.')
    text = text.replace(advanced_branch, about_branch)

# Make old standalone AboutPage unreachable by tabs but keep it as a harmless legacy builder.
# Bottom tabs are validated to remain four entries and not expose About.
if "this.TabPill('about'" in text:
    raise SystemExit('BottomTabs still exposes about tab.')
for required in [
    "this.SettingMenuCard('关于'",
    "private SettingsAboutPage()",
    "this.settingsSection === 'about'",
    "this.SettingsAboutPage()",
]:
    if required not in text:
        raise SystemExit(f'About settings patch missing: {required}')

path.write_text(text, encoding='utf-8')
print('About section moved into Settings menu in', path)
