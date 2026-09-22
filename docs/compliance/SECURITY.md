# 安全策略

## 支持范围

本仓库包含 HarmonyOS ArkTS Stage App 工程代码、配置文件、本地规则逻辑和 GitHub Actions 构建脚本。

当前 CI 从 SDK 工具仓库下载命令行 SDK，并生成 unsigned HAP artifact。SDK 包、签名材料和正式发布包不属于源代码仓库内容。

## 安全加固措施（2026-09-22 审计修复）

以下措施在 2026-09-22 全面安全审计后实施：

### 网络安全
- **SSL证书验证**：Web组件 `onSslErrorEventReceive` 调用 `handleCancel()` 拒绝不安全证书，防止中间人攻击
- **禁止混合内容**：Web组件 `mixedMode(MixedMode.None)` 禁止HTTPS页面加载HTTP子资源
- **本地文件隔离**：Web组件 `fileAccess(false).databaseAccess(false)` 禁止网页访问应用沙箱本地文件
- **HTTPS强制**：HttpClient对HTTP URL自动升级为HTTPS（仅允许127.0.0.1/localhost例外）
- **规则URL校验**：RuleValidator仅允许HTTPS规则URL（仅允许127.0.0.1/localhost例外）

### 资源管理
- **定时器统一清理**：Index.ets和WebBrowserPage添加 `aboutToDisappear` 生命周期钩子，统一清理所有setTimeout/setInterval
- **注入JS防重复**：setInterval移入styleInjected守卫内部，防止多次注入累积interval
- **Web页面恢复重试限制**：ERR_CONNECTION_CLOSED恢复最多重试3次，防止无限循环

### 数据安全
- **持久化队列**：persistData使用链式Promise队列消除并发flush导致的数据损坏
- **JSON解析校验**：所有JSON.parse结果添加Array.isArray类型校验，防止篡改数据导致崩溃
- **不可变更新**：applyCoverAccuracy使用对象展开创建新对象，不直接修改原对象

### 搜索安全
- **搜索竞态防护**：searchSelectedEngines/searchHtmlRuleSources/searchOnlineRuleDomains在Promise.all后检查searchGeneration，防止旧搜索结果污染新搜索
- **URL归一化去重**：appendResults使用normalizeUrl进行大小写不敏感+尾部斜杠归一化比较
- **startSearch顶层catch**：防止未处理的Promise rejection导致应用崩溃

## 需要报告的问题

如发现以下问题，请通过 GitHub Issue 或仓库维护者公开联系方式反馈：

- 私钥、签名证书、Token、Cookie、账号、API Key 等敏感信息被提交；
- App 意外上传搜索记录、书架、阅读历史或本地设置；
- 远程规则更新存在不安全来源、过宽校验或供应链风险；
- 网络请求存在危险重定向、非预期协议、任意文件读取或注入风险；
- Release 包混入本地配置、签名文件、调试缓存或不应发布的资源；
- GitHub Actions 日志、artifact 或脚本泄露 SDK 下载凭据；
- 构建脚本存在供应链污染风险，或会把 SDK 压缩包、临时缓存、unsigned HAP 误提交到仓库。

## 处理原则

1. 先临时移除高风险规则、域名、文件或 workflow；
2. 再复核来源、影响范围和修复方式；
3. 修复后更新合规、隐私或第三方说明；
4. 必要时创建 `backup/*` 分支保存回滚点。