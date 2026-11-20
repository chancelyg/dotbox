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

本目录不提供安装管理脚本。先检查目标目录及父路径没有符号链接，核对全局规则和同名 Skills 是否已存在；同名个人文件应先决定如何保留或合并，不能直接覆盖。还需核对 `~/.agents/skills/` 和项目技能是否有同名定义，避免重复发现。

同目录若存在 `AGENTS.override.md`，它会遮蔽 `AGENTS.md`。其他候选规则如 `CLAUDE.md` 也应先核对，不能只凭复制成功认定规则已生效。

**确认目标为空，或已有副本明确归属 dotbox 且允许覆盖后**，在仓库根执行：

```bash
target=${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}
mkdir -p "$target/skills" "$target/licenses"
cp global/AGENTS.md "$target/AGENTS.md"
for skill in skills/*/; do
    [ -f "$skill/SKILL.md" ] || continue
    cp -R "${skill%/}" "$target/skills/"
done
cp skills/THIRD_PARTY_NOTICES.md "$target/licenses/"
cp -R skills/LICENSES "$target/licenses/"
```

更新先审阅本地克隆差异，再按上述方式同步。复制不会自动删除退役文件；退役项或卸载须逐项核对来源后删除，不清空全局 `skills/` 或个人配置目录。受管副本不作为个人定制来源，项目差异记录在项目规则中。

## 使用

在 Pi 中运行 `/reload`，检查加载诊断和 Skills，再在真实任务中验证行为。文件同步不代表当前会话已经重载。

- `/skill:discuss`：澄清需求、检验前提和比较方向。
- `/skill:investigate`：深入取证、核实事实和原因。
- `/skill:plan`：将明确方向写成正式实施方案。
- `/skill:review-plan`：复核方案范围、必要性和可实施性。

这些都是当前会话的方法，不是独立代理，不隔离上下文、不强制改变工具权限，也不自动执行后续阶段。专项 Skills 同样按任务需要加载。

Coding / Ops 的项目差异放在项目 `AGENTS.md` 中，例如开发工作区、精确验证命令、远程环境授权与恢复约定；不在 Pi 中创建虚构的 `default_agent` 设置。

文档基线为 Pi 1.5.2。新环境应核对客户端版本、全局规则来源及 Skills 加载诊断。
