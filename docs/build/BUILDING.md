# 构建说明

本文记录 ComicReader_HarmonyOS 的本地构建、GitHub Actions 构建、版本号、SDK 来源和构建产物规则。

## 构建入口

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

安装 HAP：

```bash
bash scripts/hdc_install_hap.sh /path/to/app.hap
```

## 版本规则

App 使用三段版本号：

```text
主版本.全量构建号.增量构建号
```

版本状态文件：

```text
version.json
```

构建信息文件：

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

## GitHub Actions 构建

主构建 workflow：

```text
.github/workflows/manual-build-entry-advanced.yml
```

当前构建目标：

| Matrix package | Runtime OS | ABI | Product | Artifact |
| --- | --- | --- | --- | --- |
| `harmonyos-arm64` | `HarmonyOS` | `arm64-v8a` | `default` | `comic-reader-hap-harmonyos-arm64` |
| `harmonyos-x86_64` | `HarmonyOS` | `x86_64` | `default` | `comic-reader-hap-harmonyos-x86_64` |
| `openharmony-arm64` | `OpenHarmony` | `arm64-v8a` | `openharmony_verify` | `comic-reader-hap-openharmony-arm64` |
| `openharmony-x86_64` | `OpenHarmony` | `x86_64` | `openharmony_verify` | `comic-reader-hap-openharmony-x86_64` |

产物均为 unsigned HAP，只用于构建验证或后续签名流程输入。

## SDK 来源

SDK 不提交到本仓库。CI 从 SDK 工具仓库下载命令行 SDK：

```text
liyan-lucky/HarmonyOS_SDK_Tools
```

推荐 SDK Release tag：

```text
linux_command_line_tool_6.1.1
```

Actions 配置：

```text
HARMONYOS_SDK_TOKEN
HARMONYOS_SDK_URL
```

## CI 兼容脚本边界

允许存在的 CI 兼容脚本仅用于命令行 SDK 构建兼容，不允许再用于 UI 自动注入或 ArkTS 片段 patch。

当前允许的构建相关脚本包括：

| 脚本 | 作用 |
| --- | --- |
| `scripts/update_build_version.js` | 维护版本号并写入构建信息。 |
| `scripts/install_combined_harmonyos_sdk.sh` | 安装 CI 命令行 SDK。 |
| `scripts/build_hap_ci.js` | CI 构建入口。 |
| `scripts/patch_openharmony_device_types_ci.js` | OpenHarmony CI 设备能力兼容。 |
| `scripts/patch_sdk_info_paths.js` | SDK 路径 accessor 兼容。 |
| `scripts/patch_syscap_transform_ci.js` | OpenHarmony syscap 兼容。 |
| `scripts/link_ci_node_tools.js` | CI Node 工具兼容。 |
| `scripts/patch_jsonfile_empty_schema.js` | 空 schema 兼容。 |
| `scripts/patch_prebuild_sdk_version_check.js` | SDK 版本检查兼容。 |
| `scripts/run_hvigor_with_sdk_patch.js` | 运行 hvigor 前加载 SDK 兼容补丁。 |

禁止重新引入：

- 自动 UI 注入脚本；
- 自动 patch `Index.ets` 的脚本；
- 自动把关于页或 Tab 注入页面的构建前脚本。

## 本地构建建议

本地开发建议直接使用 DevEco Studio：

1. 打开仓库根目录；
2. 等待 hvigor 同步；
3. 使用 `default` / `HarmonyOS` / `phone` 作为常规调试目标；
4. 配置本地签名；
5. 运行 `entry` 模块。

## 日志和诊断

构建失败时优先检查：

1. SDK 是否下载和解压成功；
2. SDK 环境变量和路径是否正确；
3. hvigor 构建错误；
4. `comic-reader-hvigor-logs-*`；
5. `comic-reader-sdk-install-logs-*`。

## 维护原则

- 不提交 SDK 压缩包、签名证书、私钥、Token 或 HAP/APP 发布包；
- SDK 访问凭据只放在 GitHub Actions 配置中；
- SDK 版本、Release tag、资产格式或 artifact 命名变化时，必须同步更新文档中心。