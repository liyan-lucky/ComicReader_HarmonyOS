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
| 主入口 | `entry/src/main/ets/pages/Index.ets` |
| 构建脚本 | `scripts/build.sh incremental` |
| 安装脚本 | `scripts/install.sh` |
| JAVA_HOME | `C:\Program Files\Huawei\DevEco Studio\jbr` |
| hdc 路径 | `C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains` |
| 远程规则 | `https://raw.githubusercontent.com/liyan-lucky/ComicReader_Rules/main/generated/index.json` |

## 构建注意事项

- 构建前需 `git checkout HEAD -- AppScope/app.json5`，防止被清空。
- 构建后需恢复 `build-profile.json5`、`oh-package.json5` 等被构建脚本修改的配置文件。
- 安装时如遇版本降级错误，先 `hdc uninstall` 再 `hdc install`。
- hdc 路径拼接有 bug，需将 HAP 复制到 `E:\` 根目录后用 `hdc install entry-default-unsigned.hap` 安装。

## ArkTS 编码约束

- `@Builder` 方法返回 void，不能链式调用 `.onClick()` 等属性方法，需要用 `Column() { this.BuilderCall() }.onClick(...)` 包裹。
- `@Builder` 方法不能接受 `() => void` 作为参数。
- ArkTS 不允许内联对象字面量数组（`arkts-no-untyped-obj-literals`），需要用显式类型如 `Array<[string, number]>`。
- ArkTS 不允许 `any`/`unknown` 类型（`arkts-no-any-unknown`）。
- ArkTS 不允许在独立函数中使用 `this`（`arkts-no-standalone-this`）。
- ArkTS 函数必须有显式返回类型（`arkts-no-implicit-return-types`）。
- `linearGradient` 的 colors 参数需要用辅助方法返回 `Array<[string, number]>` 类型。
- `Stack({ alignContent: Alignment.End })` 在 ArkTS 中会触发 `arkts-no-any-unknown`，应改用 `Stack()`。
- `window.AvoidAreaType.TYPE_STATUS_BAR` 不存在，应使用 `TYPE_SYSTEM`。
- stroke 格式 SVG 必须有 `stroke="#000000"` 属性才能被 `colorFilter(BlendMode.SRC_IN)` 着色。
- `getContext(this)` 和 `px2vp` 已被标记为 deprecated，但仍可使用。

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
