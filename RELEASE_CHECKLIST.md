# 发布前检查清单

发布 HAP/APP 或创建 GitHub Release 前，请逐项检查：

## 代码和配置

- [ ] `oh-package.json5` 和 `entry/oh-package.json5` 的许可证为 MIT。
- [ ] `build-profile.json5` 没有提交本地签名证书路径或私钥配置。
- [ ] `module.json5` 当前仍只声明实际需要的设备类型；本地 HarmonyOS 调试通常使用 `phone`。
- [ ] `build-profile.json5` 中 `default` 对应 `HarmonyOS`，`openharmony_verify` 对应 `OpenHarmony`。
- [ ] 远程规则地址仍然指向可信来源。
- [ ] 远程规则加载仍包含 schema、数量上限、字段长度和 URL 协议校验。
- [ ] HTTP 请求仍限制为 HTTP/HTTPS。
- [ ] URL 工具仍过滤 `file:`、`data:`、`blob:`、`javascript:` 等危险 scheme。

## GitHub Actions 构建

- [ ] `Build ComicReader HAP` 工作流已成功完成 4 个 matrix job：
  - [ ] `harmonyos-arm64`
  - [ ] `harmonyos-x86_64`
  - [ ] `openharmony-arm64`
  - [ ] `openharmony-x86_64`
- [ ] Actions 已上传 4 个 unsigned HAP artifact：
  - [ ] `comic-reader-hap-harmonyos-arm64`
  - [ ] `comic-reader-hap-harmonyos-x86_64`
  - [ ] `comic-reader-hap-openharmony-arm64`
  - [ ] `comic-reader-hap-openharmony-x86_64`
- [ ] Actions 已上传 SDK 安装日志和 hvigor 诊断日志，便于回溯失败原因。
- [ ] `HARMONYOS_SDK_TOKEN` 仍只保存在 GitHub Actions Secret 中，没有写入仓库文件或日志。
- [ ] `HARMONYOS_SDK_URL` 指向当前可用的 SDK Release tag 或资产直链。
- [ ] 私有 SDK 仓库 `liyan-lucky/HarmonyOS_SDK_Tools` 的 Token 授权仍然有效。

## 资源和证书

- [ ] Release 包不包含 `.p12`、`.pfx`、`.jks`、`.keystore`、`.pem`、`.key` 等签名或私钥文件。
- [ ] Release 包不包含本地配置、测试账号、Cookie、Token 或 API Key。
- [ ] Release 包不包含 SDK 压缩包、SDK 解压目录、CI 临时缓存或构建日志中的敏感信息。
- [ ] Release 包不包含未授权漫画图片、章节正文、站点 Logo、字体或来源不明二进制资源。
- [ ] GitHub Actions 生成的 HAP 是 unsigned 产物；正式发布前已完成合法签名。

## 隐私和权限

- [ ] App 权限与实际功能一致，目前仅需要 INTERNET。
- [ ] 如果新增统计、广告、崩溃上报、账号登录或云同步，已更新 `PRIVACY.md`。
- [ ] 如果新增第三方 SDK、字体、图标、模板或依赖，已更新 `THIRD_PARTY_NOTICES.md`。

## 文档同步

- [ ] 如 SDK 仓库、Secret 名称、SDK Release tag、SDK 格式或 artifact 名称发生变化，已同步更新：
  - [ ] `README.md`
  - [ ] `BUILDING.md`
  - [ ] `COMPLIANCE.md`
  - [ ] `MAINTAINERS.md`
  - [ ] `THIRD_PARTY_NOTICES.md`
- [ ] 如 CI 兼容补丁新增或删除，已同步更新 `BUILDING.md` 的脚本说明。

## 法律和描述

- [ ] 应用描述不使用“破解”“免费看付费内容”“绕过限制”等高风险表述。
- [ ] 应用说明明确只处理公开可访问资源。
- [ ] 不宣传绕过登录、付费、验证码、DRM、加密接口、反爬或专有客户端协议。
