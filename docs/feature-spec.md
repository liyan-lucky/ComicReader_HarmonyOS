# ComicReader 功能规格文档

> 版本: 0.88.5 | 更新日期: 2026-09-20

## 1. 设置页面下拉列表优化

### 问题描述
设置页面中，图标颜色等下拉列表展开时会挤压下方容器，导致布局错乱。

### 解决方案
- 设置页面 Stack 添加 `.height(280)` 固定高度，防止下拉列表展开时挤压下方容器
- 创建 `pickerItemBg()` 和 `pickerBorder()` 颜色方法，统一下拉列表项的背景色和边框色
- `OptionPickerRow` 改为紧凑样式（更小的尺寸和字体）
- 下拉列表用 `Stack + position + zIndex` 方案（替代 `Stack + offset`），确保层级正确

### 关键代码位置
- `Index.ets` — 设置页面 Stack `.height(280)`
- `Index.ets` — `pickerItemBg()` / `pickerBorder()` 颜色方法
- `Index.ets` — `OptionPickerRow` Builder

---

## 2. "阅读全屏" Toggle 失效修复

### 问题描述
设置页面中"阅读全屏" Toggle 开关操作无效——点击 Toggle 后状态会自动恢复。

### 根因分析
1. **双重切换**: Toggle({ isOn: this.fullscreenReader }) 绑定 @State 变量时，Toggle 交互自动更新变量；同时父组件 Column 的 onClick 又切换同一变量，导致双重切换（两次切换相互抵消）
2. **偏好被覆盖**: `applyReaderFullscreen(enabled)` 方法同时承担窗口状态控制（临时）和偏好设置存储（持久）两个职责。退出阅读器时 `onBackPress()` 调用 `applyReaderFullscreen(false)` 恢复系统栏，但也把 `fullscreenReader` 偏好改成 false

### 解决方案
1. 去掉 Column 的 onClick，改用 Toggle 的 `onChange` 回调来处理偏好变更
2. `applyReaderFullscreen` 不再修改 `fullscreenReader`，只控制系统栏状态
3. 在需要修改偏好的地方（Toggle onChange、阅读器全屏按钮）手动设置 `this.fullscreenReader`

### 关键代码位置
- `Index.ets:~3265` — fullscreenReader Toggle onChange
- `Index.ets:~3285` — floatingReaderControls Toggle onChange
- `Index.ets:~696` — `applyReaderFullscreen()` 方法（不再修改偏好变量）
- `Index.ets:~3031` — 阅读器全屏按钮（手动设置偏好 + 调用 applyReaderFullscreen）

---

## 3. 文案修改

### 变更内容
- 中文: "阅读页全屏" → "阅读全屏"
- 英文: "Fullscreen Reader" → "Fullscreen"

---

## 4. 书架/历史页面网格与标题重叠修复

### 问题描述
书架和历史页面中，网格内容区域与页面标题文字重叠。

### 解决方案
- 调整网格内容顶部偏移量：`compactContentTopInset() + 26`（书架页面和历史页面各自调整）
- 不修改共享的 `compactContentTopInset()` 方法本身，以免影响设置页面和 logo 区域

### 关键代码位置
- `Index.ets:~4107` — 书架页面 `compactContentTopInset() + 26`
- `Index.ets:~4251` — 历史页面 `compactContentTopInset() + 26`

---

## 5. 书架/历史页面左右滑动切换

### 功能描述
- 书架页面: 左右滑动切换分类（catalogCategories）
- 历史页面: 左右滑动切换"历史"/"收藏"标签

### 交互设计
- 手指滑动时内容实时跟随平移
- 下一页内容从旁边逐渐显示（预渲染在旁边）
- 超过屏幕宽度 1/3 松手时平滑过渡切换，否则回弹到原位

### 实现方案
用 `Stack + PanGesture + translate` 实现连续平移动画：

