# 文件放置规则

本文件用于决定新增文件应该放在哪里，避免文件散落在根目录或临时目录。

## 总原则

- 根目录只放项目入口、许可证、构建系统必需文件和工具必须识别的配置。
- 长期说明写入 `docs/`。
- 可执行维护逻辑写入 `scripts/`。
- App 源码写入 `entry/src/main/ets/`。
- App 资源写入 `entry/src/main/resources/`。
- GitHub 自动化写入 `.github/workflows/`。
- 不再新增自动 UI 注入脚本或 patch 脚本。

## 新文件归类表

| 文件类型 | 放置位置 | 说明 |
| --- | --- | --- |
| 页面入口 | `entry/src/main/ets/pages/` | 页面级 ArkTS 文件。 |
| 公共工具 | `entry/src/main/ets/common/` | HTTP、搜索、解析、URL、远程规则、构建信息。 |
| 数据模型 | `entry/src/main/ets/model/` | interface、type、枚举。 |
| 图片资源 | `entry/src/main/resources/base/media/` | 图标、插画、App 图标。 |
| 配置资源 | `entry/src/main/resources/base/profile/` | Stage 配置、路由或系统资源配置。 |
| 构建脚本 | `scripts/` | build、install、version、check。 |
| GitHub Actions | `.github/workflows/` | 构建、清理、备份、检查。 |
| 构建文档 | `docs/build/` | 构建说明、SDK、CI 构建说明。 |
| 发布文档 | `docs/release/` | 发布前检查、版本发布说明。 |
| 维护文档 | `docs/maintenance/` | 维护者说明、长期维护规则。 |
| 合规文档 | `docs/compliance/` | 合规、安全、隐私、免责声明、第三方来源、版权说明。 |
| 开发规范 | `docs/development/` | 需求、问题、规范、流程、贡献指南。 |
| 架构说明 | `docs/architecture/` | 系统结构、模块关系。 |
| 搜索说明 | `docs/search/` | 搜索链路、规则系统、过滤策略。 |
| 临时测试文件 | 不提交 | 本地验证后删除。 |

## 根目录允许项

根目录长期只允许：

- `README.md`
- `LICENSE`
- `version.json`
- `oh-package.json5`
- `build-profile.json5`
- `hvigorfile.ts`
- `hvigor/`
- `entry/`
- `scripts/`
- `docs/`
- `.github/`
- `.gitignore`
- `.editorconfig`
- `.gitattributes`

构建、发布、维护、合规、隐私、安全、第三方说明等 Markdown 文档不要再放根目录。

## ArkTS 源码拆分规则

`Index.ets` 当前仍是主页面组合入口，但后续新增功能不要继续无限堆入单文件。

建议拆分：

- 搜索首页、搜索结果：后续可拆到 `entry/src/main/ets/pages/search/`。
- 设置页组件：后续可拆到 `entry/src/main/ets/pages/settings/`。
- 阅读器组件：后续可拆到 `entry/src/main/ets/pages/reader/`。
- 书架和历史：后续可拆到 `entry/src/main/ets/pages/library/`。

拆分前必须保证构建通过，避免一次拆太多导致定位困难。

## 搜索规则相关文件

App 主仓库只放：

- 内置兜底规则。
- 远程规则加载逻辑。
- 搜索结果过滤逻辑。
- 规则数据模型。

规则仓库 `ComicReader_Rules` 放：

- 站点规则源。
- 生成后的 `generated/index.json`。
- 规则测试和规则文档。

不要把大量站点规则直接堆进 App 主仓库。

## Workflow 放置规则

允许新增的 workflow 类型：

- 手动构建。
- 合规检查。
- 清理构建产物。
- 强制覆盖备份分支。

禁止新增的 workflow 类型：

- 自动 UI 注入。
- 自动 patch ArkTS 源码。
- push 后无提示自动大规模改源码。
- 临时一次性 workflow。

## 备份分支规则

- `backup` 分支用于保存当前 `main` 的快照。
- `backup/*` 分支用于保存某个特定时间点的快照。
- 备份分支不用于继续开发。
- 强制覆盖备份分支必须通过明确命名的 workflow 或人工确认操作。

## 命名规则

- 文件名使用英文小写或清晰英文短语。
- 脚本用动词开头，例如 `build.sh`、`install.sh`、`update_build_version.js`。
- 文档用大写下划线或明确英文名，例如 `FILE_PLACEMENT_RULES.md`。
- 不使用 `new.py`、`test2.js`、`final.md`、`临时.txt` 这类无意义名称。

## 提交前检查

新增文件前先问：

1. 这是源码、资源、脚本、workflow 还是文档？
2. 是否必须放在根目录？
3. 是否已有同类目录？
4. 是否会被误认为临时文件？
5. 是否需要在 `docs/README.md` 建索引？
6. 是否包含不应提交的产物、账号数据、私钥或第三方受保护资源？
