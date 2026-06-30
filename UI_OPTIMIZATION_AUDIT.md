# 漫画浏览器 UI / 设置 / 图标优化审计

基准分支：`develop`

## 已按本次需求落地

- APP 图标不再使用原 PNG，已替换为自绘 `entry/src/main/resources/base/media/icon.svg`。
- 图标来源策略：底部 Tab / 设置相关 / 阅读控制图标继续使用外部 SVG 图标资源风格，不把这些图标做成自绘。proIcons 页面显示其聚合免费 SVG 图标集合，支持 SVG 下载，并提示使用时应查看具体图标集许可。

## 需要在 `Index.ets` 中继续处理的关键问题

### 1. 主页面不要有“设置”入口

当前问题：

- README 标注四个 Tab：搜索 / 书架 / 设置 / 关于。
- `Index.ets` 的 `BottomTabs()` 里仍渲染 `settings` Tab。
- `build()` 中仍存在 `activeTab === 'settings'` 时进入 `SettingsPage()` 的逻辑。
- 搜索首页还有“去设置引擎”按钮，会把 `activeTab` 改为 `settings`。

建议处理：

- 底部 Tab 改为：搜索 / 书架 / 关于，删除设置 Tab。
- 主搜索页删除“去设置引擎”按钮。
- `build()` 不再暴露 `SettingsPage()` 作为主 Tab。
- 设置功能不建议直接删除逻辑，建议转为内部调试入口或折叠到关于页的高级入口，避免误触。

### 2. 设置中所有功能审计

已发现主要风险：

- `toggleLanguage()` 会在中文/英文之间切换，导致用户点击后出现英文，例如搜索按钮、About 页、阅读提示等。
- `t()` 函数只有少量 key 翻译，大量设置页文案仍是中文；切到英文后会出现中英文混排。
- “当前搜索引擎”点击后直接 `cycleEngine()`，没有二次说明，容易被误认为无效点击或误切。
- “搜索模式 / 来源过滤模式 / 搜索语言倾向”等点击即轮换，没有弹窗或确认，容易误触。
- API Key / CX 输入框在主设置页裸露，不适合普通用户主流程。
- 自定义 HTML 源规则输入框和远程规则更新属于高级功能，应从主页面隐藏。

建议处理：

- 默认锁定中文：移除 `toggleLanguage()` 的可点击入口，或仅保留 `appLanguage='zh'`。
- 把搜索相关设置拆成“搜索设置”子页或高级面板，点击设置卡片后给明确状态提示。
- 远程规则、自定义规则、API Key 统一放到“高级设置 / 调试设置”。
- 所有开关值统一使用绿色选中态，不使用红色表达正常选中。

### 3. 绿色选中风格统一

当前问题：

- `TabPill()` 选中时整块背景为绿色，图标和文字为白色。
- 用户要求：不要绿色填充块，把绿色改到图标渲染上。
- 代码里还有多处红色 `#E53935` 用于步骤、徽标、章节序号、当前引擎等选中/强调。

建议处理：

- `UiIcon(tab, selected, size)`：选中颜色改为 `this.accent()`，未选中为 `this.secondaryText()`。
- `TabPill()`：选中背景改透明或轻微浅绿背景，例如 `#1434C759`；文字选中使用 `this.accent()`。
- 所有选中对象：当前引擎、章节序号、结果数量、封面占位、步骤圆点、当前状态徽标，统一替换为 `this.accent()` 或绿色浅背景。

推荐改法片段：

```ts
private selectedSoftBg(): string {
  return this.isDarkTheme() ? '#1E34C759' : '#1434C759';
}

private selectedText(): string {
  return this.accent();
}
```

`UiIcon()` 示例：

```ts
Image($r('app.media.ic_search'))
  .width(size)
  .height(size)
  .fillColor(selected ? this.accent() : this.secondaryText())
```

`TabPill()` 示例：

```ts
.fontColor(this.activeTab === tab ? this.accent() : this.secondaryText())
.backgroundColor('#00000000')
```

### 4. 图标资源补齐

当前已存在：

- `ic_search.svg`
- `ic_shelf.svg`
- `ic_settings.svg`
- `ic_about.svg`
- `ic_back.svg`
- `ic_add_shelf.svg`
- `ic_refresh.svg`
- `ic_more.svg`

建议补充：

- `ic_home.svg`：主搜索 / 首页
- `ic_reader.svg`：阅读器
- `ic_history.svg`：历史
- `ic_filter.svg`：过滤
- `ic_globe.svg`：公开源 / 网络
- `ic_engine.svg`：搜索引擎
- `ic_rule.svg`：规则
- `ic_theme.svg`：主题
- `ic_language.svg`：语言（若保留）
- `ic_check.svg`：选中
- `ic_close.svg`：关闭 / 移除

注意：这些图标建议从 proIcons 选择同一图标集，例如 Lucide / Tabler / Phosphor，保持线宽一致。proIcons 首页说明 SVG 是默认可用格式，且每个集合页面会列出具体许可。

## 建议 PR 拆分

1. 资源 PR：APP 图标、自绘图标替换、外部 SVG 图标补齐。
2. 主页面 PR：删除设置 Tab 和首页设置入口。
3. 设置审计 PR：隐藏语言切换，设置项改为高级面板，所有点击给明确中文反馈。
4. 绿色风格 PR：统一 `accent()`，移除红色选中与 Tab 绿色填充块。
