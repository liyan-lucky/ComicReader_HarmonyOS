# AI 助手记忆

> 每次新对话先读本文件。

## 工作规则

- 先读取所有文档了解项目，再处理问题。
- 处理问题前先回顾 DEVELOPMENT_ISSUES.md 中的历史经验。
- 每次修改后及时更新文档并验证构建。
- 尽量使用构建脚本（`scripts/build.sh`、`scripts/install.sh`）。
- 无人值守时自行完成，不等待指示。
- 主动思考解决方案，直接给出可执行方案。

## 用户偏好

- 使用简体中文交互，UI 文本支持中英文切换（通过 `t()` 翻译方法）。
- 使用 HarmonyOS 开发（提及 hdc 工具），使用 ArkTS/ArkUI。
- 常量命名使用 UPPER_SNAKE_CASE 风格。
- 绿色主色 `#34C759`，按钮统一绿色 + 白色文字 + 圆角。
- 网络不稳定时多试几次，不要改其他配置。
- 参考项目 `E:\Visual_Studio_Code\11_Rustdesk_harmonyos` 的 UI 风格和文档体系。

## 项目关键信息

| 项目 | 值 |
|------|-----|
| 包名 | `com.nw.cleansite.novel.hm` |
| 主分支 | `main` |
| 长期分支 | `main` |
| 当前版本 | 0.1.0 |
| 主入口 | `entry/src/main/ets/pages/Index.ets` |
| API 搜索源 | `entry/src/main/ets/common/ApiSources.ets` |
| 本地构建脚本 | `scripts/build_local.ps1` |
| CI 构建脚本 | `scripts/build_full.sh` / `scripts/build_incremental.sh` |
| 版本更新脚本 | `scripts/update_build_version.js` |
| JAVA_HOME | `C:\Program Files\Huawei\DevEco Studio\jbr` |
| hdc 路径 | `C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains` |
| 远程规则 | `https://raw.githubusercontent.com/liyan-lucky/ComicReader_Rules/main/generated/index.json` |
| 构建产物 | `E:\Visual_Studio_Code\99_Temp\entry-default-unsigned.hap` |

## 构建注意事项

- 本地构建使用 `scripts/build_local.ps1`（PowerShell），CI 使用 `.sh` 脚本，两者严格分离。
- CI 脚本（`.sh`）不能包含本地路径，本地构建用独立脚本（`.ps1`）。
- 构建前必须执行 `update_build_version.js` 更新版本号。
- 构建后需恢复 `oh-package.json5`：`git checkout -- oh-package.json5 entry/oh-package.json5`。
- 签名通过 DevEco Studio GUI 操作，不在 `build-profile.json5` 中配置。
- `hdc install` 对 Windows 绝对路径有 bug，从 HAP 所在目录用相对路径执行。
- 安装时如遇版本降级错误，先 `hdc uninstall` 再 `hdc install`。
- 所有构建测试产物放到 `E:\Visual_Studio_Code\99_Temp`。

## ArkTS 编码约束

- `@Builder` 方法返回 void，不能链式调用 `.onClick()` 等属性方法，需要用 `Column() { this.BuilderCall() }.onClick(...)` 包裹。
- `@Builder` 方法不能接受 `() => void` 作为参数。
- ArkTS 不允许内联对象字面量数组（`arkts-no-untyped-obj-literals`），需要用显式类型如 `Array<[string, number]>`。
- ArkTS 不允许无类型对象字面量数组（`arkts-no-noninferrable-arr-literals`），多个源需逐个调用或定义 interface+class。
- ArkTS 不允许 `any`/`unknown` 类型（`arkts-no-any-unknown`）。
- ArkTS 不允许在独立函数中使用 `this`（`arkts-no-standalone-this`）。
- ArkTS 函数必须有显式返回类型（`arkts-no-implicit-return-types`）。
- `linearGradient` 的 colors 参数需要用辅助方法返回 `Array<[string, number]>` 类型。
- `Stack({ alignContent: Alignment.End })` 在 ArkTS 中会触发 `arkts-no-any-unknown`，应改用 `Stack()`。
- `window.AvoidAreaType.TYPE_STATUS_BAR` 不存在，应使用 `TYPE_SYSTEM`。
- stroke 格式 SVG 必须有 `stroke="#000000"` 属性才能被 `colorFilter(BlendMode.SRC_IN)` 着色。
- `getContext(this)` 和 `px2vp` 已被标记为 deprecated，但仍可使用。
- `@Builder` 中通过参数传入的布尔值不会触发状态追踪，必须直接引用 `this.xxx` 状态变量。
- `@Builder` 中的 `if/else` 分支可能导致状态追踪失效，优先用三元表达式在同一组件上切换属性值。
- Canvas 叠加在 Stack 中做动画时，尺寸必须和底层组件一致，不能用 `width('100%')`。

