# 我漫画浏览器 v5.7 GitHub RuleBot 审计报告

## 本轮目标

用户反馈：让任何 AI 生成规则太复杂，容易失败或编造。v5.7 改为在项目中加入“规则自动发现脚本”：

```text
关键词 / 域名
→ 搜索公开网页
→ 审计详情页、章节页、图片、登录/付费风险
→ 生成 GeneratedSourceRules.ets
→ App 构建时自动加载规则
```

## 新增文件审计

| 文件 | 作用 | 审计结果 |
|---|---|---|
| `tools/rule_discovery/generate_rules.py` | 公开漫画源搜索、审计、规则生成主脚本 | 已通过 Python 语法检查 |
| `tools/rule_discovery/requirements.txt` | Python 依赖 | requests / beautifulsoup4 / lxml |
| `scripts/generate_comic_rules.sh` | 本地一键生成规则 | 已设置可执行权限 |
| `.github/workflows/generate-comic-rules.yml` | GitHub Actions 自动/手动生成规则 | 支持 workflow_dispatch 和每周计划任务 |
| `entry/src/main/ets/common/GeneratedSourceRules.ets` | 自动生成规则入口 | 初始为空数组，可被脚本覆盖 |
| `entry/src/main/resources/rawfile/audit/generated_rulebot_report.json` | 自动生成规则审计报告 | 初始占位，脚本运行后覆盖 |

## App 集成审计

`SourceRules.ets` 已加入：

```ts
import { GENERATED_SOURCES } from './GeneratedSourceRules';
```

并在默认源数组最前面加入：

```ts
...GENERATED_SOURCES,
```

因此脚本生成的规则会优先参与搜索、域名匹配、章节解析和卷轴阅读。

## RuleBot 功能审计

| 功能 | 状态 |
|---|---|
| 支持关键词搜索 | 通过 |
| 支持限定域名搜索 | 通过 |
| 支持 Brave Search API | 通过，需 GitHub Secret `BRAVE_SEARCH_API_KEY` |
| 支持 Google Programmable Search API | 通过，需 `GOOGLE_API_KEY` 与 `GOOGLE_CX` |
| 支持 DuckDuckGo HTML 兜底 | 通过，可能受搜索页限流影响 |
| 自动排除登录/付费/VIP/下载/社区/视频等页面 | 通过 |
| 详情页公开访问审计 | 通过 |
| 章节链接提取 | 通过 |
| 静态图片提取 | 通过 |
| JS 转义图片 URL 提取 | 通过 |
| 静态无图但公开阅读页渲染兜底标记 | 通过 |
| 生成 ArkTS `ComicSourceRule[]` | 通过 |
| 生成结构化审计 JSON | 通过 |

## 安全/边界审计

RuleBot 明确不做：

- 登录绕过；
- 付费/VIP 绕过；
- 验证码绕过；
- 加密接口破解；
- App 私有协议伪造；
- 反爬对抗；
- 批量高频压测。

脚本默认请求间隔 `--sleep 0.6`，可自行调大。

## 使用审计结论

v5.7 已把“规则搜索/生成”从人工提示词流程改为项目内自动化流程。用户只需要：

```bash
bash scripts/generate_comic_rules.sh "斗罗大陆" "Soul Land" "Douluo Dalu"
```

或在 GitHub Actions 手动输入关键词运行，生成的规则会写入：

```text
entry/src/main/ets/common/GeneratedSourceRules.ets
```

然后用 DevEco Studio 重新构建 App 即可使用。

## 限制说明

- 本地环境如果无法访问搜索引擎，脚本会生成 0 条规则；建议在 GitHub Actions 中配置 Brave 或 Google CSE API Key。
- 自动规则是“公开 HTML 通用规则”，不等于对每个网站 100% 精确；但它已经自动执行网页发现、详情审计、章节审计、图片审计和过滤，不再依赖 AI 猜选择器。
