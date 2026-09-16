# 跨对话任务交接

> 新对话接棒入口。按时间倒序记录。

## 2026-09-16 自定义规则编辑器 + 屏蔽规则 + 搜索优化 + 项目清理

### 已完成

1. **自定义规则编辑器键盘/光标修复** — `openEditorFullscreen` 中添加 `getFocusController().requestFocus('customRuleTextArea')`，TextArea 添加 `onTextSelectionChange` 回调跟踪 Ln/Col 光标位置
2. **屏蔽规则功能** — 新增 `blockedUrls: string[]`、`editorMode`、`editorEditable` 状态变量；规则对话框新增"屏蔽列表"行；`applyBlockedUrls()` 保存 JSON 字符串数组；`isUrlBlocked()` 在 `appendResults` 中过滤屏蔽 URL；持久化到 Preferences
3. **远程规则查看** — "远程规则"点击改为打开编辑器只读查看 JSON 内容；新增"更新远程规则"按钮独立触发更新
4. **搜索逻辑优化** — `rebuildEffectiveRules` 改为 `merge(onlineRules, merge(DEFAULT_SOURCES, advancedRules))`，顺序：自定义→内置→远程；`searchHtmlRuleSources` 规则上限从 8 提升到 30
5. **编辑器UI改进** — 右上角箭头改为 `ic_more_vert.svg` 三点图标；工具栏新增 `ic_keyboard.svg` 键盘触发图标；编辑模式改为 Row 布局：左侧行号 Column + 1px 竖分界线 + TextArea；`onContentScroll` 同步行号滚动；READ 模式行号 onClick 触发编辑
6. **内置规则行号点击 bug 修复** — 新增 `editorEditable` 区分可编辑内容（自定义规则/屏蔽列表=true）和只读内容（内置规则/远程规则=false）；行号 onClick 仅对 `editorEditable=true` 调用 `editorEditAtLine`
7. **"高级规则"重命名为"自定义规则"** — 翻译键 `advanced_rules` 中文值改为"自定义规则"，英文改为"Custom Rules"
8. **项目清理** — 删除垃圾文件（`0`、`10`、`nul`、`appfreeze-111339.log`、`15_ComicReader_Rules` 符号链接）；更新 `.gitignore` 排除 `.codegraph/`、`.appanalyzer/`、`.codeartsdoer/`、`.tmp/`；删除 12 个重复顶层 docs 文件（子目录版本为规范版本）

### 关键技术决策

- **ArkTS API 限制** — `TextAreaAttribute` 不支持 `caretPosition` 属性，需用 `onTextSelectionChange` 回调配合计算；`onTextSelectionChange` 签名是 `(selectionStart: number, selectionEnd: number) => void`
- **`@Builder` 参数按值传递** — `string` 类型参数不响应 @State 变化，需用状态变量直接引用
- **Toggle `isOn` 非双向绑定** — 需添加 `onChange` 回调
- **规则合并顺序** — `mergeRules(A, B)` 返回 `[...B, ...A]`（B 优先，A 按 id 去重追加）

### 验证证据

- v0.87.44 构建通过，多次构建安装验证通过

### 未完成边界

- `Index.ets` 单文件仍然过大（6235+ 行），待拆分
- `GeneratedSourceRules.ets` 已删除，规则统一由 `SourceRules.ets` 管理

## 2026-09-14 主题/语言就地展开 + 箭头图标颜色统一

### 已完成

1. **箭头图标颜色统一** — LinkRow 箭头颜色从 `iconColor(arrowIcon)` 改为 `iconColor(icon)`，使箭头跟随行图标的多彩色配置（之前箭头始终为灰色）
2. **主题/语言就地展开（覆盖式 overlay）** — 取消旧的对话框方式，改为点击行后就地展开选项列表：
   - 无标题、55%宽度、右对齐（position x:'45%'）
   - 覆盖在下方内容之上（position + zIndex(999)），不挤压下方布局
   - 互斥效果：展开主题时语言自动收起，反之亦然
   - 选项行有单选圆圈标识，点击选项后自动关闭展开
   - 箭头图标随展开状态切换：展开时向上（ic_chevron_up），收起时向下（ic_chevron_down）
