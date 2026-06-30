# 规则系统

## 规则来源

规则来源按优先级和用途分为：

1. 内置生成规则：`GeneratedSourceRules.ets`。
2. 内置手工规则：`SourceRules.ets`。
3. 远程规则：`ComicReader_Rules/generated/index.json`。
4. 用户自定义规则：设置页粘贴 JSON。

## 默认远程规则地址

```text
https://raw.githubusercontent.com/liyan-lucky/ComicReader_Rules/main/generated/index.json
```

## 安全要求

远程规则必须满足：

- 固定 schema。
- 数量上限。
- URL 只能是 HTTP/HTTPS。
- 字段长度限制。
- 不允许本地危险地址，必要本地调试例外必须显式处理。

## 加载策略

当前：

- APP 默认加载内置规则。
- 远程规则通过设置页手动更新。

后续目标：

- APP 启动后静默尝试更新远程规则。
- 更新失败时保留内置规则。
- 不影响用户搜索和阅读。

## 自定义规则

自定义规则属于高级功能，应放在设置页高级规则分区。

要求：

- 必须校验 JSON。
- 必须校验 URL。
- 不允许危险协议。
- 不允许绕过登录、付费、验证码、DRM 或反爬。
