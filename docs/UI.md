# 漫画浏览器 UI 规范

本文记录当前 App 的新版 UI 方向和构建时注入规则。

## 设计目标

- 参考 HarmonyOS 官方应用的清爽、圆角、胶囊化设计语言；
- 底部导航改为悬浮胶囊 Tab；
- 顶部搜索区使用半透明磨砂感过渡；
- 支持明亮 / 暗黑双主题；
- 支持中文 / English 双语言基础切换；
- 书架支持收藏搜索结果，并显示最近阅读章节、阅读时间、估算进度和阅读次数；
- 阅读页默认全屏，标题栏、返回、收藏、刷新等控制改为悬浮独立按钮。

## 构建注入方式

当前 UI 改造通过构建脚本注入到 `entry/src/main/ets/pages/Index.ets`：

```text
scripts/patch_about_page_ci.js
scripts/patch_modern_ui_ci.js
```

执行入口：

```text
scripts/build_hap_ci.js
scripts/build_full.sh
scripts/build_incremental.sh
```

因此建议使用脚本构建：

```bash
bash scripts/build_full.sh
bash scripts/build_incremental.sh
```

如果只想预览补丁后的源码，不真正构建 HAP：

```bash
SKIP_HAP_BUILD=1 bash scripts/build_full.sh
```

## 主题

当前主题状态：

```text
appTheme = light | dark
```

明亮主题：

- 页面背景：`#F7F8FA`
- 卡片背景：`#FFFFFF`
- 顶部半透明背景：`#EFFFFFFF`
- 主文字：`#111111`
- 次级文字：`#666666`
- 强调色：`#34C759`

暗黑主题：

- 页面背景：`#101418`
- 卡片背景：`#1B222A`
- 顶部半透明背景：`#CC141A20`
- 主文字：`#F2F5F7`
- 次级文字：`#AAB4C0`
- 强调色：`#34C759`

## 多语言

当前语言状态：

```text
appLanguage = zh | en
```

目前已接入核心外壳文案：

- 搜索 / Search
- 书架 / Shelf
- 设置 / Settings
- 关于 / About
- 主题 / Theme
- 语言 / Language
- 全屏阅读 / Full screen reader
- 悬浮控制 / Floating controls

后续可以继续把规则说明、错误提示、设置说明细化到完整 i18n 字典。

## 底部胶囊 Tab

新版底部导航包含：

```text
搜索 / 书架 / 设置 / 关于
```

当前选中的 Tab 使用绿色胶囊背景，未选中状态使用透明背景和次级文字色。

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

新版阅读页特点：

- 背景固定深色；
- 图片竖向卷轴全屏显示；
- 顶部显示悬浮标题胶囊；
- 底部显示悬浮返回、加入书架、刷新按钮；
- 渲染阅读模式继续使用 WebView 兜底，但外层采用同样全屏结构。

## 注意事项

- 当前 UI 注入发生在构建前；直接用 DevEco Studio 打开未执行脚本的源码，可能看不到注入后的新版 UI；
- 建议先执行 `SKIP_HAP_BUILD=1 bash scripts/build_full.sh` 查看补丁后的源码，再正式构建；
- 后续如果要把 UI 改造固化到 `Index.ets`，可以在构建后把补丁结果回写为正式源码。