3. **Area.position.y 类型修复** — ArkUI 中 `Area.position.y` 是 `Length` 类型（可能 undefined），不能直接做加法，需用 `Number()` 转换

### 关键技术决策

- **Stack + height(0) 方案失败** — height(0) 导致 Stack visible=false，子元素不渲染
- **最终方案：Column + position + zIndex** — position 让 Column 脱离常规流不占空间，zIndex(999) 确保浮在最上层覆盖下方内容

### 验证证据

- v0.86.4 构建通过（0 ERROR，17 WARN）
- 虚拟机验证：语言展开 → 选项列表浮动覆盖在"阅读全屏"之上 → 点击"暗黑"选项 → 主题切换为暗黑模式 + 选项列表自动关闭
- dumpLayout 确认：选项行 visible=true、bounds 正确（右对齐 x=605-1208，55%宽度）、下方内容 bounds 未改变（未被挤压）

### 未完成边界

- `Index.ets` 单文件仍然过大（5288+ 行），待拆分
- ThemeDialog/LanguageDialog Builder 方法仍保留在代码中（不再被渲染调用，但未删除）
- 截图分析对箭头方向判断不准确（实际展开时箭头已切换为向上，但 analyzeImage 偶尔误判为向下）

## 2026-09-14 书架Tab目录推荐卡片恢复阅读位置

### 已完成

1. **书架Tab点击已读书恢复章节** — CatalogItemCard onClick 之前只 loadDetail 停在详情页（无框选无恢复）；现在先查书架数据（shelfMatch.lastChapterUrl）→ 再查历史记录（histMatch.detailUrl+url）→ 有则走 openBookUnified 恢复章节，无则 loadDetail 停详情页
2. **openBookUnified 改为停在章节目录** — 有阅读历史时不再自动 loadChapter 跳阅读器，而是设置 currentUrl=chapterUrl + scrollToCurrentChapter()，停在章节目录页框选上次阅读章节，由用户自行选择是否继续阅读

### 验证证据

- v0.85.7 构建通过（0 ERROR，17 WARN）
- 书架Tab点击《一天的一天》（已读第1话）→ 停在章节目录页 → 第1话绿色框选+滚动定位正确

### 未完成边界

- `Index.ets` 单文件仍然过大（5233+ 行），待拆分

### 已完成

1. **openBookUnified 统一入口** — 新增统一方法（loadDetail → 章节匹配 → fallback注入 → loadChapter），书架/历史/搜索三个入口复用同一套逻辑
2. **历史入口封面修复** — openHistoryItem 之前不设置 currentCover，addHistory 会把上一本书的封面串进新历史记录；现在统一传入 `item.cover`
3. **搜索入口封面修复** — openSearchResult 同样补上 `this.currentCover = first.cover`，消除封面串扰
4. **历史入口 fallback 保留目录** — 之前 `this.chapters = [单章]` 直接覆盖完整目录（数据断层主因）；统一后与书架一致：保留完整章节列表并追加 fallback
5. **书架入口收敛** — openBookshelfItem 缩减为一行调用 openBookUnified
6. **addCurrentToShelf 脏数据修复** — 详情页点"+"添加书架时之前把详情页URL误记为 lastChapterUrl（导致书架点击后错误尝试"阅读详情页"失败回列表）；现在仅 mode='reader' 时记录章节，且已存在的书保留原阅读进度
7. **openBookUnified 防御** — chapterUrl 等于 detailUrl 时视为无效不恢复
8. **收藏卡片副标题统一** — 网格+列表模式从 sourceName 改为 lastChapterTitle（与历史页一致），无章节时回退显示来源名

### 验证证据

- v0.85.4 构建通过（0 ERROR，17 WARN）
- 虚拟机完整链路验证：目录点书→详情页→"+"收藏→读第1话→返回（第1话绿色框选+定位）→收藏标签副标题显示"[第1话] 吴一天"→点击直接恢复第1话阅读器→返回框选正确
- 历史入口与收藏入口行为一致

### 未完成边界