- **当前内容**: `.translate({ x: shelfTranslateX })` 跟随手指平移
- **目标内容**: 预渲染在旁边，`.translate({ x: shelfTranslateX + direction * screenWidthVp })` 从旁边滑入
- **目标 Scroll**: 用 `hitTestBehavior(HitTestMode.None)` 避免拦截手势事件
- **松手判定**: 超过 `screenWidthVp / 3` 时用 `animateTo` 平滑切换，否则回弹
- **屏幕宽度**: 在 `aboutToAppear` 中通过 `display.getDefaultDisplaySync()` + `px2vp()` 获取

### 关键状态变量
- `shelfTranslateX` — 书架滑动偏移量
- `shelfSwipeTarget` — 书架滑动目标索引
- `shelfSwipeDirection` — 书架滑动方向（1 或 -1）
- `shelfSwipeItems` — 书架滑动时的目标分类项列表
- `historyTranslateX` — 历史页面滑动偏移量
- `screenWidthVp` — 屏幕宽度（vp 单位）

### 关键代码位置
- `Index.ets:~4104` — ShelfPage Stack + PanGesture + translate
- `Index.ets:~4248` — HistoryPage Stack + PanGesture + translate
- `Index.ets:~327` — aboutToAppear 中获取屏幕宽度

---

## 6. 章节列表框选已阅读章节

### 功能描述
在阅读器章节面板中，最后阅读的章节用边框框选标记，打开面板时自动滚动到该章节位置。

### 视觉效果
- 当前章节（`chapter.url === this.currentUrl`）:
  - 左右边框用 accent 颜色（2vp 宽度）
  - 上下边框用 borderSubtle 颜色（1vp 宽度）
  - 背景色: 半透明（深色模式 `#301E232F`，浅色模式 `#30FFFFFF`）
  - 圆角: 6vp
  - 字体颜色: accent 颜色
- 其他章节:
  - 仅底部边框（borderSubtle 颜色）
  - 无背景色
  - 字体颜色: primaryText 颜色

### 滚动行为
- 打开章节面板时，自动滚动到当前章节位置（`scrollToIndex(currentIndex, false, ScrollAlign.CENTER)`）
- 有 60ms 延迟以确保列表渲染完成

### 关键代码位置
- `Index.ets:~3058-3067` — 章节列表 ForEach 渲染（含框选样式）
- `Index.ets:186-194` — `openReaderChapterPanel()` 方法（含 scrollToIndex）

---

## 7. 全量构建模式

### 变更内容
- 构建脚本 `build_local.ps1` 从 `--incremental` 改为 `--full`
- 版本号自增逻辑: 全量构建时中间位（full）自增 1

### 关键文件
- `scripts/build_local.ps1` — 构建脚本
- `scripts/update_build_version.js` — 版本号自增逻辑
- `version.json` — 版本状态文件

---

## 8. 书本关联信息跨页面一致（数据链路统一）

### 需求背景
书本作为独立对象，其关联信息（最后阅读章节标题）应在书架（收藏）页面和历史页面一致显示。此前书架页面显示来源名称（sourceName），历史页面显示章节标题（chapterTitle），信息不一致。

### 变更内容
- 书架/收藏页面卡片副标题统一显示 `lastChapterTitle`（最后阅读章节标题）：
  - 网格卡片: `BookCard(item.title, item.url, item.cover, 'shelf', item.lastChapterTitle)`
  - 列表卡片: `BookListCard(..., item.lastChapterTitle + ' · ' + item.lastReadAt, ...)`
- 书本卡片书名强制单行显示: `maxLines(2)` → `maxLines(1)`，超出省略

### 关键代码位置
- `Index.ets:~4157/4296/4303/4325/4332` — 书架 ForEach 卡片副标题
- `Index.ets:~3952` — BookCard 书名 maxLines(1)

---

## 9. 章节列表框选最后阅读章节（从任意页面进入）

### 需求背景
从书架或历史页面点击书本进入阅读后，返回章节列表时，最后阅读的章节应带框选标记并自动滚动定位。此前仅历史页面进入时框选正常，书架进入时失效。

### 根因分析
`openBookshelfItem` 的 fallback 路径（详情页加载失败或章节 URL 不匹配时）直接构造章节对象调用 `loadChapter`，但**没有把该章节注入 `this.chapters`**。导致从阅读器返回时 `chapters.length === 0`，无法进入章节列表（回主页），自然无框选。而 `openHistoryItem` 的 fallback 会将章节写入 `this.chapters`，所以历史进入正常。

