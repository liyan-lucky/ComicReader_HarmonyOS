# 构建说明

本文记录当前仓库的 GitHub Actions 构建状态、SDK 连接方式、4 平台产物名称、版本自增脚本、安装辅助脚本和 CI 兼容补丁边界。

## 当前状态

当前 `main` 分支的 `构建漫画浏览器 HAP` 工作流已经能够生成 4 个 unsigned HAP 产物：

| Matrix package | Runtime OS | ABI | Product | Artifact |
| --- | --- | --- | --- | --- |
| `harmonyos-arm64` | `HarmonyOS` | `arm64-v8a` | `default` | `漫画浏览器-HAP产物-harmonyos-arm64` |
| `harmonyos-x86_64` | `HarmonyOS` | `x86_64` | `default` | `漫画浏览器-HAP产物-harmonyos-x86_64` |
| `openharmony-arm64` | `OpenHarmony` | `arm64-v8a` | `openharmony_verify` | `漫画浏览器-HAP产物-openharmony-arm64` |
| `openharmony-x86_64` | `OpenHarmony` | `x86_64` | `openharmony_verify` | `漫画浏览器-HAP产物-openharmony-x86_64` |

产物文件会被复制到：

```text
/tmp/comic_reader_harmonyos_artifacts/<matrix-package>/
```

文件名前缀会带上 matrix package，例如：

```text
harmonyos-arm64-*.hap
openharmony-x86_64-*.hap
```

> 这些产物均为 unsigned HAP。正式安装、发布或上架前，必须使用合法签名流程重新处理。

## 版本规则

App 当前使用三段版本号：

```text
主版本.全量构建号.增量构建号
```

当前初始值：

```text
0.0.0
```

规则：

- 第一段 `major` 由维护者手动指定，当前定义为 `0`；
- 第二段 `full` 由全量构建脚本自动增加，每次全量构建 `+1`；
- 第三段 `incremental` 由增量构建脚本自动增加，每次增量构建 `+1`；
- 全量构建时会把第三段重置为 `0`，例如 `0.3.7` 全量后变成 `0.4.0`；
- `versionCode` 由三段号换算，最低为 `1`。

版本状态文件：

```text
version.json
```

App 内构建信息文件：

```text
entry/src/main/ets/common/BuildInfo.ets
```

构建脚本会同步更新：

```text
AppScope/app.json5
oh-package.json5
entry/oh-package.json5
entry/src/main/ets/common/BuildInfo.ets
```

App 的“关于”页会显示：

- 版本；
- versionCode；
- 构建类型；
- 构建目标；
- 构建时间；
- 版本结构说明。

## 全量/增量构建脚本

全量构建：

```bash
bash scripts/build_full.sh
```

增量构建：

```bash
bash scripts/build_incremental.sh
```

只更新版本号和构建信息，不真正执行 HAP 构建：

```bash
SKIP_HAP_BUILD=1 bash scripts/build_full.sh
SKIP_HAP_BUILD=1 bash scripts/build_incremental.sh
```

手动指定第一段主版本：

```bash
node scripts/update_build_version.js --major 0 --full
node scripts/update_build_version.js --major 0 --incremental
```

本地指定构建目标：

```bash
BUILD_PRODUCT=default BUILD_PACKAGE_SUFFIX=local-harmonyos bash scripts/build_full.sh
BUILD_PRODUCT=openharmony_verify BUILD_PACKAGE_SUFFIX=local-openharmony bash scripts/build_incremental.sh
```

## HAP 安装辅助脚本

连接设备或虚拟机后，可以使用 hdc 安装：

```bash
bash scripts/hdc_install_hap.sh /path/to/app.hap
```

如果不传入路径，脚本会尝试在当前仓库和 `/tmp/comic_reader_harmonyos_artifacts` 中寻找最新的 `.hap` 文件：

```bash
bash scripts/hdc_install_hap.sh
```

前提：`hdc` 已安装并在 `PATH` 中。

## 工作流入口

文件：

```text
.github/workflows/manual-build-entry.yml
```

触发方式：

- `workflow_dispatch` 手动触发；
- push 到 `main`；
- pull request 到 `main`。

工作流使用 matrix 构建，不再只生成单一平台包。

## SDK 来源

SDK 不提交到本仓库。

当前 CI 从私有仓库下载命令行 SDK：

```text
liyan-lucky/HarmonyOS_SDK_Tools
```

当前推荐 SDK Release tag：

```text
linux_command_line_tool_6.1.1
```

当前推荐 SDK 资产格式：

```text
单包 .7z
```

安装脚本：

```text
scripts/install_combined_harmonyos_sdk.sh
```

安装目标：

```text
/home/runner/harmonyos-sdk/command-line-tools
```

脚本会自动识别完整 `command-line-tools` 布局，并要求最终存在：

```text
command-line-tools/hvigor/bin/hvigorw.js
command-line-tools/sdk/default/openharmony/native
command-line-tools/sdk/default/openharmony/native/build/cmake/ohos.toolchain.cmake
```

## 必需的 GitHub Actions 配置

### Secret

```text
HARMONYOS_SDK_TOKEN
```

用途：读取私有 SDK 仓库 `HarmonyOS_SDK_Tools` 的 Release 资产。