## 布局约束

- Scroll 外层 padding 在 `expandSafeArea` 下不生效，必须在 Scroll 内部用 `Blank().height()` 做物理占位。
- Stack 三层叠加是标准布局模式：底层可滚动内容 + 中层渐变半透明 HeaderOverlay（hitTestBehavior Transparent）+ 底层导航栏。
- `avoidStatusBarHeight` 默认值必须设 48vp 兜底（`getWindowAvoidArea` 可能返回 0）。
- `contentBottomInset` 当前为 96vp。
- `headerOverlayHeight` 当前为 `avoidStatusBarHeight + 64`（含 top padding 8vp）。
- 参考 `10_Tabssh_harmonyos` 和 `11_Rustdesk_harmonyos` 的状态栏处理方式。

## 搜索 UI

- 搜索框：透明背景 + 灰色线框（`backgroundColor(Color.Transparent)` + `border({ width: 1, color: secondaryText() })`）。
- 搜索按钮：绿色胶囊形 `#34C759`，固定宽度 76vp，加载时 Canvas 沿轮廓绘制渐变描边旋转动画。
- X 按钮：中断搜索 + 清空输入 + 清空结果 + 回到首页。
- Tab 图标：选中绿色，未选中灰色，`@Builder` 内部直接用 `this.activeTab === name` 驱动。

## 搜索源

- 搜索引擎：Bing/DuckDuckGo/Google/Yandex（无需 Key），Brave/Google CSE（需要 Key）。
- API 搜索源：Internet Archive/Wikimedia/Open Library/Library of Congress/Pepper（无需 Key，在 `ApiSources.ets` 中定义）。
- 伪 URL 处理：`archive://`、`wikimedia://`、`loc://`、`pepper://`（在 `loadDetail()` 中分发）。
- 搜索模式：`mixed`（默认）/`engine_only`/`api_only`。
- `languageMode` 内部值：`chinese`/`english`/`auto`，需同时匹配中英文值。

## 持久化

- 书架/历史/主题/语言通过 `@ohos.data.preferences` 持久化存储。
- 书架条目上限 100 条，历史上限 40 条。
- `enrichResultCovers` 和 `fetchReaderImagesWithPagination` 已移除硬编码上限。

## 国际化（i18n）

- 所有 UI 文本通过 `t(key: string): string` 方法翻译。
- `appLanguage` 状态变量：`'zh'`（中文）、`'en'`（英文）、`'system'`（跟随系统）。
- `searchMode` 内部值：`'mixed'`、`'engine_only'`、`'api_only'`，通过 `searchModeDisplay()` 显示翻译文本。
- `languageMode` 内部值：`'chinese'`、`'english'`、`'auto'`，通过 `languageModeDisplay()` 显示翻译文本。
- `themeDisplay()`/`languageDisplay()` 辅助方法用于设置页显示值翻译。

## 文档阅读顺序

```
新对话：AGENT_HANDOFF.md → AGENT_MEMORY.md → CURRENT_STATUS.md
开发前：DEVELOPMENT_REQUIREMENTS.md → REPOSITORY_STANDARDS.md
修改代码：ARCHITECTURE.md → UI.md → SEARCH.md → DEVELOPMENT_ISSUES.md
构建发布：BUILDING.md → RELEASE_CHECKLIST.md
```