### 修复内容
1. `openBookshelfItem` fallback 构造 `fallbackChapter` 后，若 `this.chapters.length === 0` 则注入该章节并设置 `mode = 'chapters'`
2. 历史/书架 ForEach 的 keyGenerator 由 `item.url` 改为 `item.url + '|' + item.chapterTitle/lastChapterTitle`，避免持久化数据中重复 URL（如同一本书多条记录）导致 ArkUI 渲染异常（此前表现为历史页面只渲染1张卡片）

### 框选视觉效果
- 当前章节条目: accent 色粗体文字 + accent 色背景色块 + accent 色圆角边框
- 打开章节面板/返回章节列表时 `scrollToIndex(currentIndex, false, ScrollAlign.CENTER)` 自动滚动到该章节并居中

### 验证结果（2026-09-12 虚拟机实测）
- 历史页面进入《恰似寒光遇骄阳》→ 返回 → 第61话绿色边框框选 ✓
- 收藏页面进入《我真没想重生啊》（详情源失效走 fallback）→ 章节列表1条带框选 → 点击可正常阅读 ✓
- 收藏页面进入（详情源恢复时）→ 完整章节列表 → 第129话框选 + 自动滚动居中 ✓
- 历史页面6本书正常渲染（keyGenerator 修复后）✓
- 书名单行显示 ✓

---

## 10. 从书架进入时自动恢复阅读位置（框选标记）

### 需求背景
从书架点击一本书进入详情页后，章节列表应自动框选上次阅读的章节。此前从书架进入时章节列表无框选标记。

### 根因分析
`loadDetail` 有两条章节加载路径：
1. **Catalog manifest 路径**: 从预定义的 catalog manifest 中找到匹配源时，直接设置 `this.chapters` 并 `return`——**跳过了 `restoreReadingPosition` 调用**
2. **HTTP 请求路径**: 通过 HTTP 请求解析 HTML 获取章节，完成后调用 `restoreReadingPosition`

从书架进入的书通常在 catalog manifest 中有预定义章节列表，走的是路径 1，因此 `restoreReadingPosition` 从未被调用，`this.currentUrl` 保持为详情页 URL（非章节 URL），导致无框选。

### 修复内容
1. 在 catalog manifest 路径的 `return` 前添加 `this.restoreReadingPosition(url, title, rule.id)` 调用
2. 在 `restoreReadingPosition` 方法末尾添加 `this.scrollToCurrentChapter()` 调用，使章节列表自动滚动到框选章节的可见位置

### `restoreReadingPosition` 方法说明
- 从 `this.history` 中查找匹配的阅读记录
- 匹配条件优先级: detailUrl 精确匹配 → title + sourceId → title 宽松匹配
- 找到匹配后: 若 `match.url` 在 `this.chapters` 中则直接设置 `this.currentUrl`；否则追加章节到 `this.chapters` 再设置 `this.currentUrl`
- 设置 `this.currentUrl` 后调用 `this.scrollToCurrentChapter()` 自动滚动到该章节（居中显示）

### 关键代码位置
- `Index.ets:~1665` — catalog manifest 路径中调用 `restoreReadingPosition`（**新增**）
- `Index.ets:~1753` — HTTP 请求路径中调用 `restoreReadingPosition`
- `Index.ets:~1767` — `restoreReadingPosition()` 方法定义（含 `scrollToCurrentChapter` 调用）
- `Index.ets:~202` — `scrollToCurrentChapter()` 方法定义

### 验证结果（2026-09-12 虚拟机实测）
- 从书架进入《不存在的人》→ 章节列表自动框选第3话（上次阅读位置）✓
- 从书架进入《万人之上》→ 章节列表自动框选第20话 + 自动滚动到可见区域（第11~27话范围）✓

---

## 11. 搜索结果筛选模式切换（规则筛选 / 浏览器）

