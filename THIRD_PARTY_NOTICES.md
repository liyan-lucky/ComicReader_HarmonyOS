# 第三方来源说明

本文件用于记录 App 主仓库中的第三方平台、依赖、接口、规则来源和资源来源。

## 当前状态

- HarmonyOS / OpenHarmony / ArkTS / DevEco Studio / Hvigor：用于 App 开发和构建，遵循对应平台与工具链许可条款。
- HarmonyOS / OpenHarmony 命令行 SDK：CI 从私有仓库 `liyan-lucky/HarmonyOS_SDK_Tools` 下载，不提交到本仓库，也不随 App 源码分发。
- `@ohos` 系统 API：用于网络请求、WebView、应用生命周期等系统能力。
- 远程规则仓库：默认读取 `liyan-lucky/ComicReader_Rules` 的公开规则索引。
- 公开资源源：App 代码中可能包含公开网页、公共馆藏或搜索引擎相关规则，仅用于兼容识别和公开页面读取。
- UI 图标资源：后续所有应用内图标必须从 `https://proicons.com/` 上的开源图标集合获取，不自建设计图标，不复制来源不明图标。
- CI 构建工具：GitHub Actions 使用 Node、Java、p7zip、hvigor、ohpm、SDK toolchains 等工具生成 unsigned HAP artifact。

## 图标来源规则

App 使用图标前必须确认 ProIcons 对应集合页面的许可证，并在本文件补充具体清单。

记录格式：

| 资源名 | ProIcons 集合 | 原作者/项目 | 许可证 | 来源页面 | 是否随 App 分发 |
| --- | --- | --- | --- | --- | --- |
| 待添加 | 待确认 | 待确认 | 待确认 | 待确认 | 是 |

要求：

- 优先使用 SVG；
- 优先使用同一图标集合，保持视觉风格一致；
- MIT、Apache 2.0、ISC 等许可证需要保留归属说明；
- CC0 图标也建议记录来源；
- 不使用品牌 Logo 作为 App 自有品牌标识，除非符合对应品牌规则；
- 不提交字体包、来源不明图标包、截图裁剪图标或未授权 UI 包。

## CI 依赖说明

当前 GitHub Actions 会生成 4 个 unsigned HAP artifact：

- `comic-reader-hap-harmonyos-arm64`
- `comic-reader-hap-harmonyos-x86_64`
- `comic-reader-hap-openharmony-arm64`
- `comic-reader-hap-openharmony-x86_64`

OpenHarmony CI 兼容脚本可能在构建期间创建临时 `node_modules/webpack` 入口和中间输出目录。这些内容仅存在于 CI 工作区，不应提交到仓库，也不代表 App 随包分发了 webpack。

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

## 商标声明

仓库中出现的网站名、作品名、服务名、平台名和商标仅用于说明兼容目标或平台环境，相关权利归各自所有者所有。
