# 漫画浏览器 · HarmonyOS

这是「漫画浏览器」鸿蒙 ArkTS Stage 项目。主仓库只放 App 工程代码；漫画公开源规则放到独立规则仓库，App 可以从 GitHub Raw 地址更新规则。

## 仓库拆分

- App 主仓库：`liyan-lucky/ComicReader_HarmonyOS`
- 规则仓库：`liyan-lucky/ComicReader_Rules`
- 默认远程规则地址：

```text
https://raw.githubusercontent.com/liyan-lucky/ComicReader_Rules/main/generated/index.json
```

## App 功能

- 三个 Tab：搜索 / 书架 / 设置
- 搜索现有主流搜索引擎
- 聚合公开 API / 公开 HTML 漫画源
- 按漫画名称归类显示
- 封面 + 名称 / 纯封面列表
- 章节列表
- 原生图片卷轴阅读
- 公开卷轴网页渲染兜底
- 书架和阅读历史
- 设置页可调整搜索、过滤、显示、阅读、规则等选项
- 从 GitHub 远程更新规则

## 导入 DevEco Studio

1. 打开 DevEco Studio。
2. 选择 **Open Project**。
3. 打开本仓库根目录。
4. 等待 hvigor 同步。
5. 配置签名后运行 `entry` 模块。

## 构建和签名

本仓库不提交签名证书、私钥或本地签名配置。

`build-profile.json5` 当前未包含签名配置。请在本地 DevEco Studio 中配置签名，确认 `.gitignore` 已排除证书、密钥和本地配置文件。

## 从 GitHub 更新规则

App 内：

```text
设置 → GitHub 远程规则 → 从GitHub更新规则
```

默认读取：

```text
https://raw.githubusercontent.com/liyan-lucky/ComicReader_Rules/main/generated/index.json
```

远程规则索引会进行基础安全校验：HTTPS、本地调试地址例外、固定 schema、规则数量上限和关键字段长度限制。

如果你把规则仓库改名，修改 App 设置里的远程地址即可。

## 合规边界

项目只处理公开可访问资源。不实现登录绕过、付费绕过、验证码绕过、DRM 绕过、加密接口破解、App 专属协议绕过或反爬规避。

本仓库不托管、不上传、不分发漫画图片、章节正文、付费内容、账号数据、签名证书、私钥、站点 Logo、字体、HAP/APP 发布包或其他第三方受保护资源。

## 隐私说明

App 申请 `ohos.permission.INTERNET`，用于访问用户选择的公开页面、公开 API、搜索引擎和远程规则索引。

App 可能在本地保存搜索设置、远程规则地址、书架、阅读历史、阅读偏好和用户手动填写的公开 API Key 或搜索配置。本仓库当前不应包含账号登录、广告 SDK、遥测统计、云同步或后台上传用户数据的逻辑。

## 许可证和合规文件

本仓库采用 MIT License。

相关文件：

- `LICENSE`
- `NOTICE.md`
- `DISCLAIMER.md`
- `PRIVACY.md`
- `SECURITY.md`
- `THIRD_PARTY_NOTICES.md`
- `CONTRIBUTING.md`
- `COMPLIANCE.md`
- `MAINTAINERS.md`

## 初始化并推送到 GitHub

```bash
git init
git add .
git commit -m "initial HarmonyOS comic reader app"
git branch -M main
git remote add origin https://github.com/liyan-lucky/ComicReader_HarmonyOS.git
git push -u origin main
```