### 功能描述
设置页新增"结果筛选"选项，支持两种模式切换：
- **规则筛选**（默认）：经 `looksComicRelated` + `isBlockedSearchResult` 筛选，只展示漫画相关结果，APP 卡片样式。
- **浏览器**：不筛选，直接显示搜索引擎返回的全部结果，浏览器原样条目样式。

### 实现要点
- `SearchEngines.ets` 导出 `searchResultFilterMode` 全局变量 + `setSearchResultFilterMode()` 函数。
- `makeSearchItem()` 在浏览器模式下跳过 `isBlockedSearchResult` 和 `looksComicRelated` 筛选。
- `Index.ets` `@State searchResultMode` 驱动 UI 渲染分支。
- 设置持久化到 `@ohos.data.preferences`。

### 关键代码位置
- `SearchEngines.ets` — `searchResultFilterMode` + `setSearchResultFilterMode()`
- `SearchEngines.ets` — `makeSearchItem()` 浏览器模式跳过筛选
- `Index.ets` — 设置对话框"结果筛选"选项行

---

## 12. 浏览器模式搜索结果样式

### 功能描述
浏览器模式下搜索结果使用浏览器原样条目样式，替代 APP 卡片样式。

### 视觉效果
- 蓝色标题（可点击跳转内置浏览器）
- 绿色 URL
- 灰色摘要文本

### 关键代码位置
- `Index.ets` — `BrowserResultItem()` @Builder

---

## 13. 无限滚动分页

### 功能描述
搜索结果支持无限滚动，下滑到底部自动加载下一页。

### 实现要点
- `fetchSearchEngineResults(engine, keyword, query, page)` 支持 page 参数。
- Bing/百度/Google/DuckDuckGo/搜狗/360/Yandex 均支持分页 URL 构建。
- Scroll `onReachEnd` 触发 `loadMoreSearchResults()`。
- `@State searchPage` / `hasMoreResults` / `loadingMore` 控制分页状态。

### 关键代码位置
- `Index.ets` — `fetchSearchEngineResults()` page 参数
- `Index.ets` — `loadMoreSearchResults()` 方法
- `Index.ets` — Scroll `onReachEnd`

---

## 14. auto 模式查询词构建修复

### 问题描述
此前 auto 模式使用 OR 布尔语法追加关键词（如 `keyword OR 漫画`），但百度不支持 OR 运算，导致 OR 被当作字面搜索词污染结果。

### 解决方案
改为根据关键词语言智能追加：
- 中文关键词 → 追加"漫画"
- 英文关键词 → 追加"manga comic"
- 不再使用 OR 语法

### 关键代码位置
- `SearchEngines.ets:~413` — `buildEngineQuery()` auto 模式语言判断

---

## 15. 浏览器模式不追加查询变体

### 功能描述
浏览器模式下搜索只使用基本查询词，不追加"在线阅读 章节"等查询变体，原样搜索用户输入。

### 关键代码位置
- `Index.ets` — `searchSelectedEngines()` 浏览器模式分支

---

## 16. 搜索结果页搜索框可编辑

### 问题描述
搜索结果页的搜索框无法点击编辑，因为清除按钮的 Row（`.width('100%')`）覆盖在 TextInput 上方，拦截了点击事件。

### 解决方案
给清除按钮 Row 添加 `hitTestBehavior(HitTestMode.Transparent)`，让点击事件穿透到下方的 TextInput。

### 关键代码位置
- `Index.ets` — 搜索结果页清除按钮 Row

---

## 17. siteTypeTag 统一2字标记

### 功能描述
网址分类标记统一为2字格式：漫画/百科/字典/应用/视频/社交/资讯/购物/社区/政府/网页。标题含"漫画"即归漫画类。

### 关键代码位置
- `Index.ets:~1557` — `siteTypeTag(url, title)` 签名改为双参数

---

## 18. 内置浏览器漫画域名自动检测

### 功能描述
内置浏览器（WebBrowserPage）加载页面后自动检测当前 URL 是否为已知漫画域名，若是则显示绿色提示条"检测到漫画内容，点击使用阅读模式"。

