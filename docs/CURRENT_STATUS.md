# 当前仓库状态

更新时间：2026-07-01

## 定位

`ComicReader_HarmonyOS` 是漫画浏览器的 HarmonyOS / OpenHarmony ArkTS Stage App 主仓库。仓库只维护 App 工程代码、页面、构建脚本、文档和合规说明；公开漫画源规则由 `liyan-lucky/ComicReader_Rules` 独立维护。

## 当前工程状态

- 工程类型：HarmonyOS / OpenHarmony ArkTS Stage 应用。
- `oh-package.json5`：`modelVersion` 为 `6.1.1`，包名为 `comic_reader_harmony`，版本字段为 `0.0.0`。
- 当前能力边界：公开漫画资源搜索、结果整理、章节卷轴阅读、书架/历史/设置等 App 侧能力。
- 规则来源：默认从 `ComicReader_Rules` 的 `generated/index.json` 读取远程规则。
- 合规边界：不托管漫画图片、章节正文、付费内容、账号数据、站点 Logo、字体、SDK 压缩包、签名证书、HAP/APP 发布包或其他第三方受保护资源。

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