- `Index.ets` 单文件仍然过大（5230+ 行），待拆分
- 书架Tab 的目录推荐卡片点击仍只 loadDetail（推荐书无阅读历史，属合理设计）
- 增量构建版本号发现 0.85.2→0.85.4 跳号（中间有额外一次构建调用，无实际影响）

### 下一步建议

- openBookUnified 参数为基本类型字符串，未来拆分 Index.ets 时可将其与 BookCard 一起提取为独立模块

## 2026-09-14 设置页面5项修复 + 屏幕常亮默认关闭 + 构建脚本增量模式

### 已完成

1. **设置页面间距缩小** — `avoidStatusBarHeight + 48` → `+43`，减少顶部空白
2. **更新封面功能** — BookLongPressMenu 新增"更新封面"选项，新增 `refreshBookCover()` 方法（删除本地缓存后重新下载封面）
3. **ic_more.svg 全部替换** — 4处 `ic_more.svg` 改为 `ic_chevron_right.svg`（LinkRow、DialogLinkRow、EditorTopBar、底部导航栏）
4. **主题/语言下拉箭头** — LinkRow 新增可选 `arrowIcon` 参数，主题和语言行传入 `ic_chevron_down`（▼），其他行默认 `ic_chevron_right`（>）
5. **i18n 4字文案** — 阅读页全屏→阅读全屏、调试时屏幕常亮→屏幕常亮、显示与阅读→显示阅读、封面准确性校验→封面校验、手机内置规则→内置规则
6. **显示残留修复** — 所有对话框背景从 `Color.Transparent`/`#00000000` 改为 `dialogOverlay()` 半透明遮罩；`onBackPress` 增加对所有对话框状态（themeDialogVisible、languageDialogVisible、updateDialogVisible、historyMenuVisible、bookLongPressVisible、editorMenuVisible、editorFullscreen）的关闭处理
7. **屏幕常亮默认关闭** — `@State debugKeepScreenOn` 初始值 `true` → `false`，preferences 默认值 `true` → `false`
8. **构建脚本增量模式** — `build_local.ps1` 添加 `--incremental` 参数支持，增量构建时末尾版本号自增1

### 验证证据

- 全量构建 v0.85.0 通过（0 ERROR，17 WARN），HAP 安装到虚拟机验证
- 增量构建 v0.85.1 通过（末尾号+1，符合预期）
- 设置页面截图确认：间距缩小、无"三个点"图标、主题/语言下拉箭头、4字文案、半透明遮罩
- 书架长按菜单截图确认："更新封面"选项已出现
- 屏幕常亮默认关闭验证通过：清除应用数据后重新安装，Toggle 开关默认为关闭状态（灰色）

### 未完成边界

- `Index.ets` 单文件仍然过大（5200+ 行），待拆分

### 下一步建议

- 如需增量构建：`powershell -ExecutionPolicy Bypass -File scripts\build_local.ps1 --incremental`
- 如需全量构建：`powershell -ExecutionPolicy Bypass -File scripts\build_local.ps1 --full`（默认）
- 版本号逻辑：`--full` 时中间号+1末尾归零，`--incremental` 时末尾号+1

## 2026-08-31 全会话改造交接

- 必读：[SESSION_REQUIREMENTS_2026-08-31.md](SESSION_REQUIREMENTS_2026-08-31.md)，其中汇总规则流水线、全网搜索、目录/章节、阅读器、主题、消息、书架和历史全部新增约束。
- 当前工作树为 0.1.110；最新源码已签名构建成功，但最后一批搜索滚动恢复、历史滑动删除、三点菜单清空、书架每次检查更新和顶部间距调整尚未重新安装验收。
- 下一步严格执行该文档第九节验证顺序，验收后提交推送，再回到长期的全网搜索与规则流水线目标。

## 2026-07-04 搜索 UI 优化 + Tab 状态修复

### 已完成

