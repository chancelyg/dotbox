# Pi

全局规则和 Skills 与 OpenCode 共用，清理及安装见[根 README](../README.md)。不定义代理体系，不改写个人模型、认证、MCP 或设置。更新后运行 `/reload`，检查加载诊断。

## 可选单行状态栏

`extensions/status.ts` 替换 Pi 原生 footer，仅在 TUI 模式生效。在仓库根执行（使用根 README 已定义的 `link` 函数）：

```bash
repo=$(pwd -P)
pi=${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}
(
    set -e
    mkdir -p "$pi/extensions"
    link "$repo/pi/extensions/status.ts" "$pi/extensions/status.ts"
)
```

显示模型、思考等级、目录、上下文占用和系统 CPU / RAM：

```text
◎ GPT-5.6 Sol ⚡️ medium 📁 github/dotbox 📊 24k / 200k (12%) · CPU 8% / RAM 42%
```

- 宽度不足时依次缩短目录、隐藏 CPU/RAM、目录和思考等级；极窄时仅保留上下文。
- 上下文来自 Pi 原生统计，压缩后未知值显示 `?`，不是累计用量或订阅额度。
- CPU / RAM 每 2 秒刷新，是运行 Pi 的系统指标；SSH 显示远程机器，容器内不代表容器配额。
- 不联网、不读取凭证、不启动子进程；卸载、会话切换或 `/reload` 时清理定时器。

替换后不显示原生 Git 分支、费用和 Token 明细；不要同时启用另一个 footer 替换扩展。恢复原生 footer 时，核实并删除此链接，再运行 `/reload`。

文档基线：Pi 1.5.2。规则和 Skills 是指令，不提供工具权限隔离。
