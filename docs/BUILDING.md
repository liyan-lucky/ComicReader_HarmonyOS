# 构建说明

本文记录 ComicReader_HarmonyOS 的本地构建、GitHub Actions 构建、版本号、SDK 来源和构建产物规则。

## 构建入口

增量构建（日常开发）：

```bash
bash scripts/build.sh incremental
```

全量构建：

```bash
bash scripts/build.sh full
```

安装 HAP：

```bash
bash scripts/install.sh
```

本地构建需设置 `JAVA_HOME` 指向 DevEco Studio 自带 JBR：

```powershell
$env:JAVA_HOME = "C:\Program Files\Huawei\DevEco Studio\jbr"
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
```

## 版本规则

App 使用三段版本号：`主版本.全量构建号.增量构建号`。

版本状态文件：`version.json`
构建信息文件：`entry/src/main/ets/common/BuildInfo.ets`

构建脚本会同步更新：`AppScope/app.json5`、`oh-package.json5`、`entry/oh-package.json5`、`BuildInfo.ets`。

## GitHub Actions 构建

唯一构建入口：

```text
Actions → APP手动构建入口 → Run workflow
```

对应文件：`.github/workflows/manual-build-entry.yml`

复杂构建逻辑放在：`scripts/github_build_harmonyos_linux.sh`

### Actions 配置变量

进入 `Settings → Secrets and variables → Actions → Variables`，添加：

| 变量名 | 用途 |
|--------|------|
| `HARMONYOS_SDK_URL` | 完整 HarmonyOS SDK 压缩包下载链接 |
| `HARMONYOS_FULL_URL` | SDK 以外的命令行工具、hvigor、ohpm 补充文件 |

压缩包应包含：`openharmony`、`hms`、`sdk-pkg.json`、`command-line-tools`。

### 构建流程

```text
拉取源码 → 准备 Java 17 → 准备 Node 20 → 安装系统工具 → 执行构建脚本 → 下载 SDK → 合并补充工具 → 安装 ohpm 依赖 → 临时未签名构建 → 执行 assembleHap → 上传 HAP 产物
```

产物目录：`/tmp/comic_reader_harmonyos_artifacts`
Actions 产物名称：`comic-reader-hap`

## CI 兼容脚本

允许存在的 CI 兼容脚本仅用于命令行 SDK 构建兼容，禁止重新引入自动 UI 注入脚本或自动 patch `Index.ets` 的脚本。

## 线上构建排错经验

### 1. 手动入口能看到但点击无反应

现象：能看到 workflow 和手动状态，但点击 Run workflow 没反应，运行时间 0 秒。

处理：先用极简入口验证 Actions 权限，再把构建逻辑接入；不要在 workflow 文件里堆太多脚本。

### 2. runner.temp 不能放在 job 顶层 env

错误：`Invalid workflow file — Unrecognized named-value: 'runner'`

原因：job 顶层 `env` 解析时还没进入 runner 环境。

处理：使用固定路径 `/tmp/comic_reader_harmonyos_artifacts`。

### 3. 长脚本不要直接写进 workflow

复杂逻辑放到 `scripts/github_build_harmonyos_linux.sh`，workflow 只保留拉源码、准备环境、调用脚本、上传产物。

### 4. 不要在入口里写太复杂的表达式

`secrets.XXX || vars.XXX` 这类表达式容易让问题变复杂。当前只读取 `vars.XXX`。

## 本地构建建议

1. 打开仓库根目录，等待 hvigor 同步。
2. 使用 `default` / `HarmonyOS` / `phone` 作为常规调试目标。
3. 配置本地签名，运行 `entry` 模块。

## 构建失败排查

1. SDK 是否下载和解压成功。
2. SDK 环境变量和路径是否正确。
3. hvigor 构建错误日志。
4. `app.json5` 是否被构建脚本清空（需 `git checkout HEAD -- AppScope/app.json5`）。
5. `build-profile.json5` 版本号是否被修改导致 `Configuration Error`（需恢复）。

## 维护原则

- 不提交 SDK 压缩包、签名证书、私钥、Token 或 HAP/APP 发布包。
- SDK 访问凭据只放在 GitHub Actions 配置中。
