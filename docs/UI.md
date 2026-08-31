# 漫画浏览器 UI 规范

本文记录当前 App 的 UI 方向、源码固化目标和图标资源规则。

> 最新 UI 验收基线见 [SESSION_REQUIREMENTS_2026-08-31.md](SESSION_REQUIREMENTS_2026-08-31.md) 第五至第七节。特别注意：阅读器使用独立自定义磨砂控件、消息位于 Tab 上方约 5vp、短页面顶部对齐、历史记录使用左右滑删除。

## 布局架构

当前主页面使用 Stack 三层叠加布局：

```text
Stack() {
  // 第1层：可滚动内容（底层）
  Scroll() {
    Column() {
      Blank().height(contentTopInset)    // 顶部避让 HeaderOverlay
      ... 实际内容 ...
      Blank().height(contentBottomInset) // 底部避让 BottomTabs
    }
  }

  // 第2层：渐变半透明 HeaderOverlay（中层，点击穿透）
  Column() {
    Blank().height(avoidStatusBarHeight) // 状态栏占位
    ... 标题/搜索栏 ...
  }
  .linearGradient({ angle: 180, colors: headerGradientColors() })
  .hitTestBehavior(HitTestMode.Transparent)

  // 第3层：底部导航栏（底层，点击穿透）
  Column() {
    Blank()
    BottomTabs()
  }
  .hitTestBehavior(HitTestMode.Transparent)
}
.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
```

关键点：

1. `expandSafeArea` 在根 Stack 上，让渐变穿透状态栏。
2. HeaderOverlay 用 `hitTestBehavior(Transparent)` 实现点击穿透。
3. 渐变使用 9 段颜色从 ~75% 不透明度线性过渡到全透明。
4. 内容页面的 Scroll 内部用 `Blank().height()` 做物理占位避让 Header 和 BottomTabs。
5. 有自己固定头部的页面（ChaptersPage、ReaderPage）不用 HeaderOverlay，直接用 `Blank().height(avoidStatusBarHeight)` 在头部上方占位。
6. 搜索首页不用 HeaderOverlay，用 Column 布局 + 顶部/底部 Blank 避让。
7. SettingsPage 补上底部 Blank 占位。

### 状态栏避让

- `EntryAbility.ets` 中设置 `setWindowLayoutFullScreen(true)` + 透明状态栏。
- `avoidStatusBarHeight` 默认值 48vp 兜底（`aboutToAppear()` 中 `getWindowAvoidArea` 可能返回 0）。
- 实测设备值 38.86vp（raw=136px），默认值确保在 API 返回 0 时仍能正常避让。
- `contentTopInset` = `avoidStatusBarHeight` + HeaderOverlay 高度。
- `contentBottomInset` = 96vp（底部导航栏高度 + 边距）。

### 重要约束

- Scroll 外层 padding 在 `expandSafeArea` 下不生效，必须在 Scroll 内部用 `Blank().height()` 做物理占位。
- 参考 `10_Tabssh_harmonyos` 和 `11_Rustdesk_harmonyos` 的状态栏处理方式。

## 设计目标

- 参考 HarmonyOS 官方应用的清爽、圆角、胶囊化设计语言；
- 底部导航改为悬浮胶囊 Tab（毛玻璃效果 + borderRadius 28）；
- 顶部搜索区使用半透明磨砂感渐变过渡；
- 支持明亮 / 暗黑 / 跟随系统 三种主题；
- 支持中文 / English / 跟随系统 三种语言，所有 UI 文本通过 `t()` 翻译方法切换；
- 书架支持收藏搜索结果，并显示最近阅读章节、阅读时间、估算进度和阅读次数；
- 阅读页默认全屏，标题栏、返回、收藏、刷新等控制改为悬浮独立按钮；
- 所有 App 图标资源统一来自 ProIcons 上的开源图标集合，不自建设计图标。

## 实现方式

当前 UI 固化到：

```text
entry/src/main/ets/pages/Index.ets
```

正式构建不应依赖 UI 注入脚本动态改页面源码。

## 图标资源规则

所有应用内图标资源必须来自：

```text
https://proicons.com/
```

使用规则：

- 优先选择 SVG 图标（stroke 格式）；
- SVG 必须有 `stroke="#000000"` 属性才能被 `colorFilter(BlendMode.SRC_IN)` 着色；
- 优先选同一图标集合，保证线宽、圆角和视觉风格一致；
- 不允许自建图标、不允许用临时字符图标长期替代正式图标；
- 不允许从来源不明的网站、搜索结果图片或未授权 UI 包复制图标；
- 每个使用的图标集合必须记录集合名、原作者、许可证和来源页面；
- 如果图标集合许可证是 MIT、Apache 2.0、ISC 等需要归属说明的许可证，必须同步更新 `THIRD_PARTY_NOTICES.md`。

推荐命名和存放路径：

```text
entry/src/main/resources/rawfile/ic_search.svg
entry/src/main/resources/rawfile/ic_shelf.svg
entry/src/main/resources/rawfile/ic_settings.svg
entry/src/main/resources/rawfile/ic_history.svg
entry/src/main/resources/rawfile/ic_back.svg
entry/src/main/resources/rawfile/ic_add_shelf.svg
entry/src/main/resources/rawfile/ic_close.svg
entry/src/main/resources/rawfile/ic_x.svg
entry/src/main/resources/rawfile/ic_moon.svg
entry/src/main/resources/rawfile/ic_language.svg
entry/src/main/resources/rawfile/ic_fullscreen.svg
entry/src/main/resources/rawfile/ic_layout.svg
entry/src/main/resources/rawfile/ic_info.svg
entry/src/main/resources/rawfile/ic_clock.svg
entry/src/main/resources/rawfile/ic_more.svg
entry/src/main/resources/rawfile/ic_filter.svg
entry/src/main/resources/rawfile/ic_reading.svg
entry/src/main/resources/rawfile/ic_engine.svg
entry/src/main/resources/rawfile/ic_rule.svg
entry/src/main/resources/rawfile/ic_code.svg
```