- 搜索输入框 X 图标靠右对齐（Stack + Row justifyContent End）。
- 搜索按钮颜色改回 `#34C759`，加载时 Canvas 沿胶囊形轮廓绘制渐变描边旋转动画（中间最亮→两端渐隐）。
- 搜索按钮固定宽度 76vp，Canvas 也用 76vp，不再撑开容器。
- 搜索框改为透明背景+灰色线框。
- 搜索按钮加载时始终显示"搜索"文字。
- X 按钮功能：中断搜索+清空输入+清空结果+回到首页。
- 搜索结果页去掉搜索标题和提示文字。
- HeaderOverlay 搜索框行加 padding top 8vp，headerOverlayHeight 从 56 增到 64。
- Tab 图标状态修复：`@Builder UiIcon` 不通过参数传 selected，改为内部直接用 `this.activeTab === name` 驱动。
- `@Builder` 中 if/else 分支改为三元表达式，避免状态追踪失效。
- 加载动画渐变方向改为中间向两端渐隐（`alpha = 1.0 - 2.0 * |t - 0.5|`）。
- 更新经验教训文档（新增 6 条经验：#20-#25）。

### 验证证据

- 增量构建 v0.1.11 通过（0 ERROR，6 WARN），HAP 安装到设备验证。

### 未完成边界

- `Index.ets` 单文件仍然过大（1800+ 行），待拆分。
- 书架页仍为简单列表，未改为热门题材推荐。

## 2026-07-04 项目规范化 + 逻辑缺陷审计修复 + 状态栏避让 UI 修复

### 已完成

- 删除根目录 bak 文件（ComicModels.ets.original.bak、Index.ets.original.bak、Index.original.ets）。
- 移动根目录散落文档到 docs/（使用审计与排错记录.md、线上构建说明.md、AUDIT_REPORT.md、UI_OPTIMIZATION_AUDIT.md、PUSH_TO_GITHUB.md、REMOTE_RULES.md）。
- 清理构建缓存（.hvigor/cache、outputs、report、dependencyMap、entry/build）。
- 新建 `scripts/build_local.ps1` 本地构建脚本（hvigor + 复制到 99_Temp），CI 脚本还原为原样。
- 修复 `updateRemoteRules()` 绕过 `mergeRules()` 导致规则重复。
- 修复 `languageMode` 中英文不匹配（`'chinese'`/`'中文'` 双匹配）。
- 集成 ApiSources 到 Index.ets（新增 `searchApiSources()` 方法，逐个调用避免 ArkTS 类型错误）。
- 新增伪 URL 处理（`archive://`、`wikimedia://`、`loc://`、`pepper://`）和 `loadArchiveDetail()` 方法。
- 新增自定义 JSON 规则应用按钮和 `applyCustomRule()` 方法。
- 实现历史/书架/主题/语言持久化存储（`@ohos.data.preferences`）。
- 移除 `enrichResultCovers` 和 `fetchReaderImagesWithPagination` 硬编码上限。
- 修复 `searchHtmlRuleSources` 空 catch 无反馈。
- 书架条目上限 100 条。
- 状态栏避让：改为 Stack 三层叠加 + HeaderOverlay + Scroll 内部 Blank 占位。
- `contentBottomInset` 从 100 调到 96vp。
- SettingsPage 补上底部 Blank 占位。
- 全量构建 v0.1.0 通过（0 ERROR，6 WARN）。
- 更新经验教训文档（docs/使用审计与排错记录.md 新增 19 条经验）。
- 更新 CURRENT_STATUS.md、ARCHITECTURE.md、BUILDING.md、UI.md、SEARCH.md、AGENT_MEMORY.md。

### 验证证据

- 全量构建 v0.1.0 通过（0 ERROR，6 WARN）。

### 未完成边界

- `Index.ets` 单文件仍然过大（1700+ 行），待拆分。
- 书架页仍为简单列表，未改为热门题材推荐。
- docs 子目录文档同步（docs/build/、docs/architecture/、docs/search/、docs/development/）待完成。

## 2026-07-03 国际化（i18n）语言切换

### 已完成

