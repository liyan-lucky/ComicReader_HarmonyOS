# GitHub Actions 规范

## 总原则

- 所有自动流程不能直接针对 `main` 分支。
- `main` 只承载稳定代码和 workflow 文件入口。
- 开发、测试、校验、自动 UI 应用应面向 `develop` 或开发分支。
- 清理流程只允许手动触发，默认预览。
- 复杂逻辑放在 `scripts/`，workflow 只调用脚本。

## 现有流程

| 流程 | 文件 | 作用 | 触发方式 |
| --- | --- | --- | --- |
| 基础测试 | `.github/workflows/basic-test.yml` | 检查脚本语法、版本文件、workflow 关键结构 | `develop` push/PR + 手动 |
| 合规检查 | `.github/workflows/compliance-check.yml` | 检查合规文档、许可证、规则加固标记 | `develop` push/PR + 手动 |
| 高级构建漫画浏览器 HAP | `.github/workflows/manual-build-entry-advanced.yml` | 手动构建 unsigned HAP | 手动 |
| 清理旧构建产物和流程记录 | `.github/workflows/cleanup-artifacts.yml` | 预览或清理 artifacts / workflow runs | 手动 |
| 应用下一轮 UI 优化到 develop | `.github/workflows/patch-reader-floating-controls.yml` | 固定 UI 自动应用入口 | 手动，默认目标 `develop`，禁止 `main` |

## 清理流程

默认：

- `dry_run=true`
- 只预览，不删除。
- `clear_all_workflow_runs=false`

如需清空所有可删除 workflow run 记录：

1. `cleanup_workflow_runs=true`
2. `clear_all_workflow_runs=true`
3. `dry_run=false`

保护规则：

- 当前运行中的 workflow run 不删除。
- 排队、运行中、等待中的 run 不删除。

## 固定 UI 自动应用流程

固定文件：

```text
.github/workflows/patch-reader-floating-controls.yml
```

固定脚本：

```text
scripts/polish_ui.py
```

要求：

- 后续 UI 自动改动直接覆盖 `scripts/polish_ui.py`。
- 不新增临时 workflow。
- 如确需新增，必须先说明并更新文档。

## 基础测试修复记录

曾经失败原因：

- 测试检查 `.github/workflows/manual-build-entry.yml`。
- 实际文件为 `.github/workflows/manual-build-entry-advanced.yml`。

当前已修正为检查正确文件。
