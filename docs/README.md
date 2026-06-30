# 文档中心

本目录是漫画浏览器仓库的统一文档入口。后续所有需求、问题、规范、架构、构建、测试、发布说明都应归类到这里，避免散落在 README、脚本注释或临时对话中。

## 文档分类

### 开发与规范

- [`development/DEVELOPMENT_REQUIREMENTS.md`](development/DEVELOPMENT_REQUIREMENTS.md)：持续更新的产品与开发需求。
- [`development/DEVELOPMENT_ISSUES.md`](development/DEVELOPMENT_ISSUES.md)：开发过程中遇到的问题、原因和处理状态。
- [`development/REPOSITORY_STANDARDS.md`](development/REPOSITORY_STANDARDS.md)：仓库目录、文档、脚本、workflow 管理规范。
- [`development/BRANCH_RULES.md`](development/BRANCH_RULES.md)：分支和合并规则。
- [`development/GITHUB_WORKFLOW.md`](development/GITHUB_WORKFLOW.md)：GitHub Actions 使用规范。
- [`development/UI_RULES.md`](development/UI_RULES.md)：UI 风格、颜色、图标和页面结构规范。

### 架构

- [`architecture/ARCHITECTURE.md`](architecture/ARCHITECTURE.md)：App 整体架构、页面关系、搜索链路、规则系统和阅读流程。

### 搜索和规则

- [`search/SEARCH_ARCHITECTURE.md`](search/SEARCH_ARCHITECTURE.md)：搜索链路和结果处理策略。
- [`search/RULE_SYSTEM.md`](search/RULE_SYSTEM.md)：内置规则、远程规则和自定义规则。

## 维护要求

1. 新需求先写入 `DEVELOPMENT_REQUIREMENTS.md`，再开发。
2. 新问题必须写入 `DEVELOPMENT_ISSUES.md`，包含原因和状态。
3. 新 workflow 必须先检查是否可复用现有固定 workflow；默认不新增临时 workflow。
4. 所有自动流程禁止直接针对 `main` 分支运行。
5. README 只保留项目入口和链接，详细说明放入 `docs/`。
