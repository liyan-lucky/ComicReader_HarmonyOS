# 漫画浏览器 UI 规范

本文记录当前 App 的新版 UI 方向、源码固化目标和图标资源规则。

## 设计目标

- 参考 HarmonyOS 官方应用的清爽、圆角、胶囊化设计语言；
- 底部导航改为悬浮胶囊 Tab；
- 顶部搜索区使用半透明磨砂感过渡；
- 支持明亮 / 暗黑双主题；
- 支持中文 / English 双语言基础切换；
- 书架支持收藏搜索结果，并显示最近阅读章节、阅读时间、估算进度和阅读次数；
- 阅读页默认全屏，标题栏、返回、收藏、刷新等控制改为悬浮独立按钮；
- 所有 App 图标资源统一来自 ProIcons 上的开源图标集合，不自建设计图标。

## 实现方式要求

当前目标是把 UI 改造固化到：

```text
entry/src/main/ets/pages/Index.ets
```

正式构建不应依赖 UI 注入脚本动态改页面源码。`scripts/patch_about_page_ci.js` 和 `scripts/patch_modern_ui_ci.js` 只能作为历史迁移/对照工具，不应作为长期构建路径。

推荐源码固化流程：

```text
1. 备份原始 Index.ets
2. 直接修改 Index.ets
3. 构建脚本只负责版本信息和 CI SDK 兼容
4. 出错时对照备份文件修复
```

## 图标资源规则

所有应用内图标资源必须来自：

```text
https://proicons.com/
```

使用规则：

- 优先选择 SVG 图标；
- 优先选同一图标集合，保证线宽、圆角和视觉风格一致；
- 不允许自建图标、不允许用临时字符图标长期替代正式图标；
- 不允许从来源不明的网站、搜索结果图片或未授权 UI 包复制图标；
- 每个使用的图标集合必须记录集合名、原作者、许可证和来源页面；
- 如果图标集合许可证是 MIT、Apache 2.0、ISC 等需要归属说明的许可证，必须同步更新 `THIRD_PARTY_NOTICES.md`；
- 如果使用 CC0 图标，也建议记录来源，方便后续审计；
- 不使用品牌 Logo 图标作为 App 自有品牌标识，除非明确符合对应品牌使用规则。

推荐命名：

```text
entry/src/main/resources/base/media/ic_search.svg
entry/src/main/resources/base/media/ic_shelf.svg
entry/src/main/resources/base/media/ic_settings.svg
entry/src/main/resources/base/media/ic_about.svg
entry/src/main/resources/base/media/ic_back.svg
entry/src/main/resources/base/media/ic_refresh.svg
entry/src/main/resources/base/media/ic_add_shelf.svg
```

建议图标清单：

| 用途 | 建议图标语义 | 资源名 |
| --- | --- | --- |
| 搜索 Tab | search / magnifier | `ic_search.svg` |
| 书架 Tab | book / library / bookmark | `ic_shelf.svg` |
| 设置 Tab | settings / gear | `ic_settings.svg` |
| 关于 Tab | info / circle-info | `ic_about.svg` |
| 阅读返回 | arrow-left / chevron-left | `ic_back.svg` |
| 刷新章节 | refresh / rotate | `ic_refresh.svg` |
| 加入书架 | bookmark-plus / book-plus | `ic_add_shelf.svg` |
| 主题切换 | sun / moon | `ic_theme.svg` |
| 语言切换 | language / translate | `ic_language.svg` |

## 主题

当前主题状态：

```text
appTheme = light | dark
```

明亮主题：

- 页面背景：`#F7F8FA`
- 卡片背景：`#FFFFFF`
- 顶部半透明背景：`#EFFFFFFF`
- 主文字：`#111111`
- 次级文字：`#666666`
- 强调色：`#34C759`

暗黑主题：

- 页面背景：`#101418`
- 卡片背景：`#1B222A`
- 顶部半透明背景：`#CC141A20`
- 主文字：`#F2F5F7`
- 次级文字：`#AAB4C0`
- 强调色：`#34C759`

## 多语言

当前语言状态：

```text
appLanguage = zh | en
```

需要接入核心外壳文案：

- 搜索 / Search
- 书架 / Shelf
- 设置 / Settings
- 关于 / About
- 主题 / Theme
- 语言 / Language
- 全屏阅读 / Full screen reader
- 悬浮控制 / Floating controls

后续继续把规则说明、错误提示、设置说明细化到完整 i18n 字典。

## 底部胶囊 Tab

新版底部导航包含：

```text
搜索 / 书架 / 设置 / 关于
```

当前选中的 Tab 使用绿色胶囊背景，未选中状态使用透明背景和次级文字色。Tab 图标使用 ProIcons / Lucide Icons 来源的 SVG，不使用字符图标长期替代。

## 书架与阅读进度

`BookshelfItem` 已扩展：

```text
lastReadUrl?: string
progressPercent?: number
readCount?: number
```

行为：

- 搜索结果可加入书架；
- 当前阅读对象可加入书架；
- 打开章节阅读后会更新书架最近章节和阅读时间；
- 如果书架条目存在 `lastReadUrl`，从书架打开时优先继续最近章节；
- `progressPercent` 用章节位置估算，无法准确计算时保留最近值。

## 全屏阅读页

新版阅读页特点：

- 背景固定深色；
- 图片竖向卷轴全屏显示；
- 顶部显示悬浮标题胶囊；
- 底部显示悬浮返回、加入书架、刷新按钮；
- 渲染阅读模式继续使用 WebView 兜底，但外层采用同样全屏结构；
- 阅读页悬浮按钮使用 ProIcons / Lucide Icons 来源的 SVG 图标。

## 注意事项

- UI 改造最终应固化到源码，不依赖构建时注入；
- 图标资源加入仓库前必须先确认 ProIcons 对应集合页面上的许可证；
- 任何新增图标都要同步更新 `THIRD_PARTY_NOTICES.md`；
- 不能把字体包、来源不明图标包或未授权图标集提交到仓库。
