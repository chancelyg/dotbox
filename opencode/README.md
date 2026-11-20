# OpenCode 配置

共同规则来自 [`../global/AGENTS.md`](../global/AGENTS.md)，所有 Skills 来自 [`../skills/`](../skills/)。本目录只保存 OpenCode 专用内容和脚本。

## 安装与更新

在克隆的仓库根目录运行：

```bash
bash opencode/setup.sh
# 自行更新本地克隆后同步
bash opencode/update.sh
```

脚本根据自身位置定位仓库，也可从其他目录使用绝对路径执行。默认目标为 `${XDG_CONFIG_HOME:-$HOME/.config}/opencode`。

| 来源 | 目标 |
| --- | --- |
| `global/AGENTS.md` | `AGENTS.md` |
| `opencode/agents/` | `agents/`，仅 Coding / Ops |
| 根 `skills/` | `skills/`，含支持文件 |
| 技能来源与许可 | `licenses/` |
| `opencode/commands/dotbox.md` | `commands/dotbox.md` |

`.dotbox-files` 记录受管文件。写入前核对范围，同名非受管文件会阻止安装，不自动认领或合并；符号链接路径和非普通文件目标会被拒绝。更新按当前源文件覆盖，并删除旧清单中的退役项。

原来安装的 Discuss、Investigator、Planner、Reviewer 四个子代理，若已在受管清单中，会在更新时移除，改用同一套 `discuss`、`investigate`、`plan`、`review-plan` Skills。非受管或项目内旧代理不会自动删除，应核实归属后单独处理。

更新不执行 `git pull`，不保留受管副本的人工定制，不修改个人 JSON 配置、模型、MCP 或全局默认代理。脚本不操作 Pi，不安装客户端或定时任务，也不迁移旧 `/onboard`、项目副本或旧调度。

## 项目使用

安装后在目标项目运行 `/dotbox`，调查项目用途并选择 Coding、Ops 或其他已安装主模式。只增量设置项目原生配置的 `default_agent`，没有配置时使用项目根 `opencode.jsonc`，不禁用其他代理。

项目差异保存在项目 `AGENTS.md` 或其引用文档，不复制标准代理或 Skills。发现旧项目定义遮蔽全局内容时先报告，不清空 `.opencode/`。默认值不会切换已有会话，需手动切换或新建会话。

- [Coding](agents/coding.md)：开发、验证和受授权 Git 交付。
- [Ops](agents/ops.md)：本机与远程调查、自动化、发布和恢复。
- [共享 Skills](../skills/)：按任务加载工作方法，不再提供四个自定义子代理；同会话复核不等于独立审核。

## 卸载

```bash
bash opencode/uninstall.sh
```

立即删除 `.dotbox-files` 中的受管文件及清单，不清空配置目录，不处理个人配置、插件或项目文件。清单仅包含路径，没有内容基线、备份或回退功能；受管文件即使被人工修改也会删除。

三个脚本没有预览或 `--apply` 模式。需要预先核对范围时：

```bash
less -- "${XDG_CONFIG_HOME:-$HOME/.config}/opencode/.dotbox-files"
```

没有清单时不会卸载。`opencode/install.sh` 是退役提示，不转调其他脚本，非零退出。原根目录脚本已移入本目录，旧调用方需更新路径。

## 可选配置与验证

[`cli.json`](cli.json)、[`opencode.json`](opencode.json)、[`opencode.jsonc`](opencode.jsonc) 和 [`plugins/status-sidebar/`](plugins/status-sidebar/) 独立选用，不由脚本安装。配置示例可能指定模型、权限或 MCP，不能直接覆盖个人设置。

在仓库根运行静态检查：

```bash
bash -n opencode/setup.sh opencode/update.sh opencode/uninstall.sh opencode/install.sh
git diff --check
```

完整安装测试使用隔离 HOME / XDG 目录。静态检查和文件复制成功不代表客户端已加载或模型行为已验证。文档基线为 OpenCode 2.0.32。
