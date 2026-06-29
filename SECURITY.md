# 安全策略

## 支持范围

本仓库包含 HarmonyOS ArkTS Stage App 工程代码、配置文件、本地规则逻辑和 GitHub Actions 构建脚本。

当前 CI 从私有 SDK 工具仓库下载命令行 SDK，并生成 4 个 unsigned HAP artifact。SDK 包、签名材料和正式发布包不属于源代码仓库内容。

## 需要报告的问题

如发现以下问题，请通过 GitHub Issue 或仓库维护者公开联系方式反馈：

- 私钥、签名证书、Token、Cookie、账号、API Key 等敏感信息被提交；
- App 意外上传搜索记录、书架、阅读历史或本地设置；
- 远程规则更新存在不安全来源、过宽校验或供应链风险；
- 网络请求存在危险重定向、非预期协议、任意文件读取或注入风险；
- Release 包混入本地配置、签名文件、调试缓存或不应发布的资源；
- GitHub Actions 日志、artifact 或脚本泄露 SDK 下载凭据、私有仓库地址以外的敏感内容；
- 构建脚本存在供应链污染风险，或会把 SDK 压缩包、临时缓存、unsigned HAP 误提交到仓库。

## CI 安全注意事项

- `HARMONYOS_SDK_TOKEN` 只应配置在 GitHub Actions Secret 中；
- `HARMONYOS_SDK_URL` 可以配置为 Actions Secret 或 Variable；
- SDK 压缩包和解压目录只应存在于 runner 临时目录；
- `comic-reader-hap-*` 是 unsigned HAP artifact，不能直接视为正式发布包；
- 修改 CI 兼容补丁时，应检查是否会扩大网络访问、泄露路径或写入不应提交的文件。

## 非安全问题

普通 UI 问题、规则失效、目标站结构变化、搜索结果不准确、阅读器显示异常等，请按普通 Issue 提交。

## 处理原则

维护者可以在确认问题后删除文件、回滚提交、移除规则、禁用远程来源、吊销泄露凭据或临时停止发布流程。
