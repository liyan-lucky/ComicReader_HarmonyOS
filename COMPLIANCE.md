# 合规审计记录

## 当前范围

本仓库是 HarmonyOS ArkTS Stage 漫画浏览器 App 主仓库。公开源规则拆分到 `liyan-lucky/ComicReader_Rules`。

GitHub Actions 当前从私有 SDK 工具仓库 `liyan-lucky/HarmonyOS_SDK_Tools` 下载命令行 SDK，并生成 4 个 unsigned HAP 构建产物。SDK 压缩包、SDK 解压目录和 HAP 产物不应提交到本仓库。

## 当前 CI 构建状态

`Build ComicReader HAP` 工作流当前输出：

- `comic-reader-hap-harmonyos-arm64`
- `comic-reader-hap-harmonyos-x86_64`
- `comic-reader-hap-openharmony-arm64`
- `comic-reader-hap-openharmony-x86_64`

这些产物均为 unsigned HAP，仅用于构建验证和后续签名流程输入。

## 已检查项目

- README 已说明 App 与规则仓库拆分，并声明只处理公开可访问资源；
- README 和 BUILDING 已说明当前 4 平台 GitHub Actions 构建状态；
- `oh-package.json5` 和 `entry/oh-package.json5` 当前无第三方依赖声明，许可证已统一为 MIT；
- `build-profile.json5` 当前无签名配置，未发现签名证书路径；
- `module.json5` 当前仅申请 `ohos.permission.INTERNET`；
- 未通过关键词搜索发现明显硬编码密码、Token、Cookie、私钥、签名证书或账号数据；
- 未通过关键词搜索发现明显打包漫画图片、章节正文、字体、Logo、HAP/APP 发布包、SDK 压缩包或来源不明二进制资源；
- 远程规则默认来源为 `liyan-lucky/ComicReader_Rules` 的 `generated/index.json`；
- GitHub Actions 使用的 SDK 连接信息通过 Actions 配置注入，不应写入仓库文件。

## 已补充文件

- `LICENSE`
- `NOTICE.md`
- `DISCLAIMER.md`
- `PRIVACY.md`
- `SECURITY.md`
- `THIRD_PARTY_NOTICES.md`
- `CONTRIBUTING.md`
- `COPYRIGHT`
- `MAINTAINERS.md`
- `RELEASE_CHECKLIST.md`
- `BUILDING.md`
- `.editorconfig`
- `.gitattributes`
- `.github/CODEOWNERS`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/ISSUE_TEMPLATE/bug_report.md`
- `.github/ISSUE_TEMPLATE/feature_request.md`
- `.github/workflows/compliance-check.yml`
- `.github/workflows/manual-build-entry.yml`
- `.github/dependabot.yml`

## 已完成的代码加固

- `RemoteRuleService.ets`：限制远程规则 HTTPS、本地调试例外、固定 schema、规则数量上限，并使用统一规则校验器；
- `RuleValidator.ets`：新增公开规则字段、URL、长度、分页上限等校验；
- `UrlUtil.ets`：过滤 `file:`、`data:`、`blob:`、`javascript:`、`about:`、`intent:` 等危险 URL scheme；
- `HttpClient.ets`：限制 HTTP/HTTPS 请求，过滤非法 Header 名和值，避免换行注入；
- `HtmlParser.ets`：搜索结果、章节、图片、下一页 URL 均要求 HTTP/HTTPS；图片 URL 判断收窄，减少误抓非图片接口。

## CI 兼容边界

当前 OpenHarmony CI 构建包含若干兼容补丁，用于补齐命令行 SDK 在 GitHub Actions 环境下缺失的路径和中间产物。它们只服务于 CI 构建验证，不改变本地 DevEco Studio 常规开发流程。

关键脚本：

- `scripts/install_combined_harmonyos_sdk.sh`
- `scripts/build_hap_ci.js`
- `scripts/patch_openharmony_device_types_ci.js`
- `scripts/patch_sdk_info_paths.js`
- `scripts/patch_syscap_transform_ci.js`
- `scripts/link_ci_node_tools.js`

## 仍需长期注意

1. App 具有 INTERNET 权限，应确保隐私说明与实际行为一致；
2. 内置规则和远程规则应持续排除登录、付费、验证码、DRM、加密接口、反爬规避和专有客户端伪造；
3. 若上架应用商店，应避免使用可能被理解为盗版、破解或绕过付费的宣传语；
4. 如果后续加入第三方 SDK、图标、字体、统计、广告、崩溃上报或云同步，必须更新第三方声明和隐私说明；
5. 如果后续持久化用户 API Key，应采用平台安全存储，并更新隐私说明和安全说明；
6. 如果 SDK Release tag、SDK 包格式、构建 matrix 或 artifact 名称变化，必须同步更新 `README.md`、`BUILDING.md`、`RELEASE_CHECKLIST.md` 和本文件。

## 当前结论

当前检查未发现明显密钥泄露或受保护资源打包问题。基础许可证、合规文档、隐私说明、远程规则供应链防护、URL 过滤、HTTP 客户端校验、解析器安全边界和 4 平台 CI 构建说明均已补强。
