# 合规审计记录

## 当前范围

本仓库是 HarmonyOS ArkTS Stage 漫画浏览器 App 主仓库。公开源规则拆分到 `liyan-lucky/ComicReader_Rules`。

## 已检查项目

- README 已说明 App 与规则仓库拆分，并声明只处理公开可访问资源；
- `oh-package.json5` 和 `entry/oh-package.json5` 当前无第三方依赖声明；
- `build-profile.json5` 当前无签名配置，未发现签名证书路径；
- `module.json5` 当前仅申请 `ohos.permission.INTERNET`；
- 未通过关键词搜索发现明显硬编码密码、Token、Cookie、私钥、签名证书或账号数据；
- 未通过关键词搜索发现明显打包漫画图片、章节正文、字体、Logo、HAP/APP 发布包或来源不明二进制资源；
- 远程规则默认来源为 `liyan-lucky/ComicReader_Rules` 的 `generated/index.json`。

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

## 风险点

1. 远程规则属于供应链输入，应限制 schema、规则数量、URL 协议、字段长度和合规标记；
2. App 具有 INTERNET 权限，应确保隐私说明与实际行为一致；
3. 内置规则和远程规则应持续排除登录、付费、验证码、DRM、加密接口、反爬规避和专有客户端伪造；
4. 若上架应用商店，应避免使用可能被理解为盗版、破解或绕过付费的宣传语；
5. 如果后续加入第三方 SDK、图标、字体、统计、广告、崩溃上报或云同步，必须更新第三方声明和隐私说明。

## 当前结论

本次检查未发现明显密钥泄露或受保护资源打包问题。仓库主要缺口是许可证、合规文档、隐私说明和远程规则供应链防护；基础文件已补齐，远程规则校验建议继续加固。
