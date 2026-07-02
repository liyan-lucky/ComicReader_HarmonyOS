# 仓库规范

本文件用于约束仓库目录、文档、脚本、workflow、资源和分支使用，避免文件散落、临时脚本堆积、说明分散到 README 或对话里。

## 当前分支策略

- `main`：当前唯一长期主分支，保存已经测试确认的稳定代码。
- `backup`：主分支快照分支，可通过手动 workflow 强制覆盖。
- `backup/*`：历史回滚点，不在上面继续开发。
- `feature/*`：较大功能开发分支。
- `fix/*`：问题修复分支。

所有修改默认落到 `main`。风险较大的修改应从 `main` 新建 `feature/*` 或 `fix/*` 分支。

## 当前仓库状态

- 根目录旧文档已迁入 `docs/`。
- 自动 UI 注入脚本和 UI patch workflow 已删除。
- `backup` 分支已建立，并有手动强制覆盖 workflow。
- README 只保留项目入口和文档链接。
- 详细说明统一进入 `docs/README.md` 索引。

## 根目录规范

根目录只允许放项目入口、许可证、构建系统必需文件和工具必须识别的配置，禁止随手新建临时说明、临时脚本或测试文件。

允许长期存在的根目录文件和目录：

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

不再允许长期放在根目录的文档：

- `BUILDING.md`
- `CONTRIBUTING.md`
- `COMPLIANCE.md`
- `RELEASE_CHECKLIST.md`
- `MAINTAINERS.md`
- `NOTICE.md`
- `DISCLAIMER.md`
- `PRIVACY.md`
- `SECURITY.md`
- `THIRD_PARTY_NOTICES.md`
- `COPYRIGHT`

这些文档已经统一迁入 `docs/`。

新增根目录文件必须先确认不能归入 `docs/`、`scripts/`、`.github/` 或 `entry/`。

## 目录职责

- `entry/`：HarmonyOS / OpenHarmony App 工程代码。
- `entry/src/main/ets/pages/`：页面层。`Index.ets` 可以保留入口组合逻辑，但后续新增大功能应拆到独立页面或组件文件。
- `entry/src/main/ets/common/`：公共能力，例如 HTTP、搜索引擎、HTML 解析、远程规则、URL 工具、构建信息。
- `entry/src/main/ets/model/`：数据模型和接口类型。
- `entry/src/main/resources/`：应用资源，包括图标、媒体、配置资源。
- `scripts/`：本地构建、安装、版本号、仓库维护脚本。
- `.github/workflows/`：GitHub Actions workflow。
- `docs/`：所有文档（扁平结构）。

## 文档规范

- README 只作为项目入口，不能堆积所有细节。
- 构建说明写入 `docs/BUILDING.md`。
- 发布检查写入 `docs/RELEASE_CHECKLIST.md`。
- 维护者说明写入 `docs/MAINTAINERS.md`。
- 合规、安全、隐私、法律声明、第三方来源写入 `docs/` 对应文件。
- 长期需求写入 `docs/DEVELOPMENT_REQUIREMENTS.md`。
- 开发问题和处理记录写入 `docs/DEVELOPMENT_ISSUES.md`。
- 仓库规范写入 `docs/REPOSITORY_STANDARDS.md`。
- 架构说明写入 `docs/ARCHITECTURE.md`。
- 搜索和规则说明写入 `docs/SEARCH.md`。
- UI 规范写入 `docs/UI.md`。
- 新增文档必须在 `docs/README.md` 建立索引。

## 脚本规范

- 构建、安装、版本号、检查脚本放入 `scripts/`。
- 脚本命名必须表达用途，例如 `build.sh`、`install.sh`、`update_build_version.js`。
- 禁止再新增自动 UI 注入脚本、自动 patch 脚本、临时一次性补丁脚本。
- 后续源码修改以直接替换完整源码文件为主，不再通过脚本注入片段修改 ArkTS 文件。
- Python 脚本必须通过 `python3 -m py_compile`。
- JavaScript 脚本必须通过 `node --check`。
- Shell 脚本必须通过 `bash -n`。

## Workflow 规范

- workflow 只用于构建、清理、备份、合规检查等明确任务。
- 禁止重新引入自动 UI 注入 workflow。
- workflow 不应该把临时逻辑直接写成大段 shell；复杂逻辑应放到 `scripts/` 后由 workflow 调用。
- 自动流程不得无提示修改大量源码。
- 需要对 `backup` 分支做强制覆盖时，必须使用专门的备份 workflow，并在 workflow 名称和日志中明确提示。

## 资源规范

- App 图标使用 `entry/src/main/resources/base/media/icon.png`。
- Tab、设置、阅读控制图标使用统一线性风格资源。
- 新增图片资源必须放入 `entry/src/main/resources/base/media/`，并使用清晰命名。
- 禁止提交第三方字体文件、站点 Logo、漫画图片、付费内容或账号数据。

## 禁止提交

- `.hap`、`.app` 发布包。
- `.p12`、`.pfx`、`.jks`、`.keystore`、`.pem`、`.key` 等证书和私钥。
- SDK 压缩包。
- 第三方受保护图片、漫画内容、字体和站点 Logo。
- 临时压缩包、临时日志、一次性测试文件。

## 变更流程

1. 先确认文件应该放在哪个目录。
2. 更新对应文档或问题记录。
3. 小改动可直接在 `main` 修改；风险较大时从 `main` 新建 `feature/*` 或 `fix/*`。
4. 修改源码时尽量直接替换完整文件，避免片段注入导致状态不可控。
5. 用户安装测试通过后再保留为稳定版本。
6. 重要节点使用 `backup/*` 或备份 workflow 做回滚点。