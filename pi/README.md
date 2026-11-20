# Pi 配置

使用 Pi 原生全局规则与 Agent Skills，不定义自有 agent 格式、不安装子代理或模式切换扩展，也不需要 Pi Package。

## 全局来源与目标

目标根目录为 `${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}`：

| 仓库来源 | 全局目标 |
| --- | --- |
| `global/AGENTS.md` | `AGENTS.md` |
| `skills/<名称>/` | `skills/<名称>/` |
| `skills/THIRD_PARTY_NOTICES.md` | `licenses/THIRD_PARTY_NOTICES.md` |
| `skills/LICENSES/` | `licenses/LICENSES/` |

不安装仓库根的开发规则，不复制 OpenCode 主代理、配置或命令。不修改 `settings.json`、`auth.json`、模型、MCP 或会话。

## 安装与更新

在仓库根执行，或从任意目录使用脚本的绝对路径：

```bash
bash pi/install.sh
```

更新时先自行更新并审阅本地克隆，再运行同一条命令。不自动 `git pull`，不联网，不安装 Pi 程序。

- 使用目标目录的 `.dotbox-files` 记录受管文件；重跑覆盖受管副本，并删除清单中的退役文件。
- 同名非受管文件只有与源文件内容完全一致时才接管，兼容此前手动复制的副本。接管后更新会覆盖、卸载会删除；不希望受管的同名文件应先自行处理。
- 同名文件内容不同则停止，不自动合并；拒绝符号链接路径、非普通文件目标及源码目录与目标重叠。
- 存在 `AGENTS.override.md` 时停止安装，避免全局规则被遮蔽。其他候选规则如 `CLAUDE.md`、`~/.agents/skills/` 和项目内同名技能仍需自行核对。
- 受管副本不保留人工定制，清单没有内容基线、备份或回退功能。项目差异保存在项目规则中。

## 卸载

```bash
bash pi/uninstall.sh
```

直接删除 `.dotbox-files` 清单内的文件及清单，保留空目录、个人配置和其他文件。受管文件即使被人工修改也会删除。没有清单时不处理；此前手动安装的副本须先运行安装脚本接管，才能按清单卸载。

两个脚本都没有预览或 `--apply` 模式。运行前如需核对已有受管范围，可查看：

```bash
less -- "${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/.dotbox-files"
```

脚本面向 macOS / Linux 的 Bash，修改后运行 `bash -n pi/install.sh pi/uninstall.sh`，并在临时 `PI_CODING_AGENT_DIR` 下验证，不用真实配置测试卸载。

## 使用

在 Pi 中运行 `/reload`，检查加载诊断和 Skills，再在真实任务中验证行为。文件同步不代表当前会话已经重载。

- `/skill:discuss`：澄清需求、检验前提和比较方向。
- `/skill:investigate`：深入取证、核实事实和原因。
- `/skill:plan`：将明确方向写成正式实施方案。
- `/skill:review-plan`：复核方案范围、必要性和可实施性。

这些都是当前会话的方法，不是独立代理，不隔离上下文、不强制改变工具权限，也不自动执行后续阶段。专项 Skills 同样按任务需要加载。

Coding / Ops 的项目差异放在项目 `AGENTS.md` 中，例如开发工作区、精确验证命令、远程环境授权与恢复约定；不在 Pi 中创建虚构的 `default_agent` 设置。

文档基线为 Pi 1.5.2。新环境应核对客户端版本、全局规则来源及 Skills 加载诊断。