### 实现要点
- `SourceRules.ets` 导出 `isComicDomain(url)` 函数，检查 URL 是否匹配已验证漫画域名（88个）+ 公开访问源（44个）+ 域名含 manhua/manga/comic 等关键词。
- `WebBrowserPage.ets` `onPageEnd` 调用 `isComicDomain(event.url)`，匹配时设置 `showReaderHint` 状态。
- 提示条 6 秒后自动消失。

### 关键代码位置
- `SourceRules.ets` — `isComicDomain()` 导出函数
- `WebBrowserPage.ets` — `onPageEnd` 检测 + 提示条 UI

---

## 19. 内置浏览器 HeaderOverlay 完全透明

### 功能描述
内置浏览器顶部浮层（返回按钮+阅读按钮）改为完全透明背景，移除磨砂模糊效果和半透明背景色，避免遮挡网页内容。

### 关键代码位置
- `WebBrowserPage.ets` — `HeaderOverlay()` 移除 `backgroundBlurStyle` 和 `backgroundColor`

---

## 20. Web 组件 User-Agent 设置

### 问题描述
Web 组件默认 User-Agent 被搜索引擎拒绝（返回 ERR_CONNECTION_RESET），桌面 UA 被百度验证码拦截。

### 解决方案
设置标准移动版 Chrome User-Agent：`Mozilla/5.0 (Linux; Android 13; Pixel 7) ...`

### 关键代码位置
- `WebBrowserPage.ets` — Web 组件 `.userAgent(...)`

---

## 21. 调试信息显示实际查询词

### 功能描述
搜索结果列表顶部的调试信息增加实际查询词回显，显示 `buildEngineQuery` 构建后发送给搜索引擎的完整查询词，便于排查搜索质量问题。

### 关键代码位置
- `Index.ets` — `@State debugSearchQueries` 状态变量
- `Index.ets` — 调试信息行渲染

---

## 22. 百度搜索建议 URL 屏蔽

### 问题描述
百度搜索建议页使用 `/s?word=` 参数（非 `wd`），原正则缺少 `word` 选项导致搜索建议页未被屏蔽。

### 解决方案
更新屏蔽正则，添加 `word` 选项。

### 关键代码位置
- `SearchEngines.ets:~286` — 屏蔽正则

---

## 23. 屏蔽词同步功能

### 功能描述
从规则仓库（`liyan-lucky/ComicReader_Rules`）下载 `filter_words.txt`，解析分段格式并更新本地屏蔽词配置，在更新菜单中提供独立同步入口。

### 文件格式
`filter_words.txt` 使用 INI 风格分段格式：

```text
[DOMAINS]
example.com
spam-site.net

[WORDS]
广告
赞助

[NOISE]
导航
首页
```

### 实现要点
- 在更新菜单（UpdateDialog）中添加"同步屏蔽词"按钮，独立触发同步流程。
- 下载 `filter_words.txt` 后按 `[DOMAINS]`/`[WORDS]`/`[NOISE]` 分段解析。
- 解析结果更新 `searchFilterConfig` 并通过 `@ohos.data.preferences` 持久化。
- 同步过程独立显示进度条和状态文本，跟随下载进度实时变化。

### 关键代码位置
- `Index.ets` — UpdateDialog 中"同步屏蔽词"按钮
- `SearchEngines.ets` — `searchFilterConfig` 配置与解析
- `Index.ets` — 同步流程与持久化

---

## 24. 更新菜单进度显示改进

### 功能描述
更新菜单中每个更新操作（规则/目录/屏蔽词）独立显示进度条和状态文本，进度条跟随下载进度实时变化。

### 变更内容
- 每个操作（更新规则/更新目录/同步屏蔽词）独立进度条 + 状态文本
- 进度条跟随下载进度实时变化（0~100%）
- 修复"更新目录"按钮错误调用 `updateAll()` 改为 `updateCatalog()`
- 目录更新显示当前数量→更新后数量差异（如"42 → 45"）

### 关键代码位置
- `Index.ets` — UpdateDialog 三个独立进度条与状态文本
- `Index.ets` — `updateCatalog()` 方法（修复错误调用）


