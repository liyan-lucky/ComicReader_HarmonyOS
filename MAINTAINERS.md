# 维护者说明

## 当前 CI 状态

当前 `构建漫画浏览器 HAP` 工作流已配置 4 平台 unsigned HAP 构建：

- HarmonyOS ARM64：`comic-reader-hap-harmonyos-arm64`
- HarmonyOS x86_64：`comic-reader-hap-harmonyos-x86_64`
- OpenHarmony ARM64：`comic-reader-hap-openharmony-arm64`
- OpenHarmony x86_64：`comic-reader-hap-openharmony-x86_64`

SDK 从私有仓库 `liyan-lucky/HarmonyOS_SDK_Tools` 下载。Actions 配置名为：

- `HARMONYOS_SDK_TOKEN`
- `HARMONYOS_SDK_URL`

## 合并前检查

合并代码、规则或文档变更前，请检查：

- 是否包含签名证书、私钥、Token、Cookie、账号数据或本地配置；
- 是否包含 SDK 压缩包、SDK 解压目录、漫画图片、章节正文、字体、Logo、HAP/APP 包或来源不明二进制文件；
- 是否涉及登录绕过、付费绕过、验证码绕过、DRM 绕过、加密接口破解、反爬规避或专有客户端伪造；
- 是否新增网络访问、WebView 行为、远程规则加载或用户数据存储；
- 是否已更新 `THIRD_PARTY_NOTICES.md`、`PRIVACY.md` 或 `COMPLIANCE.md`；
- 如果改动 CI、SDK、构建矩阵或 artifact 名称，是否已更新 `README.md`、`BUILDING.md` 和 `RELEASE_CHECKLIST.md`。

## CI 维护检查

构建流程相关改动合并前，请确认：

- `.github/workflows/manual-build-entry.yml` 仍包含 4 个 matrix package；
- `scripts/install_combined_harmonyos_sdk.sh` 仍能处理当前单包 `.7z` SDK；
- `scripts/build_hap_ci.js` 仍能根据 `BUILD_PRODUCT` 选择 `default` 或 `openharmony_verify`；
- OpenHarmony CI 兼容补丁仍只用于 CI，不污染本地 DevEco Studio 常规配置；
- GitHub Actions 产物仍是 unsigned HAP，不应当作为正式发布包直接分发。

## 发布前检查

发布 HAP/APP 前，请确认：

- Release 包不包含调试缓存、签名私钥、本地配置、测试账号、SDK 包或未授权资源；
- App 权限与实际功能一致；
- 远程规则默认地址可信且可回滚；
- 应用商店描述不使用“破解”“免费看付费内容”“绕过限制”等高风险表述；
- 免责声明和隐私说明与实际行为一致；
- unsigned HAP 已通过合法签名流程处理。

## 权利人请求处理

收到站点、平台或权利人请求时，优先临时移除相关规则、域名或说明，再复核来源和合法性。
