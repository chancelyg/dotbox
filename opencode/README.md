# OpenCode

使用共享的 AI CLI 全局规则和 Skills，旧安装清理及 `instructions`、`skills` 路径配置见[根 README](../README.md)。使用原生 Build / Plan，不再分发 Coding / Ops 代理或 `/dotbox` 命令。

本目录仅保留独立选用的内容：

- `cli.json`、`opencode.json`、`opencode.jsonc`：原生配置示例，不会自动安装。
- `plugins/status-sidebar/`：状态侧栏插件。

示例包含模型、权限或 MCP 设置，使用前逐项审阅，不整份覆盖个人配置。旧全局或项目配置中的代理选择、禁用项，以及非受管旧代理，需自行核对处理。

共享规则不替代客户端权限。Build / Plan 与 Pi 的原生执行行为不同，不保证相同文字规则产生完全一致的行为。
