# 分支规则

## 当前分支定位

### `main`

- 当前唯一长期主分支。
- 保存当前稳定代码、文档和构建配置。
- 小范围、低风险维护可直接提交到 `main`。
- 风险较大的功能、结构调整或批量重构，应先从 `main` 新建 `feature/*` 或 `fix/*`。

### `backup`

- `main` 的快照备份分支。
- 可通过 `.github/workflows/force-backup-main.yml` 手动输入 `YES` 后强制覆盖。
- 不用于继续开发，不接收功能提交。

### `backup/*`

- 历史回滚点。
- 用于保存特定时间点或大改前状态。
- 不在该类分支上继续开发。

### `develop`

- 已删除。
- 当前不再作为默认开发、测试、合并或备份分支。
- 如未来确实需要重新启用，必须先更新本文件、`docs/CURRENT_STATUS.md`、`README.md` 和相关 workflow 说明。

### `feature/*`

- 较大功能开发分支。
- 适合拆分页面、下载功能、规则自动更新、搜索链路增强等较大改动。
- 从 `main` 新建，验证后再合回 `main`。

### `fix/*`

- 问题修复分支。
- 适合构建失败、运行异常、UI 错位、搜索无结果等修复。
- 从 `main` 新建，验证后再合回 `main`。

## 合并规则

- 小范围文档、配置、低风险修复：可直接进入 `main`。
- 较大功能或重构：`feature/*` / `fix/*` → `main`。
- 不使用 `develop` 作为默认中转分支。
- 不允许在 `backup` 或 `backup/*` 上继续开发。

## Workflow 分支规则

- 构建、合规、清理、备份 workflow 以当前长期分支 `main` 为准。
- 强制覆盖 `backup` 必须使用明确命名的备份 workflow，并要求人工确认。
- 禁止重新引入自动 UI 注入 workflow、自动 patch workflow 或 push 后无提示大规模改源码的 workflow。
- 清理 workflow 只允许手动触发，默认预览。

## 测试规则

- 修改 workflow 后必须确保基础测试能识别正确 workflow 文件。
- 修改 UI 后应至少构建安装一次。
- 修改搜索链路后必须测试中文、英文关键词。
- 修改文档中分支、备份、构建或发布规则后，必须同步更新 `docs/CURRENT_STATUS.md` 和文档索引。
