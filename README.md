# 漫画浏览器 · HarmonyOS

漫画浏览器是 HarmonyOS / OpenHarmony ArkTS Stage 应用。主仓库只放 App 工程代码；公开漫画源规则放在独立规则仓库，App 可从 GitHub Raw 地址更新规则。

## 当前定位

- 搜索公开漫画资源。
- 整理结果为列表。
- 打开章节并进行卷轴阅读。
- 保存阅读历史、书架记录和后续下载任务。

项目只处理公开可访问资源。不实现登录绕过、付费绕过、验证码绕过、DRM 绕过、加密接口破解、App 专属协议绕过或反爬规避。

## 当前 Tab

- 搜索
- 书架
- 历史
- 设置

关于信息整合到设置页，不再作为独立 Tab。

## 文档入口

所有长期文档统一放入：

```text
docs/
```

文档中心：

- [文档中心](docs/README.md)
- [构建说明](docs/build/BUILDING.md)
- [发布前检查](docs/release/RELEASE_CHECKLIST.md)
- [维护者说明](docs/maintenance/MAINTAINERS.md)
- [合规审计](docs/compliance/COMPLIANCE.md)
- [隐私说明](docs/compliance/PRIVACY.md)
- [安全策略](docs/compliance/SECURITY.md)
- [第三方来源说明](docs/compliance/THIRD_PARTY_NOTICES.md)
- [开发需求](docs/development/DEVELOPMENT_REQUIREMENTS.md)
- [开发问题记录](docs/development/DEVELOPMENT_ISSUES.md)
- [仓库规范](docs/development/REPOSITORY_STANDARDS.md)
- [文件放置规则](docs/development/FILE_PLACEMENT_RULES.md)
- [架构说明](docs/architecture/ARCHITECTURE.md)
- [搜索架构](docs/search/SEARCH_ARCHITECTURE.md)
- [规则系统](docs/search/RULE_SYSTEM.md)

## 仓库拆分

- App 主仓库：`liyan-lucky/ComicReader_HarmonyOS`
- 规则仓库：`liyan-lucky/ComicReader_Rules`
- SDK 工具仓库：`liyan-lucky/HarmonyOS_SDK_Tools`

默认远程规则地址：

```text
https://raw.githubusercontent.com/liyan-lucky/ComicReader_Rules/main/generated/index.json
```

## 分支规则

- `main`：当前唯一长期主分支。
- `backup`：当前主分支快照分支，可通过手动 workflow 强制覆盖。
- `backup/*`：历史回滚点。
- `feature/*`：较大功能开发。
- `fix/*`：问题修复。

`develop` 已删除。后续源码修改以直接替换完整文件为准，不再使用自动注入脚本或 UI 补丁 workflow。

## GitHub Actions

| 流程名 | 文件 | 用途 |
| --- | --- | --- |
| `高级构建漫画浏览器 HAP` | `.github/workflows/manual-build-entry-advanced.yml` | 手动构建 unsigned HAP。 |
| `合规检查` | `.github/workflows/compliance-check.yml` | 检查文档、许可证、合规和规则加固标记。 |
| `清理旧构建产物和流程记录` | `.github/workflows/cleanup-artifacts.yml` | 手动预览或清理 artifacts / workflow runs。 |
| `强制覆盖 backup 分支` | `.github/workflows/force-backup-main.yml` | 手动把 main 当前提交强制覆盖到 backup。 |

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