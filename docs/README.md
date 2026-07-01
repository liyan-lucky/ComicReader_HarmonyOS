# 文档中心

本目录是漫画浏览器仓库的统一文档入口。后续所有需求、问题、规范、架构、构建、测试、发布、合规、安全和维护说明都应归类到这里，避免散落在 README、脚本注释或临时对话中。

## 文档分类

### 构建与发布

- [`build/BUILDING.md`](build/BUILDING.md)：本地构建、GitHub Actions 构建、SDK 来源和构建产物规则。
- [`release/RELEASE_CHECKLIST.md`](release/RELEASE_CHECKLIST.md)：发布、安装测试、版本和合规检查清单。

### 维护

- [`maintenance/MAINTAINERS.md`](maintenance/MAINTAINERS.md)：维护者检查、CI 维护和发布前注意事项。

### 合规、安全和第三方说明

- [`compliance/COMPLIANCE.md`](compliance/COMPLIANCE.md)：合规审计记录。
- [`compliance/NOTICE.md`](compliance/NOTICE.md)：项目 NOTICE。
- [`compliance/DISCLAIMER.md`](compliance/DISCLAIMER.md)：免责声明。
- [`compliance/PRIVACY.md`](compliance/PRIVACY.md)：隐私说明。
- [`compliance/SECURITY.md`](compliance/SECURITY.md)：安全策略。
- [`compliance/THIRD_PARTY_NOTICES.md`](compliance/THIRD_PARTY_NOTICES.md)：第三方来源说明。
- [`compliance/COPYRIGHT.md`](compliance/COPYRIGHT.md)：版权说明。

### 开发与规范

- [`development/DEVELOPMENT_REQUIREMENTS.md`](development/DEVELOPMENT_REQUIREMENTS.md)：持续更新的产品与开发需求。
- [`development/DEVELOPMENT_ISSUES.md`](development/DEVELOPMENT_ISSUES.md)：开发过程中遇到的问题、原因和处理状态。
- [`development/REPOSITORY_STANDARDS.md`](development/REPOSITORY_STANDARDS.md)：仓库目录、文档、脚本、workflow、资源和分支管理规范。
- [`development/FILE_PLACEMENT_RULES.md`](development/FILE_PLACEMENT_RULES.md)：新增文件应该放在哪里，避免文件到处都是。
- [`development/BRANCH_RULES.md`](development/BRANCH_RULES.md)：分支和合并规则。
- [`development/UI_RULES.md`](development/UI_RULES.md)：UI 风格、颜色、图标和页面结构规范。
- [`development/CONTRIBUTING.md`](development/CONTRIBUTING.md)：贡献指南。

### 架构

- [`architecture/ARCHITECTURE.md`](architecture/ARCHITECTURE.md)：App 整体架构、页面关系、搜索链路、规则系统和阅读流程。

### 搜索和规则

- [`search/SEARCH_ARCHITECTURE.md`](search/SEARCH_ARCHITECTURE.md)：搜索链路和结果处理策略。
- [`search/RULE_SYSTEM.md`](search/RULE_SYSTEM.md)：内置规则、远程规则和自定义规则。

## 当前仓库状态

- `main` 是当前唯一长期主分支。
- `develop` 已删除。
- `backup` 是主分支快照分支，可通过手动 workflow 强制覆盖。
- 根目录只保留项目入口、许可证、构建系统文件和工具必须识别的配置。
- 长期说明全部归入 `docs/`。
- 禁止重新引入自动 UI 注入脚本、自动 patch 脚本或临时 workflow。

## 维护要求

1. 新需求先写入 `DEVELOPMENT_REQUIREMENTS.md`，再开发。
2. 新问题必须写入 `DEVELOPMENT_ISSUES.md`，包含原因和状态。
3. 新文件必须先查 `FILE_PLACEMENT_RULES.md`，再决定放置位置。
4. README 只保留项目入口和链接，详细说明放入 `docs/`。
5. 构建、发布、合规、隐私、安全、维护说明不得再放在根目录。
6. 当前 `develop` 分支已删除；如需开发分支，必须从 `main` 新建 `feature/*` 或 `fix/*`。