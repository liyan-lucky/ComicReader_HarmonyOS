# 漫画浏览器 · HarmonyOS

漫画浏览器是 HarmonyOS / OpenHarmony ArkTS Stage 应用。主仓库只放 App 工程代码；公开漫画源规则放在独立规则仓库，App 可从 GitHub Raw 地址更新规则。

## 当前定位

- 搜索公开漫画资源。
- 整理结果为列表。
- 打开章节并进行卷轴阅读。
- 保存阅读历史、收藏记录和后续下载任务。

项目只处理公开可访问资源。不实现登录绕过、付费绕过、验证码绕过、DRM 绕过、加密接口破解、App 专属协议绕过或反爬规避。

## 当前 Tab

- 搜索
- 书架
- 历史
- 设置

关于信息整合到设置页，不再作为独立 Tab。

## 文档入口

所有长期文档统一放入 [`docs/`](docs/README.md)。

重点文档：

- [开发需求](docs/development/DEVELOPMENT_REQUIREMENTS.md)
- [开发问题记录](docs/development/DEVELOPMENT_ISSUES.md)
- [仓库规范](docs/development/REPOSITORY_STANDARDS.md)
- [分支规则](docs/development/BRANCH_RULES.md)
- [UI 规范](docs/development/UI_RULES.md)
- [架构说明](docs/architecture/ARCHITECTURE.md)
- [搜索架构](docs/search/SEARCH_ARCHITECTURE.md)
- [规则系统](docs/search/RULE_SYSTEM.md)

## 仓库拆分

- App 主仓库：`liyan-lucky/ComicReader_HarmonyOS`
- 规则仓库：`liyan-lucky/ComicReader_Rules`
- 私有 SDK 工具仓库：`liyan-lucky/HarmonyOS_SDK_Tools`

默认远程规则地址：

```text
https://raw.githubusercontent.com/liyan-lucky/ComicReader_Rules/main/generated/index.json
```

## 开发分支规则

- `main`：稳定分支，只接收测试确认后的内容。
- `develop`：主要开发分支。
- `feature/*`：功能开发。
- `fix/*`：问题修复。

后续源码修改以直接替换完整文件为准，不再使用自动注入脚本或 UI 补丁 workflow。

## GitHub Actions

| 流程名 | 文件 | 用途 |
| --- | --- | --- |
| `高级构建漫画浏览器 HAP` | `.github/workflows/manual-build-entry-advanced.yml` | 手动构建 unsigned HAP。 |
| `合规检查` | `.github/workflows/compliance-check.yml` | 检查文档、许可证、合规和规则加固标记。 |
| `清理旧构建产物和流程记录` | `.github/workflows/cleanup-artifacts.yml` | 手动预览或清理 artifacts / workflow runs。 |

## 构建状态

GitHub Actions 高级构建流程支持 4 个 unsigned HAP 构建目标：

| 产物 | Runtime OS | ABI | Product | Artifact 名称 |
| --- | --- | --- | --- | --- |
| HarmonyOS ARM64 | `HarmonyOS` | `arm64-v8a` | `default` | `comic-reader-hap-harmonyos-arm64` |
| HarmonyOS x86_64 | `HarmonyOS` | `x86_64` | `default` | `comic-reader-hap-harmonyos-x86_64` |
| OpenHarmony ARM64 | `OpenHarmony` | `arm64-v8a` | `openharmony_verify` | `comic-reader-hap-openharmony-arm64` |
| OpenHarmony x86_64 | `OpenHarmony` | `x86_64` | `openharmony_verify` | `comic-reader-hap-openharmony-x86_64` |

CI 使用私有 SDK 仓库 `liyan-lucky/HarmonyOS_SDK_Tools` 的命令行 SDK。需要配置：

- `HARMONYOS_SDK_TOKEN`
- `HARMONYOS_SDK_URL`

完整构建说明见 [`BUILDING.md`](BUILDING.md)。

## 常用命令

```bash
bash scripts/build_full.sh
bash scripts/build_incremental.sh
bash scripts/hdc_install_hap.sh /path/to/app.hap
```

## 合规边界

本仓库不托管、不上传、不分发漫画图片、章节正文、付费内容、账号数据、签名证书、私钥、站点 Logo、字体、SDK 压缩包、HAP/APP 发布包或其他第三方受保护资源。

## 许可证

本仓库采用 MIT License。
