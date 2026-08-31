# 当前仓库状态

更新时间：2026-08-31

> 本轮完整需求与验证基线见 [SESSION_REQUIREMENTS_2026-08-31.md](SESSION_REQUIREMENTS_2026-08-31.md)。

## 定位

`ComicReader_HarmonyOS` 是漫画浏览器的 HarmonyOS / OpenHarmony ArkTS Stage App 主仓库。仓库只维护 App 工程代码、页面、构建脚本、文档和合规说明；公开漫画源规则由 `liyan-lucky/ComicReader_Rules` 独立维护。

## 当前工程状态

- 工程类型：HarmonyOS / OpenHarmony ArkTS Stage 应用。
- 包名：`com.nw.cleansite.novel.hm`。
- 当前工作树版本：0.1.110（版本码 1110）。
- 当前能力边界：公开漫画资源搜索、结果整理、章节卷轴阅读、书架目录浏览、历史/设置等 App 侧能力。
- 规则来源：默认从 `ComicReader_Rules` 的 `generated/update_manifest.json` 读取远程规则（两步获取：manifest → rules）。
- 目录来源：从 `update_manifest.json` 的 `catalog.url` 获取远程目录，本地 rawfile 作为 fallback。
- 目录解析同时兼容旧版 `womh_comic_catalog_v1` 和规则仓库增量发布使用的 `comic_catalog_v1`；任一作品完成来源及域名规则验证后即可进入线上目录。
- 搜索源：搜索引擎（Bing/DuckDuckGo/Google/Yandex）+ HTML 规则源 + API 源（Internet Archive/Wikimedia/Open Library/Library of Congress/Pepper）。
- 内置规则：`GeneratedSourceRules.ets` 包含 22 条自动审计生成的规则，通过 `domainApplicabilityList` 匹配 URL。
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
- 搜索框：透明背景 + 灰色线框，X 按钮可中断搜索+清空结果+回到首页。
- 书架页：HeaderOverlay 中显示分类标签（横向滚动），选中分类后下方 3 列网格展示封面+标题，默认选中第一个分类。本地 rawfile 目录作为离线 fallback，远程更新覆盖。
- 设置页：SectionLabel + CardContainer 分组 + LinkRow/ToggleRow + 自定义 JSON 规则应用按钮，标题行图标+文字在 HeaderOverlay 渐变层中。
- Tab 图标状态：选中绿色图标+文字，未选中灰色图标+文字，通过 `this.activeTab` 直接驱动。
- 所有图标使用 SVG（stroke 格式），来自 ProIcons / Lucide Icons，存放在 `entry/src/main/resources/rawfile/`。
- 全屏显示模式：`expandSafeArea` + 状态栏透明 + 9 段渐变半透明 HeaderOverlay。

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
