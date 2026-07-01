# 第三方来源说明

本文件用于记录 App 主仓库中的第三方平台、依赖、接口、规则来源和资源来源。

## 当前状态

- HarmonyOS / OpenHarmony / ArkTS / DevEco Studio / Hvigor：用于 App 开发和构建，遵循对应平台与工具链许可条款。
- HarmonyOS / OpenHarmony 命令行 SDK：CI 从 SDK 工具仓库下载，不提交到本仓库，也不随 App 源码分发。
- `@ohos` 系统 API：用于网络请求、WebView、应用生命周期等系统能力。
- 远程规则仓库：默认读取 `liyan-lucky/ComicReader_Rules` 的公开规则索引。
- 公开资源源：App 代码中可能包含公开网页、公共馆藏或搜索引擎相关规则，仅用于兼容识别和公开页面读取。
- UI 图标资源：应使用有明确许可证和来源的开源图标，并在本文件记录。
- CI 构建工具：GitHub Actions 使用 Node、Java、p7zip、hvigor、ohpm、SDK toolchains 等工具生成 unsigned HAP artifact。

## 图标来源规则

App 使用图标前必须确认对应集合页面的许可证，并补充具体清单。

| 资源名 | 来源集合 | 原作者/项目 | 许可证 | 是否随 App 分发 |
| --- | --- | --- | --- | --- |
| `ic_search.svg` | Lucide Icons | Lucide Icons and Contributors | ISC / MIT 派生归属 | 是 |
| `ic_shelf.svg` | Lucide Icons | Lucide Icons and Contributors | ISC | 是 |
| `ic_history.svg` | Lucide Icons | Lucide Icons and Contributors | ISC | 是 |
| `ic_settings.svg` | Lucide Icons | Lucide Icons and Contributors | ISC | 是 |
| `ic_back.svg` | Lucide Icons | Lucide Icons and Contributors | ISC / MIT 派生归属 | 是 |
| `ic_add_shelf.svg` | Lucide Icons | Lucide Icons and Contributors | ISC | 是 |
| `ic_refresh.svg` | Lucide Icons | Lucide Icons and Contributors | ISC | 是 |
| `ic_more.svg` | Lucide Icons | Lucide Icons and Contributors | ISC / MIT 派生归属 | 是 |
| `ic_theme.svg` | Lucide Icons | Lucide Icons and Contributors | ISC | 是 |
| `ic_language.svg` | Lucide Icons | Lucide Icons and Contributors | ISC | 是 |

## 不应提交的内容

仓库不应提交第三方漫画图片、章节正文、站点 Logo、字体、签名证书、私钥、账号数据、HAP/APP 发布包、SDK 压缩包、SDK 解压目录、CI 临时缓存、来源不明图标或来源不明的二进制资源。

## 新增第三方内容时必须记录

如后续新增第三方依赖、图标、字体、模板、规则、接口 SDK 或资源文件，请补充：

- 名称；
- 原作者或权利人；
- 来源链接；
- 许可证或授权说明；
- 修改内容；
- 是否随 App 分发。