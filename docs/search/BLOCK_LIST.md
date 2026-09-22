# 搜索屏蔽列表设计文档

## 机制概述

搜索结果过滤由 `SearchEngines.ets` 中 `isBlockedSearchResult()` + `looksComicRelated()` 两级把关，配置项集中在 `searchFilterConfig`：

| 配置项 | 作用 | 匹配方式 |
|---|---|---|
| `blockedDomains` | 屏蔽非漫画域名（视频站/社区/教育等） | `containsAny`：条目是 URL/host 的**子串**即命中 |
| `blockedWords` | 屏蔽标题/描述含非漫画词的结果 | `containsAny` 子串匹配，漫画站内豁免 |
| `noiseTitleWords` | 噪音标题词（图片/举报/帮助等） | 精确/前缀/后缀匹配 |

## 子串匹配的根域名误伤风险

`containsAny(text, values)` 判断 `values[i]` 是否为 `text` 的子串。这意味着：

> **屏蔽根域名会误伤所有子域。**

例如添加 `sohu.com`：
- `acg.sohu.com`.indexOf(`sohu.com`) >= 0 → **命中屏蔽**
- `tv.sohu.com`、`news.sohu.com`、`m.sohu.com` 全部命中

因此屏蔽列表的条目粒度分为两级：
- **根域名条目**（如 `zhihu.com`、`douyin.com`）：屏蔽该域名所有子域，适用于该域名下无任何漫画内容的站点
- **子域名/路径条目**（如 `v.qq.com`、`bilibili.com/video`）：精确屏蔽特定子域或路径，保留同根的其他子域

## 白名单豁免机制

`isBlockedSearchResult()` 中有三层白名单，命中时跳过 `blockedDomains` 检查：

### 1. `officialComic` — 官方漫画站白名单
```typescript
lowerUrl.indexOf('ac.qq.com/') >= 0 || lowerUrl.indexOf('manga.bilibili.com/') >= 0 ||
  lowerUrl.indexOf('bilibili.com/manga') >= 0 || ... ||
  lowerUrl.indexOf('acg.sohu.com/') >= 0
```
即使 URL 命中 `blockedDomains`，只要在 `officialComic` 白名单中即放行。**这是根域名屏蔽 + 漫画子域保护的核心机制。**

### 2. `isSearchResultPage` — 搜索引擎结果页白名单
```typescript
host === 'm.baidu.com' || host === 'www.baidu.com' ||
  lowerUrl.indexOf('cn.bing.com/search') >= 0 || ...
```
搜索引擎自身页面不屏蔽（结果页可能包含漫画链接）。

### 3. `PREFERRED_COMIC_DOMAINS` — 首选漫画域名
`isPreferredComicDomain(url)` 用于 `blockedWords` 检查的豁免：漫画站内标题含"教育"等词（如《教育漫画》）不屏蔽。

## sohu.com 修改案例（2026-09-21）

### 变更内容
| 位置 | 修改 |
|---|---|
| `blockedDomains` | `tv.sohu.com` → `sohu.com`（根域名屏蔽所有 sohu 子域） |
| `officialComic` 白名单 | 新增 `acg.sohu.com/`（搜狐动漫频道豁免） |
| `PREFERRED_COMIC_DOMAINS` | 新增 `acg.sohu.com`（屏蔽词豁免） |

### 效果
| URL | 结果 | 机制 |
|---|---|---|
| `acg.sohu.com/comic/123` | ✅ 通过 | officialComic 白名单豁免 |
| `tv.sohu.com/v/abc` | ❌ 屏蔽 | sohu.com 子串命中，无白名单 |
| `news.sohu.com/article/1` | ❌ 屏蔽 | 同上 |
| `m.sohu.com/news/1` | ❌ 屏蔽 | 同上 |

### 维护原则
> **添加根域名屏蔽时，必须同步把该域名下的漫画子域加入 `officialComic` 白名单和 `PREFERRED_COMIC_DOMAINS`。**

反之，如果该根域名下**没有任何漫画子域**（如 `zhihu.com`、`douyin.com`），直接加根域名即可，无需白名单。

## 用户自定义入口

屏蔽列表与白名单均已暴露到设置页（设置 → 规则设置），用户可自行编辑：

| 编辑入口 | 配置项 | 匹配方式 | 持久化键 |
|---|---|---|---|
| 屏蔽域名 | `blockedDomains` | URL/host 子串 | `custom_blocked_domains` |
| 屏蔽词 | `blockedWords` | 标题/描述子串 | `custom_blocked_words` |
| 噪音标题词 | `noiseTitleWords` | 精确/前缀/后缀 | `custom_noise_words` |
| 官方漫画白名单 | `officialComicDomains` | URL 子串，命中即跳过域名屏蔽 | `custom_official_comic_domains` |
| 首选漫画域名 | `preferredComicDomains` | host 子串，命中即豁免屏蔽词 | `custom_preferred_comic_domains` |

编辑方式统一为全屏文本编辑器，每行一条，保存后即时生效并持久化到 Preferences。

### 默认值 vs 用户值
- `SearchEngines.ets` 中的 `searchFilterConfig` 各字段是**默认值**，仅对新安装/重置后生效
- 已安装用户在设置页修改过任一列表后，Preferences 中的值覆盖默认值
- **如需让已安装用户生效，用户需在设置页对应入口手动编辑**

## 当前默认屏蔽域名清单

| 条目 | 粒度 | 屏蔽对象 | 漫画子域豁免 |
|---|---|---|---|
| `iqiyi.com` | 根域名 | 爱奇艺全站 | 无 |
| `youku.com` | 根域名 | 优酷全站 | 无 |
| `v.qq.com` | 子域名 | 腾讯视频 | 无（ac.qq.com 不含 v.qq.com 子串） |
| `sohu.com` | 根域名 | 搜狐全站 | `acg.sohu.com`（officialComic + PREFERRED） |
| `v.baidu.com` | 子域名 | 百度视频 | 无 |
| `bilibili.com/video` | 路径 | B站视频区 | manga.bilibili.com / bilibili.com/manga（officialComic） |
| `douyin.com` | 根域名 | 抖音全站 | 无 |
| `kuaishou.com` | 根域名 | 快手全站 | 无 |
| `zhihu.com` | 根域名 | 知乎全站 | 无 |
| `.edu.` | 子串 | 教育站点 | 无 |
| `coursera` | 子串 | Coursera | 无 |
| `udemy` | 子串 | Udemy | 无 |
| `zhangmen.com` | 根域名 | 掌门教育 | 无 |
| `zhangmenbaby.com` | 根域名 | 掌门教育（幼儿） | 无 |
