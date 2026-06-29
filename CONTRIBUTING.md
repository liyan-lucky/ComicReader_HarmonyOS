# 贡献指南

感谢改进 ComicReader_HarmonyOS。

## 提交前确认

贡献者提交内容前，请确认：

1. 内容由你原创，或你有权提交；
2. 没有提交漫画图片、章节正文、站点 Logo、字体、HAP/APP 包、SDK 压缩包、签名证书、私钥、账号数据、Cookie、Token 或本地用户配置；
3. 没有提交用于登录绕过、付费绕过、验证码绕过、DRM 绕过、加密接口破解、反爬规避或伪造专有客户端协议的代码；
4. 如参考第三方代码、规则、图标、字体、模板或 SDK，请记录来源、作者和许可证；
5. 修改远程规则加载、网络请求或 WebView 行为时，应说明安全影响；
6. 修改 GitHub Actions、SDK 下载、CI 兼容补丁、artifact 名称或构建矩阵时，应同步更新 `README.md`、`BUILDING.md` 和 `RELEASE_CHECKLIST.md`。

## 允许提交

- ArkTS / HarmonyOS App 功能改进；
- UI 和阅读体验修复；
- 公开网页读取规则兼容逻辑；
- 远程规则加载安全校验；
- 文档、合规和构建配置；
- GitHub Actions 构建脚本和 CI 兼容补丁，但不得引入密钥、私有 SDK 包或发布包。

## 不接受提交

- 版权漫画内容本身；
- 付费内容复制件；
- 破解、绕过、伪造客户端或规避访问控制的代码；
- 未经授权复制的第三方规则或资源；
- 来源不明的二进制文件；
- SDK 压缩包、SDK 解压目录、HAP/APP 产物、签名证书、私钥、Cookie、Token 或本地配置。

## CI 构建相关变更

当前 GitHub Actions 构建会输出 4 个 unsigned HAP artifact：

- `漫画浏览器-HAP产物-harmonyos-arm64`
- `漫画浏览器-HAP产物-harmonyos-x86_64`
- `漫画浏览器-HAP产物-openharmony-arm64`
- `漫画浏览器-HAP产物-openharmony-x86_64`

修改工作流、SDK 安装脚本、CI 兼容补丁、SDK 来源、SDK 包格式、artifact 命名或 matrix 组合时，Pull Request 必须说明影响范围和验证方式。

## PR 说明

Pull Request 应说明变更目的、影响范围、测试方式、是否新增依赖、是否涉及第三方来源以及是否影响隐私或安全。

如果修改构建流程，请附上 GitHub Actions 运行结果，至少确认 HarmonyOS ARM64、HarmonyOS x86_64、OpenHarmony ARM64、OpenHarmony x86_64 四个 matrix 的结果。
