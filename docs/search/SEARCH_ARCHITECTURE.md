# 搜索架构

## 搜索目标

- 默认无需 API Key 可用。
- 支持中文、英文关键词。
- 聚合公开 API、搜索引擎发现页和 HTML 规则源。
- 搜索结果默认以三列封面网格显示。
- 排列切换只在有结果时显示。

## 默认搜索顺序

### 搜索引擎

1. Bing 网页结果。
2. DuckDuckGo HTML 结果。
3. Google 网页结果。
4. Yandex 网页结果。
5. Brave Search API（高级，需要 Key）。
6. Google Programmable Search API（高级，需要 Key + CX）。

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

## 结果过滤

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

## 结果展示

默认：

- 三列图片网格。

可切换：

- 网格。
- 列表。

要求：

- 只在存在搜索结果时显示排列切换。
- 搜索首页不显示排列设置。
