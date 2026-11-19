# OpenCode 标准配置

本目录保存 dotbox 分发的 OpenCode 共同规则、代理、技能，以及独立选用的配置和插件。安装、更新和卸载行为以仓库根目录的 `setup.sh`、`update.sh`、`uninstall.sh` 为准。

## 安装

```bash
git clone https://github.com/chancelyg/dotbox.git "$HOME/.dotbox"
bash "$HOME/.dotbox/setup.sh"
```

默认目标目录为：

```text
${XDG_CONFIG_HOME:-$HOME/.config}/opencode
```

`setup.sh` 安装以下标准文件：

| 来源 | 目标 | 说明 |
| --- | --- | --- |
| `opencode/AGENTS.md` | `AGENTS.md` | 全局共同规则 |
| `opencode/agents/*.md` | `agents/*.md` | Coding、Ops 及四个子代理 |
| `opencode/skills/` | `skills/` | Skills 及支持文件 |
| 技能来源与许可 | `licenses/` | 避免被 OpenCode 识别为 Skill |
| `opencode/commands/dotbox.md` | `commands/dotbox.md` | `/dotbox` 项目定位命令 |

安装清单写入目标目录的 `.dotbox-files`。写入前脚本会检查完整安装范围：

- 已由清单管理的文件可按标准源覆盖。
- 同名非受管文件会阻止安装，不自动认领、覆盖或合并。
- 普通文件之外的同名目标和经过符号链接的路径会被拒绝。
- 源码目录与目标配置目录不能互相包含。

安装不修改个人 JSON/JSONC 配置，不设置全局默认代理，不安装 OpenCode，不安装定时任务，也不启动客户端。

## 在项目中使用 `/dotbox`

进入目标项目后运行：

```text
/dotbox
```

命令会读取项目的 `AGENTS.md`、README、相关文档和现有 OpenCode 配置，依据实际用途建议 Coding、Ops 或其他已经安装的主模式。

确认选择后，命令只增量修改项目原生配置中的 `default_agent`；项目没有配置时使用项目根 `opencode.jsonc`。它不会修改全局默认，不覆盖模型、MCP、权限和其他个人设置，也不会禁用其他代理。

项目差异应记录在项目自己的 `AGENTS.md` 或其明确引用的文档中。项目约定优先于 dotbox 的可定制兜底规则，但不能解除系统指令或工具权限。

标准代理、共同规则和 Skills 由全局 dotbox 安装统一管理，不复制到项目 `.opencode/`。如果旧项目副本或同名定义遮蔽全局内容，先核对归属和有效定制，获得授权后再清理；不要直接清空 `.opencode/`。

`default_agent` 不会切换当前会话已经选择的代理。需要立即使用新默认值时，手动切换代理或新建会话。

## 代理与调用边界

- [Coding](agents/coding.md)：普通代码仓库的开发、验证以及受授权的 Git 交付流程。
- [Ops](agents/ops.md)：本机和远程运维、自动化开发、发布及恢复流程。
- [Discuss](agents/discuss.md)：讨论需求、比较方向和明确取舍，不输出正式实施方案。
- [Investigator](agents/investigator.md)：只读调查、查因和证据收集，不实施修改。
- [Planner](agents/planner.md)：将已明确的方向写成正式方案并根据审核意见修订。
- [Reviewer](agents/reviewer.md)：独立审查 Planner 的完整方案。

共同授权、调查、验证、记忆和子代理调度规则见 [AGENTS.md](AGENTS.md)。讨论、调查、规划和认可方向均不自动构成实施授权。

## Skills

按任务需要使用以下标准 Skills：

- [响应式设计](skills/responsive-design/SKILL.md)
- [无障碍合规](skills/accessibility-compliance/SKILL.md)
- [API 设计](skills/api-design-principles/SKILL.md)
- [PostgreSQL 表设计](skills/postgresql-table-design/SKILL.md)
- [浏览器自动化](skills/agent-browser/SKILL.md)

第三方来源与许可见 [THIRD_PARTY_NOTICES.md](skills/THIRD_PARTY_NOTICES.md)。安装时这些说明会放入 `licenses/`，避免技能目录根部的 Markdown 被识别为 Skill。

## 更新

先自行将本地克隆更新到希望分发的版本，再运行：

```bash
bash "$HOME/.dotbox/update.sh"
```

`update.sh` 不联网、不执行 `git pull`，只调用 `setup.sh --update`：

- 从当前克隆覆盖清单内的受管文件。
- 安装新增的标准文件。
- 删除旧清单中已经从标准源退役的文件。
- 保留个人配置和不在清单中的文件。

尚未安装时不能直接运行 `update.sh`，应先运行 `setup.sh`。

受管副本不保留人工定制：更新会按仓库源文件覆盖。项目差异应保存在项目规则中，不直接修改全局受管副本。

## 卸载

```bash
bash "$HOME/.dotbox/uninstall.sh"
```

卸载会立即删除 `.dotbox-files` 中列出的受管文件，然后删除清单。它不会清空 OpenCode 配置目录，也不会删除个人 JSON 配置、插件、UI 配置或项目文件。

卸载没有预览和 `--apply` 模式。如需预先核对范围，先查看：

```bash
less -- "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/.dotbox-files"
```

没有安装清单时，脚本直接报告无需卸载。清单路径非法、目标不是普通文件或路径经过符号链接时，脚本会停止。

## 退役的 `install.sh`

仓库根目录的 `install.sh` 仅为兼容旧调用方式而保留。它不会转调其他脚本、修改文件或联网，只显示当前入口并以非零状态退出。新的安装、更新和卸载分别使用 `setup.sh`、`update.sh`、`uninstall.sh`。

## 可选配置与插件

以下内容不由安装脚本分发：

- [`cli.json`](cli.json)：终端 UI、Tabs 和快捷键参考。
- [`opencode.json`](opencode.json)：较精简的配置参考。
- [`opencode.jsonc`](opencode.jsonc)：包含模型、权限、Provider 和 MCP 示例的带注释参考，使用前必须按个人环境审阅。
- [`plugins/status-sidebar/`](plugins/status-sidebar/)：显示主机、模型速度、CPU、RAM、最后一条用户消息，以及可验证 Provider 额度的可选侧边栏插件。

这些文件可能涉及个人模型、MCP、环境变量或客户端版本差异，不应因安装标准代理而自动覆盖。

## 验证与版本

本仓库不提供统一构建或测试任务。修改 Shell 脚本后至少运行：

```bash
bash -n setup.sh update.sh uninstall.sh install.sh
git diff --check
```

需要验证完整安装、更新和卸载时，应使用隔离的临时 HOME 或 XDG 配置目录，不直接操作真实个人配置。

当前文档基线为 OpenCode **2.0.32**。历史 v1 配置保留在 `opencode-v1` 标签；其他版本使用前应核对 OpenCode 原生格式和权限行为。
