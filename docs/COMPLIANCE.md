# 合规审计记录

长期合规说明已归档到 `docs/compliance/`。

## 当前范围

本仓库是 HarmonyOS ArkTS Stage 漫画浏览器 App 主仓库。公开源规则拆分到 `liyan-lucky/ComicReader_Rules`。

## 当前仓库状态

根目录只保留 README、LICENSE、构建系统文件和工具必须识别的配置。构建、发布、维护、合规、隐私、安全、第三方来源和版权说明统一归档到 `docs/`。

## 合规边界

本仓库不托管、不上传、不分发漫画图片、章节正文、付费内容、账号数据、站点 Logo、字体、SDK 压缩包、HAP/APP 发布包或其他第三方受保护资源。

## CI 构建状态

GitHub Actions 当前输出 4 个 unsigned HAP artifact：

- `comic-reader-hap-harmonyos-arm64`
- `comic-reader-hap-harmonyos-x86_64`
- `comic-reader-hap-openharmony-arm64`
- `comic-reader-hap-openharmony-x86_64`

这些产物均为 unsigned HAP，仅用于构建验证和后续签名流程输入。

## 禁止重新引入

- UI 自动注入脚本；
- 自动 patch ArkTS 源码脚本；
- 构建前自动修改关于页或 Tab 的脚本；
- 临时 workflow；
- 根目录长期散落文档。

## 长期注意

1. App 具有 INTERNET 权限，应确保隐私说明与实际行为一致；
2. 内置规则和远程规则应持续排除登录、付费、验证码、DRM、加密接口、反爬规避和专有客户端伪造；
3. 若上架应用商店，应避免使用可能被理解为盗版、破解或绕过付费的宣传语；
4. 如后续加入第三方 SDK、图标、字体、统计、广告、崩溃上报或云同步，必须更新第三方声明和隐私说明。