- 添加 `isEn()` 和 `t(key: string): string` 翻译方法，包含 80+ 个中英文翻译键值对。
- 所有 UI 硬编码中文替换为 `t()` 调用，包括 Tab 标签、按钮、设置项、弹窗、状态提示等。
- `searchMode` 内部值改为英文 key（`mixed`/`engine_only`/`api_only`），通过 `searchModeDisplay()` 显示翻译文本。
- `languageMode` 内部值改为英文 key（`chinese`/`english`/`auto`），通过 `languageModeDisplay()` 显示翻译文本。
- 添加 `themeDisplay()`/`languageDisplay()` 辅助方法，设置页主题/语言值显示翻译。
- 切换到 English 后，所有界面文本都会变为英文。

### 验证证据

- 增量构建成功，HAP 安装到设备，启动成功。

## 2026-07-03 编译错误修复 + SearchHome/SearchHeader 重构

### 已完成

- 修复 `SearchHome` 中 `Stack({ alignContent: Alignment.End })` 导致的 `arkts-no-any-unknown` 错误，改为 `Stack()` + `Row` 包裹搜索框+按钮。
- 修复 `SearchHeader` 同样问题，`linearGradient` 的 colors 改用 `headerGradientColors()` 辅助方法。
- 修复 `AvoidAreaType.TYPE_STATUS_BAR` 不存在错误，改为 `AvoidAreaType.TYPE_SYSTEM`。
- 修复 `buildSearchEngineUrl` 参数数量错误（缺少 `this.googleApiKey`）。

### 验证证据

- 增量构建成功，HAP 安装到设备，启动成功。

## 2026-07-02 UI 优化：绿色风格 + 全屏模式 + 渐变背景 + 暗色模式 + 设置页重写

### 已完成

- 绿色主色 `#34C759`，所有按钮统一绿色 + 白色文字 + 圆角。
- 底部 Tab 栏毛玻璃效果：`#30FFFFFF` + `BlurStyle.Thin` + 细边框 + 阴影 + borderRadius 28。
- Tab 选中：绿色高亮图标（22px）+ 绿色文字，无选中背景色。
- 全屏显示模式：`expandSafeArea` + 状态栏透明（`EntryAbility.ets`）。
- 搜索首页：Stack 布局 + 插画图片 + 搜索框 + 渐变半透明遮罩 + "漫画浏览器"标题 + 状态栏避让。
- 搜索结果页 SearchHeader：渐变半透明遮罩 + 搜索框 + X 清除图标。
- 暗色模式：所有颜色方法根据 `isDark()` 动态切换。
- 设置页参考 RustDesk 重写：SectionLabel + CardContainer 分组 + LinkRow/ToggleRow + border 分隔。
- 主题切换弹窗：3选项（明亮/暗黑/跟随系统）+ 单选圆圈。
- 语言切换弹窗：3选项（跟随系统/中文/English）+ 单选圆圈。
- 设置弹窗统一风格：DialogLinkRow + DialogToggleRow + CardContainer 分组。
- 关于区域：版本号和构建时间使用 LinkRow 风格 + Divider 分隔。
- SVG 图标迁移：创建 `rawfile/` 目录，所有 SVG 修复 `stroke="#000000"`。
- 新增图标：ic_fullscreen, ic_layout, ic_moon, ic_book, ic_reading, ic_web, ic_check_circle, ic_code, ic_tune, ic_eye, ic_info, ic_about_new, ic_clock, ic_x, ic_language, ic_more, ic_close, ic_back, ic_add_shelf 等。
- 内容页底部 padding 防止被 Tab 遮挡。

### 验证证据

- 多次增量构建成功，HAP 安装到设备验证。

### 未完成边界

- `Index.ets` 单文件过大（约1500行），待拆分。
- 书架页仍为简单列表，未改为热门题材推荐。

## 2026-07-02 文档体系重组

### 已完成

- 参考项目 `11_Rustdesk_harmonyos/docs` 扁平结构重组文档。
- 合并重复文档：SEARCH_ARCHITECTURE + RULE_SYSTEM → SEARCH.md，线上构建说明排错经验 → BUILDING.md，NOTICE + DISCLAIMER + COPYRIGHT → LEGAL_NOTICES.md。
- 新增 AGENT_HANDOFF.md 和 AGENT_MEMORY.md。
- 清理根目录散落文档和空子目录。

### 未完成边界

- PROGRESS.md 待创建（功能进度追踪）。
- FILES.md 待创建（项目文件说明）。
