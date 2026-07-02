# 搜索与规则系统

## 搜索目标

- 默认无需 API Key 可用。
- 支持中文、英文关键词。
- 聚合公开 API、搜索引擎发现页和 HTML 规则源。
- 搜索结果默认以三列封面网格显示。
- 排列切换只在有结果时显示。

## 默认搜索顺序

1. Bing 网页结果。
2. DuckDuckGo HTML 结果。
3. Google 网页结果。
4. Yandex 网页结果。
5. Brave Search API（高级，需要 Key）。
6. Google Programmable Search API（高级，需要 Key + CX）。

## 结果过滤

过滤目标：

- 登录页、付费页、VIP 页面、已下架页面。
- 商城、百科、视频、社区等非阅读页面。

保留目标：

- 公开可访问漫画页、官方公开目录或试读页、公共馆藏、可被规则解析的公开 HTML 页面。

## 结果展示

- 默认三列图片网格，可切换为列表。
- 只在存在搜索结果时显示排列切换。
- 搜索首页不显示排列设置。

## 规则来源

按优先级和用途分为：

1. 内置生成规则：`GeneratedSourceRules.ets`。
2. 内置手工规则：`SourceRules.ets`。
3. 远程规则：`ComicReader_Rules/generated/index.json`。
4. 用户自定义规则：设置页粘贴 JSON。

## 远程规则

默认地址：

```text
https://raw.githubusercontent.com/liyan-lucky/ComicReader_Rules/main/generated/index.json
```

加载流程：

```text
读取 generated/index.json → 解析 rules 数组 → 过滤缺少关键字段的无效规则 → 远程规则放在本地规则前面 → 同名规则以远程优先
```

安全要求：

- 固定 schema、数量上限、URL 只能 HTTP/HTTPS、字段长度限制。
- 不允许本地危险地址（必要本地调试例外必须显式处理）。

加载策略：

- APP 默认加载内置规则，远程规则通过设置页手动更新。
- 后续目标：启动后静默尝试更新，失败时保留内置规则。

## 自定义规则

高级功能，放在设置页高级规则分区。必须校验 JSON 和 URL，不允许危险协议，不允许绕过登录、付费、验证码、DRM 或反爬。

## 推荐排查顺序

遇到"没有结果"或"远程规则没用"时：

```text
1. App 设置页远程规则条数是否大于 0
2. 规则仓库 generated/index.json 的 rules 是否为空
3. 规则有没有 searchUrl
4. 当前搜索模式是否启用了公开 HTML 规则
5. 搜索过滤是否把未验证公开源过滤掉
6. 直接粘贴公开详情页地址是否能解析
7. 章节页是否能提取图片或进入渲染卷轴兜底
```
