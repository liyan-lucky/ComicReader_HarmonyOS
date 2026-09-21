# 当前仓库状态

更新时间：2026-09-20

> 本轮完整需求与验证基线见 [SESSION_REQUIREMENTS_2026-08-31.md](SESSION_REQUIREMENTS_2026-08-31.md)。

## 定位

`ComicReader_HarmonyOS` 是漫画浏览器的 HarmonyOS / OpenHarmony ArkTS Stage App 主仓库。仓库只维护 App 工程代码、页面、构建脚本、文档和合规说明；公开漫画源规则由 `liyan-lucky/ComicReader_Rules` 独立维护。

## 当前工程状态

- 工程类型：HarmonyOS / OpenHarmony ArkTS Stage 应用。
- 包名：`com.nw.cleansite.novel.hm`。
- 当前工作树版本：0.88.5（版本码 88005）。
- 当前能力边界：公开漫画资源搜索、结果整理、章节卷轴阅读、书架目录浏览、历史/设置等 App 侧能力。
- 规则来源：默认从 `ComicReader_Rules` 的 `generated/update_manifest.json` 读取远程规则（两步获取：manifest → rules）。
- 目录来源：从 `update_manifest.json` 的 `catalog.url` 获取远程目录，本地 rawfile 作为 fallback。
- 目录解析同时兼容旧版 `womh_comic_catalog_v1` 和规则仓库增量发布使用的 `comic_catalog_v1`；任一作品完成来源及域名规则验证后即可进入线上目录。
- 搜索源：搜索引擎（Bing/百度/DuckDuckGo/Google/Yandex/搜狗/360）+ HTML 规则源 + API 源（Internet Archive/Wikimedia/Open Library/Library of Congress/Pepper）。
- 搜索结果筛选模式：规则筛选（默认，经 looksComicRelated + isBlockedSearchResult 筛选）和浏览器模式（不筛选，Web组件直接加载搜索引擎URL，iframe方式无限滚动连续加载下一页）。
- 搜索引擎查询词构建：auto模式根据关键词语言智能追加（中文加"漫画"，英文加"manga comic"），不再使用OR语法（百度不支持OR会导致结果污染）。浏览器模式不追加"在线阅读 章节"等查询变体。
- 浏览器模式搜索结果：Web组件全屏加载搜索引擎URL（Bing/百度等），CSS注入隐藏搜索框/导航栏/广告/分页栏，body padding-top让内容从HeaderOverlay下方开始。滚动到底部时iframe加载下一页URL，提取搜索结果用importNode追加到当前页面，显示"— 第N页 —"分隔符。_findNextUrl支持链接文本匹配+rel=next+sb_pagN class+URL-based fallback（Bing first=、Baidu pn=、Google start=、Sogou page=）。
- 内置浏览器（WebBrowserPage）：Web组件全屏 + 透明HeaderOverlay浮层（返回按钮+阅读按钮），加载完成后自动检测漫画域名（isComicDomain）并提示使用阅读模式。Web组件设置标准移动版Chrome User-Agent避免被搜索引擎拒绝。
- 内置规则：`SourceRules.ets` 包含 100 条验证域名规则（`VERIFIED_DOMAIN_LIST`）+ 公开访问规则（`PUBLIC_ACCESS_LIST`）+ 通用 HTML 规则（`generic_html`）。`GeneratedSourceRules.ets` 已删除，规则统一由 `SourceRules.ets` 管理。
- 规则优先级：自定义规则 > 内置规则 > 远程规则（`rebuildEffectiveRules` 合并顺序）。搜索时规则上限 30 条。
- 屏蔽规则：用户可在设置中维护 URL 屏蔽列表（JSON 字符串数组），搜索结果中匹配屏蔽 URL 的条目自动过滤。
- 屏蔽词同步：从规则仓库（`liyan-lucky/ComicReader_Rules`）下载 `filter_words.txt`，解析 `[DOMAINS]`/`[WORDS]`/`[NOISE]` 分段格式，更新 `searchFilterConfig` 并持久化。在更新菜单（UpdateDialog）中添加"同步屏蔽词"按钮触发。
- 更新菜单进度显示：每个更新操作（规则/目录/屏蔽词）独立显示进度条和状态文本，进度条跟随下载进度实时变化。目录更新显示当前数量→更新后数量差异。
- 自定义规则编辑器：全屏代码编辑器，支持行号显示、光标位置跟踪（Ln/Col）、行号点击编辑、键盘快捷键（工具栏键盘图标）。可编辑自定义规则和屏蔽列表，只读查看内置规则和远程规则。
- 自动探测未知来源：搜索引擎发现的无专用规则 URL 会被串行探测（`autoProbeUnknownUrls`），使用通用 HTML 规则尝试解析章节或图片，渐进式显示结果。`splitEngineResults` 对 probeQueue 做去重，`autoProbeUnknownUrls` 使用 try-finally 确保 `isProbing` 状态可靠重置。
- 搜索引擎 Toggle：使用数组替换方式更新 `@State searchEngines`，确保 ArkUI 状态正确刷新。
- 数据持久化：书架/历史/最近 10 条搜索/主题/语言通过 `@ohos.data.preferences` 持久化存储，书架封面落盘缓存。
- 合规边界：不托管漫画图片、章节正文、付费内容、账号数据、站点 Logo、字体、SDK 压缩包、签名证书、HAP/APP 发布包或其他第三方受保护资源。

## 当前 UI 状态

