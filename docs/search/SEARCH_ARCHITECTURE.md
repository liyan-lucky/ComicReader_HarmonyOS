# 搜索架构

> 搜索已明确为不受目录限制的全网公开资源发现；最新分级规则流水线和 50+ 样本验收要求见 [`../SESSION_REQUIREMENTS_2026-08-31.md`](../SESSION_REQUIREMENTS_2026-08-31.md)。

## 搜索目标

- 默认无需 API Key 可用。
- 支持中文、英文关键词。
- 聚合公开 API、搜索引擎发现页和 HTML 规则源。
- 搜索结果默认以三列封面网格显示。
- 排列切换只在有结果时显示。

## 默认搜索顺序

### 搜索引擎

1. Bing 网页结果。
2. 百度网页结果（移动版 UA，`rn=50` 每页50条）。
3. DuckDuckGo HTML 结果。
4. Google 网页结果。
5. Yandex 网页结果。
6. 搜狗网页结果。
7. 360搜索网页结果。
8. Brave Search API（高级，需要 Key）。
9. Google Programmable Search API（高级，需要 Key + CX）。

### 查询词构建

- **auto 模式**：根据关键词语言智能追加。中文关键词追加"漫画"，英文关键词追加"manga comic"。不再使用 OR 布尔语法（百度不支持 OR，会导致结果污染）。
- **浏览器模式**：只使用基本查询词，不追加"在线阅读 章节"等查询变体，原样搜索。
- 调试信息中回显实际发送给搜索引擎的完整查询词（`buildEngineQuery` 构建结果）。

### API 搜索源（无需 Key）

已集成到 `searchApiSources()` 方法（`Index.ets`），源码在 `ApiSources.ets`：

1. **Internet Archive**：公开馆藏搜索，使用高级搜索 API。
2. **Wikimedia Commons**：图片搜索，使用 MediaWiki API。
3. **Open Library**：书籍搜索，使用 Open Library Search API。
4. **Library of Congress**：数字馆藏搜索，使用 LOC API。
5. **Pepper**：内置目录搜索，使用 Pepper API。

### 伪 URL 处理

API 搜索源的结果使用伪 URL 标识，在 `loadDetail()` 中分发：

| 伪 URL 格式 | 解析方法 | 说明 |
|---|---|---|
| `archive://item/<identifier>` | `loadArchiveDetail()` | Internet Archive IIIF/元数据解析 |
| `wikimedia://<url>` | 直接图片 | Wikimedia 图片直出 |
| `loc://<url>` | 直接图片 | Library of Congress 图片直出 |
| `pepper://<url>` | 图片解析 | Pepper 内置目录图片解析 |

### 搜索模式

- `mixed`：同时使用搜索引擎和 API 源（默认）。
- `engine_only`：只使用搜索引擎。
- `api_only`：只使用 API 搜索源。

### 结果筛选模式

- `rule_filter`（默认）：经 `looksComicRelated` + `isBlockedSearchResult` 筛选，只展示漫画相关结果，使用 APP 卡片样式（封面+标题+来源标记）。
- `browser`：不筛选，Web组件直接加载搜索引擎URL（Bing/百度等），CSS注入隐藏非结果元素。iframe方式无限滚动连续加载下一页。

切换方式：设置页 → 结果筛选 → 规则筛选 / 浏览器。选择持久化到 `@ohos.data.preferences`。

### 无限滚动分页（浏览器模式）

- Web组件全屏加载搜索引擎URL，`onPageEnd`时注入CSS+JS。
- CSS隐藏搜索框/导航栏/广告/分页栏，`body padding-top`让内容从HeaderOverlay下方开始。
- 滚动到底部（remain≤500）时创建隐藏iframe加载下一页URL。
- iframe.onload时提取搜索结果（`li.b_algo,.b_algo,#b_results .b_algo,.result,.c-container,.vrwrap,.res-list,.serp-item,.g .rc,.results > div`），用`document.importNode`追加到当前页面容器。
- 显示"— 第N页 —"分隔符，`_pageCount`递增。
- `_findNextUrl`支持：链接文本匹配（下一页/Next/›/»）+ `rel=next` + `sb_pagN` class + URL-based fallback（Bing `first=`、Baidu `pn=`、Google `start=`、Sogou `page=`）。
- `MutationObserver`监听DOM变化重新隐藏分页栏。
- `setInterval`每2秒更新调试信息（`position:fixed`调试div，条件显示）。

## 结果过滤

> 仅在 `rule_filter` 模式下生效。`browser` 模式跳过所有过滤。

过滤目标：

- 登录页。
- 付费页。
- VIP 页面。
- 已下架页面。
- 商城、百科、视频、社区等非阅读页面。

保留目标：

- 公开可访问漫画页。
- 官方公开目录或试读页。
- 公共馆藏。
- 可被规则解析的公开 HTML 页面。

### 屏蔽词同步

屏蔽词从规则仓库（`liyan-lucky/ComicReader_Rules`）的 `filter_words.txt` 同步，采用 INI 风格分段格式：

- `[DOMAINS]`：域名屏蔽列表，匹配结果 URL 域名时过滤。
- `[WORDS]`：标题屏蔽词，匹配结果标题时过滤。
- `[NOISE]`：噪声词，用于 `containsNoiseTitleWord` 噪声匹配（`SearchEngines.ets` 中已将三次遍历合并为一次）。

同步入口：更新菜单（UpdateDialog）→"同步屏蔽词"按钮。同步结果更新 `searchFilterConfig` 并持久化到 `@ohos.data.preferences`。

## 结果展示

默认：

- 三列图片网格。

可切换：

- 网格。
- 列表。

要求：

- 只在存在搜索结果时显示排列切换。
- 搜索首页不显示排列设置。
