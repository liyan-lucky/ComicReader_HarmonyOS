# 发布前检查清单

发布 HAP/APP 或创建 GitHub Release 前，请逐项检查：

## 代码和配置

- [ ] `oh-package.json5` 和 `entry/oh-package.json5` 的许可证为 MIT。
- [ ] `build-profile.json5` 没有提交本地签名证书路径或私钥配置。
- [ ] 远程规则地址仍然指向可信来源。
- [ ] 远程规则加载仍包含 schema、数量上限、字段长度和 URL 协议校验。
- [ ] HTTP 请求仍限制为 HTTP/HTTPS。
- [ ] URL 工具仍过滤 `file:`、`data:`、`blob:`、`javascript:` 等危险 scheme。

## 资源和证书

- [ ] Release 包不包含 `.p12`、`.pfx`、`.jks`、`.keystore`、`.pem`、`.key` 等签名或私钥文件。
- [ ] Release 包不包含本地配置、测试账号、Cookie、Token 或 API Key。
- [ ] Release 包不包含未授权漫画图片、章节正文、站点 Logo、字体或来源不明二进制资源。

## 隐私和权限

- [ ] App 权限与实际功能一致，目前仅需要 INTERNET。
- [ ] 如果新增统计、广告、崩溃上报、账号登录或云同步，已更新 `PRIVACY.md`。
- [ ] 如果新增第三方 SDK、字体、图标、模板或依赖，已更新 `THIRD_PARTY_NOTICES.md`。

## 法律和描述

- [ ] 应用描述不使用“破解”“免费看付费内容”“绕过限制”等高风险表述。
- [ ] 应用说明明确只处理公开可访问资源。
- [ ] 不宣传绕过登录、付费、验证码、DRM、加密接口、反爬或专有客户端协议。