- 绿色主色 `#34C759`，所有按钮统一绿色 + 白色文字 + 圆角。
- 底部 Tab 栏毛玻璃效果 + 悬浮胶囊样式（borderRadius 28），半透明背景。
- 支持 明亮 / 暗黑 / 跟随系统 三种主题。
- 支持 中文 / English / 跟随系统 三种语言，所有 UI 文本通过 `t()` 翻译方法切换。
- 布局架构：Stack 三层叠加（底层可滚动内容 + 中层渐变半透明 HeaderOverlay + 底层导航栏），所有容器 `backgroundColor(Color.Transparent)` 确保渐变半透效果。
- 状态栏处理：`expandSafeArea` + `avoidStatusBarHeight` Blank 占位，渐变穿透状态栏，内容起始在下方。
- 搜索首页：Column 布局 + 插图 + 透明线框搜索框 + 顶部/底部 Blank 避让。
- 搜索按钮：绿色胶囊形 `#34C759`，加载时 Canvas 沿按钮轮廓绘制渐变描边旋转动画（深绿→透明）。
- 搜索框：透明背景 + 灰色线框，X 按钮可中断搜索+清空结果+回到首页。搜索结果页搜索框可编辑修改（hitTestBehavior.Transparent 修复点击穿透）。
- 网址分类标记：siteTypeTag 统一2字（漫画/百科/字典/应用/视频/社交/资讯/购物/社区/政府/网页），标题含"漫画"即归漫画类。
- 调试信息：搜索结果列表顶部显示引擎统计+实际查询词回显（buildEngineQuery构建后发送给搜索引擎的完整查询词）。
- 书架页：HeaderOverlay 中显示分类标签（横向滚动），选中分类后下方 3 列网格展示封面+标题，默认选中第一个分类。本地 rawfile 目录作为离线 fallback，远程更新覆盖。左右滑动切换分类（Stack 双内容叠加方案）。
- 设置页：SectionLabel + CardContainer 分组 + LinkRow/ToggleRow + 自定义 JSON 规则应用按钮，标题行图标+文字在 HeaderOverlay 渐变层中。间距 `avoidStatusBarHeight + 43`。
- 设置页图标：LinkRow 右侧用 `ic_chevron_right`（>），主题/语言行用 `ic_chevron_down`（▼），ToggleSettingRow 用开关。所有 `ic_more.svg` 已替换。
- 设置页文案：i18n 中文文案精简为4字（阅读全屏、屏幕常亮、显示阅读、封面校验、内置规则等）。
- 书架长按菜单：取消收藏/搜索书名/更新封面/删除/关闭，5个选项。
- 对话框遮罩：所有对话框使用 `dialogOverlay()` 半透明遮罩（`#88000000`/`#66000000`），避免点击穿透和显示残留。
- `onBackPress`：处理所有对话框状态（settingsDialog、themeDialogVisible、languageDialogVisible、updateDialogVisible、historyMenuVisible、bookLongPressVisible、editorMenuVisible、editorFullscreen、editorConfirmDiscard）。
- 屏幕常亮：默认关闭，可在设置→关于中手动开启。
- Tab 图标状态：选中绿色图标+文字，未选中灰色图标+文字，通过 `this.activeTab` 直接驱动。
- 所有图标使用 SVG（stroke 格式），来自 iconoir.com / ProIcons / Lucide Icons，存放在 `entry/src/main/resources/rawfile/`。全彩图标模式下所有配色通过 `colorfulAccent(key)` 统一逻辑。
- 全屏显示模式：`expandSafeArea` + 状态栏透明 + 9 段渐变半透明 HeaderOverlay。
- 自定义规则编辑器 UI：全屏 Stack 布局，顶部工具栏（返回/标题/三点菜单），底部编辑工具栏（撤销/重做/复制/粘贴/保存/键盘等图标）。READ 模式行号+内容垂直布局，行号可点击切换编辑；EDIT 模式左侧行号 Column + 1px 竖分界线 + TextArea，`onContentScroll` 同步行号滚动。`onTextSelectionChange` 跟踪光标 Ln/Col 位置。

## 构建脚本

- `scripts/build_local.ps1`：本地构建脚本，支持 `--full`（默认，中间版本号+1）和 `--incremental`（末尾版本号+1）两种模式。
- `scripts/update_build_version.js`：版本号管理，`--full` 时 `state.full += 1; state.incremental = 0`，`--incremental` 时 `state.incremental += 1`。
- `version.json`：当前版本状态文件，记录 major/full/incremental/buildType/buildTime。

## 当前分支和备份

- `main`：当前唯一长期主分支。
- `backup`：`main` 的快照备份分支。
- `.github/workflows/force-backup-main.yml`：手动输入 `YES` 后，把 `main` 当前提交强制覆盖到 `backup`。
- `develop`：已删除，不再作为默认开发或备份流程的一部分。

## 当前 GitHub Actions

- `.github/workflows/manual-build-entry-advanced.yml`：手动构建 unsigned HAP。
- `.github/workflows/compliance-check.yml`：合规、许可证和规则加固检查。
- `.github/workflows/cleanup-artifacts.yml`：手动清理 artifacts / workflow runs。
- `.github/workflows/force-backup-main.yml`：手动强制刷新 `backup` 分支。

## 文档维护规则

1. README 只保留项目入口、当前状态摘要和关键链接。
2. 长期规范、架构、合规、搜索、构建和发布说明放入 `docs/`。
3. 当前事实变化时，优先同步本文件、根 README 和 `docs/README.md`。
4. 不重新引入自动 UI 注入脚本、临时 patch workflow 或散落的临时说明文件。
