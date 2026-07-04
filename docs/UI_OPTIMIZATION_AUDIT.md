# 漫画浏览器 UI / 设置 / 图标优化审计

基准分支：`main`

> 本文档是历史 UI 优化审计记录。当前仓库事实、分支规则和备份策略以 `docs/CURRENT_STATUS.md`、`docs/development/BRANCH_RULES.md` 为准。

## 已按需求落地或已纳入规范

- 底部 Tab 结构统一为：搜索 / 书架 / 历史 / 设置。
- 关于信息整合到设置页，不再作为独立 Tab。
- 搜索页应只保留搜索主流程，设置类入口放入设置页。
- 选中态统一使用绿色强调色，不使用大面积绿色填充。
- 图标资源应保持统一线性风格，新增资源必须记录来源和许可证。

## 需要在 `Index.ets` 或后续拆分页面中继续处理的关键问题

### 1. 搜索页只保留搜索功能，不包含任何设置选项

当前要求：

- 设置功能和底部“设置”Tab 应保留。
- 搜索页只保留：标题、搜索输入框、搜索按钮、搜索状态、搜索结果、最近阅读或必要的搜索上下文。
- 搜索相关配置仍放在设置页里，用户需要时从底部设置 Tab 进入。
- 语言、主题、搜索模式、来源过滤、API Key、自定义 HTML 源规则、远程规则更新等都属于设置或高级设置，不放在搜索首页主流程。

### 2. 设置中所有功能审计

主要风险：

- 语言切换、主题切换、搜索引擎切换等入口必须有明确反馈，避免误触后看起来像无效点击。
- API Key / CX 输入框不适合普通用户主流程，应归入高级设置。
- 自定义 HTML 源规则和远程规则更新属于高级功能，应在设置页内做分区或高级折叠。
- 所有开关值统一使用绿色选中态，不使用红色表达正常选中。

建议处理：

- 默认语言策略与设置页说明保持一致。
- 搜索相关设置放在设置页内的“搜索设置”分区。
- 远程规则、自定义规则、API Key 统一放到设置页的“高级设置 / 调试设置”。
- 所有点击给明确中文反馈。

### 3. 绿色选中风格统一

要求：

- Tab 选中时图标和文字使用 `this.accent()`。
- 选中背景只使用轻微浅绿背景或透明，不使用整块高饱和绿色填充。
- 当前引擎、章节序号、结果数量、封面占位、步骤圆点、当前状态徽标等选中/强调对象统一使用 `this.accent()` 或绿色浅背景。

推荐辅助方法：

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
.backgroundColor(this.activeTab === tab ? this.selectedSoftBg() : '#00000000')
```

### 4. 图标资源补齐

当前曾用或建议保留的图标职责：

- `ic_search.svg`：搜索
- `ic_shelf.svg`：书架 / 热门题材
- `ic_history.svg`：历史
- `ic_settings.svg`：设置
- `ic_back.svg`：返回
- `ic_add_shelf.svg`：加入书架 / 收藏
- `ic_refresh.svg`：刷新
- `ic_more.svg`：更多
- `ic_theme.svg`：主题
- `ic_language.svg`：语言
- `ic_filter.svg`：过滤
- `ic_globe.svg`：公开源 / 网络
- `ic_engine.svg`：搜索引擎
- `ic_rule.svg`：规则
- `ic_check.svg`：选中
- `ic_close.svg`：关闭 / 移除

注意：图标建议从同一图标集选择，例如 Lucide / Tabler / Phosphor，保持线宽一致。使用外部图标前必须查看具体图标集许可证，并在第三方来源说明中记录。

## 建议 PR 拆分

1. 资源 PR：APP 图标、自绘图标替换、外部 SVG 图标补齐。
2. 主页面 PR：搜索页只保留搜索功能，所有设置类入口/切换项移到设置页。
3. 设置审计 PR：设置项改为高级面板，所有点击给明确中文反馈。
4. 绿色风格 PR：统一 `accent()`，移除红色选中与 Tab 绿色填充块。
