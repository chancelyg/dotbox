# OpenCode

使用共享的 AI CLI 全局规则和 Skills，旧安装清理及 `instructions`、`skills` 路径配置见[根 README](../README.md)。使用原生 Build / Plan，不再分发 Coding / Ops 代理或 `/dotbox` 命令。

本目录仅保留独立选用的内容：

- `cli.json`、`opencode.json`、`opencode.jsonc`：原生配置示例，不会自动安装。
- `plugins/status-sidebar/`：状态侧栏插件。

示例包含模型、权限或 MCP 设置，使用前逐项审阅，不整份覆盖个人配置。旧全局或项目配置中的代理选择、禁用项，以及非受管旧代理，需自行核对处理。

共享规则不替代客户端权限。Build / Plan 与 Pi 的原生执行行为不同，不保证相同文字规则产生完全一致的行为。

## 状态侧边栏

适用于 OpenCode V2 终端界面。将实际插件目录追加到全局 `opencode.json(c)` 的 `plugins` 数组，配置示例见[根 README](../README.md#opencode-侧边栏)。不覆盖已有插件，不复制整个配置文件。

- `index.ts` 注册服务端额度查询，`tui.tsx` 在原生侧栏追加内容，`rpc.ts` 定义通信接口。按 V2 目录加载约定，一个目录条目会加载所有部分，无需在 `cli.json` 再注册。
- 全局 `cli.json` 的 `session.sidebar` 设为 `auto`，终端需有足够宽度；`hide` 会隐藏侧栏。
- 显示主机、CPU/RAM、生成速度、最近用户消息和可获取的服务额度。CPU/RAM 来自运行 TUI 的机器；连接远程 OpenCode 服务时不一定是服务端主机。
- 服务端利用 OpenCode 已有的 OpenAI OAuth 或 DeepSeek API Key，分别请求 `https://chatgpt.com/backend-api/wham/usage`、`https://api.deepseek.com/user/balance`。无需另填凭证，也不要将凭证写进仓库；无对应认证或请求失败时不显示该服务额度。
- 额度查询成功缓存 5 分钟，全部无数据时缓存 45 秒，因此不会每次刷新界面都请求服务。

### 加载检查与移除

1. 重新打开 TUI，进入会话并检查侧栏；可用 `opencode plugin list` 辅助确认插件注册。
2. 无显示时检查插件路径是否指向目录、侧栏是否隐藏、终端宽度及加载错误。仅额度缺失时先区分认证或网络问题，不把它当作整个插件加载失败。
3. 本地目录变更可能不在自动监控范围；使用后台服务时可执行 `opencode service restart`，再重新打开 TUI。重启会影响连接该服务的客户端，避开正在执行的任务；独立运行的实例退出后重开。
4. 停用时移除该 `plugins` 路径条目并重启对应实例，保留其他插件。若以前复制或链接到自动发现目录，还需核实并处理旧副本，避免重复加载。

加载约定依据 [V2 插件文档](https://opencode.ai/docs/plugins/)及[目录入口说明](https://opencode.ai/docs/build/plugins/#load)。注册成功不等于当前版本的运行兼容性已验证。
