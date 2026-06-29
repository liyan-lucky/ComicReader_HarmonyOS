# 漫画浏览器 · HarmonyOS

这是「漫画浏览器」鸿蒙 ArkTS Stage 项目。主仓库只放 App 工程代码；漫画公开源规则放到独立规则仓库，App 可以从 GitHub Raw 地址更新规则。

## 当前构建状态

GitHub Actions 当前已配置并验证通过 4 个 unsigned HAP 构建产物：

| 产物 | Runtime OS | ABI | Product | Artifact 名称 |
| --- | --- | --- | --- | --- |
| HarmonyOS ARM64 | `HarmonyOS` | `arm64-v8a` | `default` | `comic-reader-hap-harmonyos-arm64` |
| HarmonyOS x86_64 | `HarmonyOS` | `x86_64` | `default` | `comic-reader-hap-harmonyos-x86_64` |
| OpenHarmony ARM64 | `OpenHarmony` | `arm64-v8a` | `openharmony_verify` | `comic-reader-hap-openharmony-arm64` |
| OpenHarmony x86_64 | `OpenHarmony` | `x86_64` | `openharmony_verify` | `comic-reader-hap-openharmony-x86_64` |

CI 使用私有 SDK 仓库 `liyan-lucky/HarmonyOS_SDK_Tools` 的单包 `.7z` 命令行 SDK。需要在本仓库 Actions secrets/variables 中配置：

- `HARMONYOS_SDK_TOKEN`：可读取 `HarmonyOS_SDK_Tools` 私有仓库和 Release 资产的 Token；
- `HARMONYOS_SDK_URL`：SDK Release tag 页面地址或 SDK 资产直链；当前推荐 tag 为 `linux_command_line_tool_6.1.1`，SDK 资产为单包 `.7z`。

完整构建说明见 [`BUILDING.md`](BUILDING.md)。

## 当前版本规则

App 使用三段版本号：

```text
主版本.全量构建号.增量构建号
```

当前初始版本：

```text
0.0.0
```

- 第一段由维护者手动指定，当前为 `0`；
- `scripts/build_full.sh` 每次全量构建自动增加第二段，并把第三段重置为 `0`；
- `scripts/build_incremental.sh` 每次增量构建自动增加第三段；
- App 的“关于”页显示版本、versionCode、构建类型、构建目标和构建时间。

常用命令：

```bash
bash scripts/build_full.sh
bash scripts/build_incremental.sh
bash scripts/hdc_install_hap.sh /path/to/app.hap
```

## 仓库拆分

- App 主仓库：`liyan-lucky/ComicReader_HarmonyOS`
- 规则仓库：`liyan-lucky/ComicReader_Rules`
- 私有 SDK 工具仓库：`liyan-lucky/HarmonyOS_SDK_Tools`
- 默认远程规则地址：

```text
https://raw.githubusercontent.com/liyan-lucky/ComicReader_Rules/main/generated/index.json
```

## App 功能

- 四个 Tab：搜索 / 书架 / 设置 / 关于
- 搜索现有主流搜索引擎
- 聚合公开 API / 公开 HTML 漫画源
- 按漫画名称归类显示
- 封面 + 名称 / 纯封面列表
- 章节列表
- 原生图片卷轴阅读
- 公开卷轴网页渲染兜底
- 书架和阅读历史
- 设置页可调整搜索、过滤、显示、阅读、规则等选项
- 关于页显示构建时间和三段版本信息
- 从 GitHub 远程更新规则

## 导入 DevEco Studio

1. 打开 DevEco Studio。
2. 选择 **Open Project**。
3. 打开本仓库根目录。
4. 等待 hvigor 同步。
5. 本地调试通常使用 `default` / `HarmonyOS` / `phone` 配置。
6. 配置签名后运行 `entry` 模块。

## 构建和签名

本仓库不提交签名证书、私钥或本地签名配置。

`build-profile.json5` 当前未包含签名配置。GitHub Actions 产物是 unsigned HAP，仅用于构建验证和后续签名流程输入。正式安装、上架或分发前，请在本地 DevEco Studio 或独立签名流程中配置合法签名，并确认 `.gitignore` 已排除证书、密钥和本地配置文件。

## GitHub Actions 流程

| 流程名 | 文件 | 用途 |
| --- | --- | --- |
| `构建漫画浏览器 HAP` | `.github/workflows/manual-build-entry.yml` | 4 平台 unsigned HAP 构建。 |
| `合规检查` | `.github/workflows/compliance-check.yml` | 检查合规文档、许可证、禁止提交的发布包和签名文件。 |
| `基础测试` | `.github/workflows/basic-test.yml` | 检查 JS/Shell 脚本语法、版本文件和 workflow 关键结构。 |
| `清理旧构建产物` | `.github/workflows/cleanup-artifacts.yml` | 手动或定时清理旧 artifact，可选清理旧 workflow runs。 |

构建流程会上传：

- `comic-reader-hap-*`：unsigned HAP 产物；
- `comic-reader-sdk-install-logs-*`：SDK 下载和解压日志；
- `comic-reader-hvigor-logs-*`：hvigor 诊断日志。

清理流程默认使用预览模式，不会真正删除；需要手动触发并把 `dry_run` 改为 `false` 才会删除符合条件的旧 artifact。

## 从 GitHub 更新规则

App 内：

```text
设置 → GitHub 远程规则 → 从GitHub更新规则
```

默认读取：

```text
https://raw.githubusercontent.com/liyan-lucky/ComicReader_Rules/main/generated/index.json
```

远程规则索引会进行基础安全校验：HTTPS、本地调试地址例外、固定 schema、规则数量上限和关键字段长度限制。

如果你把规则仓库改名，修改 App 设置里的远程地址即可。

## 合规边界

项目只处理公开可访问资源。不实现登录绕过、付费绕过、验证码绕过、DRM 绕过、加密接口破解、App 专属协议绕过或反爬规避。

本仓库不托管、不上传、不分发漫画图片、章节正文、付费内容、账号数据、签名证书、私钥、站点 Logo、字体、SDK 压缩包、HAP/APP 发布包或其他第三方受保护资源。

## 隐私说明

App 申请 `ohos.permission.INTERNET`，用于访问用户选择的公开页面、公开 API、搜索引擎和远程规则索引。

App 可能在本地保存搜索设置、远程规则地址、书架、阅读历史、阅读偏好和用户手动填写的公开 API Key 或搜索配置。本仓库当前不应包含账号登录、广告 SDK、遥测统计、云同步或后台上传用户数据的逻辑。

## 许可证和合规文件

本仓库采用 MIT License。

相关文件：

- `LICENSE`
- `NOTICE.md`
- `DISCLAIMER.md`
- `PRIVACY.md`
- `SECURITY.md`
- `THIRD_PARTY_NOTICES.md`
- `CONTRIBUTING.md`
- `COMPLIANCE.md`
- `MAINTAINERS.md`
- `RELEASE_CHECKLIST.md`
- `BUILDING.md`

## 初始化并推送到 GitHub

```bash
git init
git add .
git commit -m "initial HarmonyOS comic reader app"
git branch -M main
git remote add origin https://github.com/liyan-lucky/ComicReader_HarmonyOS.git
git push -u origin main
```