Token 至少需要能读取：

```text
liyan-lucky/HarmonyOS_SDK_Tools
```

不要把 Token 写入代码、文档示例输出、日志或 issue。

### Secret 或 Variable

```text
HARMONYOS_SDK_URL
```

用途：指定 SDK 来源。

可以填 Release tag 页面，例如：

```text
https://github.com/liyan-lucky/HarmonyOS_SDK_Tools/releases/tag/linux_command_line_tool_6.1.1
```

也可以填 Release 资产直链。直链失败时，脚本会尝试从 URL 解析 tag 或回退到 `linux_command_line_tool_6.1.1`。

## CI 环境变量

workflow matrix 会设置：

```text
BUILD_PLATFORM
BUILD_PLATFORM_NAME
BUILD_RUNTIME_OS
BUILD_ABI
BUILD_PRODUCT
BUILD_PACKAGE_SUFFIX
```

核心映射：

```text
HarmonyOS → BUILD_PRODUCT=default
OpenHarmony → BUILD_PRODUCT=openharmony_verify
```

## 构建脚本入口

GitHub Actions 第 8 步执行：

```bash
node scripts/build_hap_ci.js assembleHap
```

该脚本会：

1. 刷新构建时间并写入 `BuildInfo.ets`；
2. 注入 App “关于”页；
3. 预加载 CI 兼容补丁；
4. 选择 matrix 对应 product；
5. 调用 SDK 内的 `hvigorw.js`；
6. 传入 `product`、`module`、`pageType` 和资源编译参数。

## OpenHarmony CI 兼容补丁

当前 OpenHarmony 命令行 SDK 在 GitHub Actions 环境下会缺少部分本地 DevEco Studio 环境自动注入的信息。仓库中保留了若干 CI 专用兼容脚本，均由 `scripts/build_hap_ci.js` 预加载。

主要脚本：

| 脚本 | 作用 |
| --- | --- |
| `scripts/update_build_version.js` | 维护三段版本号，写入 App 元数据和 `BuildInfo.ets`。 |
| `scripts/patch_about_page_ci.js` | 在构建前把“关于”页和底部“关于”Tab 注入到 App 页面。 |
| `scripts/patch_openharmony_device_types_ci.js` | OpenHarmony CI 使用 `comic_reader_ci` 自定义设备和 syscap 文件，避免 SDK 内置设备能力集为空。 |
| `scripts/patch_sdk_info_paths.js` | 补齐 native、toolchains、restool、readelf、strip、cmake、ninja 等 SDK 路径 accessor。 |
| `scripts/patch_syscap_transform_ci.js` | 兜底处理 OpenHarmony syscap 工具路径、PackageHap 打包 jar 路径等 CI 缺失值。 |
| `scripts/link_ci_node_tools.js` | 为 OpenHarmony CI 准备项目本地 webpack 入口；当仓库没有 `webpack.config.js` 时跳过 webpack 并创建 loader 输出目录。 |
| `scripts/patch_jsonfile_empty_schema.js` | 兼容 SDK 内部空 schema 读取。 |
| `scripts/patch_prebuild_sdk_version_check.js` | 兼容 SDK 版本检查。 |
| `scripts/run_hvigor_with_sdk_patch.js` | 运行 hvigor 前加载 SDK 兼容补丁。 |

这些补丁只用于 CI 构建兼容，不代表正式 DevEco Studio 本地项目结构需要这样配置。

## 本地构建建议

本地开发建议直接使用 DevEco Studio：

1. 打开仓库根目录；
2. 等待 hvigor 同步；
3. 使用 `default` / `HarmonyOS` / `phone` 作为常规调试目标；
4. 配置本地签名；
5. 运行 `entry` 模块。

OpenHarmony 的 `openharmony_verify` 主要用于 CI 验证和 4 平台产物输出。

## 日志和诊断

每个 matrix job 都会上传：

```text
漫画浏览器-SDK安装日志-<matrix-package>
漫画浏览器-hvigor诊断日志-<matrix-package>
漫画浏览器-HAP产物-<matrix-package>
```

如果构建失败，优先检查：

1. 第 6 步：SDK 是否下载和解压成功；
2. 第 7 步：SDK 环境变量和路径是否正确；
3. 第 8 步：hvigor 构建错误；
4. `漫画浏览器-hvigor诊断日志-*`：详细任务链和堆栈；
5. `漫画浏览器-SDK安装日志-*`：SDK 包格式、Release 资产、解压路径。

## 维护原则

- 不把 SDK 压缩包、签名证书、私钥、Token 或 HAP/APP 发布包提交到仓库；
- SDK 私有仓库 Token 只放在 GitHub Actions secret 中；
- 如 SDK 版本、Release tag、资产格式或 artifact 命名发生变化，必须同步更新 `README.md`、`BUILDING.md` 和 `RELEASE_CHECKLIST.md`；
- 如新增第三方依赖或随 App 分发的资源，必须更新 `THIRD_PARTY_NOTICES.md` 和 `PRIVACY.md`；
- 如 CI 兼容补丁变更构建边界，必须更新 `COMPLIANCE.md` 和 `MAINTAINERS.md`。