当前图标清单：

| 用途 | 图标语义 | 资源名 |
| --- | --- | --- |
| 搜索 Tab | search | `ic_search.svg` |
| 书架 Tab | book-open | `ic_shelf.svg` |
| 历史 Tab | clock | `ic_history.svg` |
| 设置 Tab | settings | `ic_settings.svg` |
| 阅读返回 | chevron-left | `ic_back.svg` |
| 加入书架 | bookmark-plus | `ic_add_shelf.svg` |
| 主题 | moon | `ic_moon.svg` |
| 语言 | globe | `ic_language.svg` |
| 全屏 | maximize | `ic_fullscreen.svg` |
| 悬浮控制 | layout | `ic_layout.svg` |
| 搜索菜单 | search | `ic_search.svg` |
| 源开关 | filter | `ic_filter.svg` |
| 显示与阅读 | book-open | `ic_reading.svg` |
| 搜索引擎 | globe | `ic_engine.svg` |
| 规则设置 | file-text | `ic_rule.svg` |
| 高级规则 | code | `ic_code.svg` |
| 版本号 | info | `ic_info.svg` |
| 构建时间 | clock | `ic_clock.svg` |
| 更多 | chevron-right | `ic_more.svg` |
| 清除输入 | x | `ic_x.svg` |
| 关闭弹窗 | x-circle | `ic_close.svg` |

## 主题

当前主题状态：

```text
appTheme = light | dark | system
```

明亮主题：

- 页面背景：`#F6F8FA`
- 卡片背景：`#FFFFFF`
- 主文字：`#111827`
- 次级文字：`#7A828C`
- 强调色：`#34C759`
- 输入框背景：透明（`Color.Transparent`）
- 输入框边框：`#7A828C`（1px 线框）
- 边框：`#F0F0F0`

暗黑主题：

- 页面背景：`#111318`
- 卡片背景：`#1E232F`
- 主文字：`#E8ECF4`
- 次级文字：`#7A828C`
- 强调色：`#34C759`
- 输入框背景：透明（`Color.Transparent`）
- 输入框边框：`#7A828C`（1px 线框）

## 多语言（i18n）

当前语言状态：

```text
appLanguage = zh | en | system
```

翻译方法：`t(key: string): string`，包含 80+ 个中英文翻译键值对。

覆盖范围：

- Tab 标签（搜索/Search、书架/Shelf、历史/History、设置/Settings）
- 搜索按钮和输入框占位符
- 设置页所有标签和值
- 弹窗标题和选项
- 状态提示消息
- 结果卡片标签（作者、最新章节、更新时间等）
- 书架/历史空状态提示

内部值映射：

- `searchMode`：`mixed`/`engine_only`/`api_only` → `searchModeDisplay()` 显示翻译文本
- `languageMode`：`chinese`/`english`/`auto` → `languageModeDisplay()` 显示翻译文本
- 主题/语言显示值：`themeDisplay()`/`languageDisplay()`

## 底部胶囊 Tab

当前底部导航：

```text
搜索 / 书架 / 历史 / 设置
```

样式：毛玻璃效果 + borderRadius 28 + 细边框 + 阴影，选中态绿色图标+绿色文字，未选态灰色图标+灰色文字。

Tab 图标状态驱动：`@Builder UiIcon` 内部直接用 `this.activeTab === name` 判断选中状态，不通过参数传入布尔值（避免状态追踪失效）。

## 搜索按钮

- 绿色胶囊形 `#34C759`，固定宽度 76vp，白色文字。
- 加载时：Canvas 沿按钮轮廓绘制渐变描边旋转动画（深绿 `#34C759` alpha=1.0 → 透明 alpha=0），按钮文字保持显示。
- X 按钮：中断搜索 + 清空输入 + 清空结果 + 回到首页。
- 搜索框：透明背景 + 灰色线框（1px `secondaryText()`）。

## 书架与阅读进度

`BookshelfItem` 已扩展：

```text
lastReadUrl?: string
progressPercent?: number
readCount?: number
```

行为：

- 搜索结果可加入书架；
- 当前阅读对象可加入书架；
- 打开章节阅读后会更新书架最近章节和阅读时间；
- 如果书架条目存在 `lastReadUrl`，从书架打开时优先继续最近章节；
- `progressPercent` 用章节位置估算，无法准确计算时保留最近值。

## 全屏阅读页

当前阅读页特点：

- 背景固定深色；
- 图片竖向卷轴全屏显示；
- 顶部显示标题栏（返回 + 标题 + 加入书架）；
- 阅读页按钮使用 SVG 图标 + `colorFilter` 着色。

## 注意事项

- UI 改造最终应固化到源码，不依赖构建时注入；
- 图标资源加入仓库前必须先确认 ProIcons 对应集合页面上的许可证；
- 任何新增图标都要同步更新 `THIRD_PARTY_NOTICES.md`；
- 不能把字体包、来源不明图标包或未授权图标集提交到仓库；
- 新增翻译键必须在 `t()` 方法中同时添加中英文条目。
