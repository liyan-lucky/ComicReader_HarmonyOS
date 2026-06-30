# 仓库规范

## 目录规范

- `entry/`：HarmonyOS / OpenHarmony App 工程代码。
- `entry/src/main/ets/common/`：公共能力，例如搜索引擎、规则、HTTP、解析器、构建信息。
- `entry/src/main/ets/pages/`：页面入口。后续应逐步拆分，避免单文件过大。
- `entry/src/main/resources/`：资源文件，包含 SVG 图标和应用图标。
- `scripts/`：构建、校验、CI 辅助和临时自动化脚本。
- `.github/workflows/`：GitHub Actions 流程。
- `docs/`：所有长期维护文档。

## 文档规范

- README 只作为项目入口，不能堆积所有细节。
- 长期需求写入 `docs/development/DEVELOPMENT_REQUIREMENTS.md`。
- 开发问题写入 `docs/development/DEVELOPMENT_ISSUES.md`。
- 架构说明写入 `docs/architecture/ARCHITECTURE.md`。
- 搜索和规则说明写入 `docs/search/`。
- 新增文档必须在 `docs/README.md` 建立索引。

## 脚本规范

- 复杂脚本放入 `scripts/`，不要直接嵌入 workflow。
- workflow 只做检出、调用脚本、上传产物或提交结果。
- Python 脚本必须通过 `python3 -m py_compile`。
- JavaScript 脚本必须通过 `node --check`。
- Shell 脚本必须通过 `bash -n`。

## Workflow 规范

- 所有自动 workflow 禁止直接针对 `main`。
- `main` 只用于稳定代码和手动入口承载。
- 开发、测试、校验、UI 自动应用都应面向 `develop` 或 feature/fix 分支。
- 固定 UI 自动应用 workflow：`.github/workflows/patch-reader-floating-controls.yml`。
- 不再新建多个临时 workflow；需要变更时直接覆盖固定 workflow 或脚本。
- 清理流程默认预览，不直接删除。

## 资源规范

- 图标使用 SVG。
- Tab、设置、阅读控制图标使用统一线性风格。
- APP 图标为自绘 SVG，可以按当前构图继续微调。
- 禁止提交第三方字体文件、站点 Logo、漫画图片、付费内容或账号数据。

## 禁止提交

- `.hap`、`.app` 发布包。
- `.p12`、`.pfx`、`.jks`、`.keystore`、`.pem`、`.key` 等证书和私钥。
- SDK 压缩包。
- 第三方受保护图片、漫画内容、字体和站点 Logo。

## 变更流程

1. 更新需求或问题文档。
2. 在 `develop` 或 feature/fix 分支修改代码。
3. 运行基础测试和合规检查。
4. 用户安装测试。
5. 确认后从 `develop` 合并到 `main`。
