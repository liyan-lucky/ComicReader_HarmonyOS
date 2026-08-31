# 搜索与规则系统

## 搜索目标

- 默认无需 API Key 可用。
- 支持中文、英文关键词。
- 聚合公开 API、搜索引擎发现页和 HTML 规则源。
- 搜索结果默认以三列封面网格显示。
- 排列切换只在有结果时显示。
- 搜索是全网公开资源发现，不受线上分类目录限制；目录和已验证书本仅作为域名发现、规则衍生和结果增强的种子。
- 输入聚焦显示最近 10 条搜索；提交后收起键盘；进入详情再返回时恢复结果滚动位置并描边最后点击项。
- 使用题材词和常见作品名进行至少 50 个样本回归，不能以单一结果视为正常。

完整流水线和验收要求见 [SESSION_REQUIREMENTS_2026-08-31.md](SESSION_REQUIREMENTS_2026-08-31.md)。

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

API 搜索源的结果使用伪 URL 标识，在 `loadDetail()` 中分发到对应的解析方法：

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

设置页高级规则区域有 TextInput 和"启用"按钮，用户输入 JSON 后点击"启用"即可解析并按 ID 去重后加入规则列表。

## 持久化

书架/历史/主题/语言通过 `@ohos.data.preferences` 持久化存储，App 重启后数据保留。

- 书架条目上限 100 条。
- 历史条目上限 40 条。

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
