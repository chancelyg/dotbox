# dotbox

个人常用、可公开分享的配置文件归档。

## 目录约定

仓库根目录对应 `$HOME/.config`，配置保持原始路径层级，不按应用类型重新分类：

- `kitty/kitty.conf` → `$HOME/.config/kitty/kitty.conf`
- `opencode/agents/` → `$HOME/.config/opencode/agents/`
- `opencode/skills/` → `$HOME/.config/opencode/skills/`

## 使用

按需将目标文件复制或链接到对应配置路径。使用前请检查配置是否适合当前系统和已安装的软件版本。

### Linux / macOS 可选安装

不使用安装器也可以继续单独参考、复制配置。安装器支持 OpenCode 和 Kitty，不改变配置的原有目录结构。

```bash
git clone https://github.com/chancelyg/dotbox.git "$HOME/.dotbox"
bash "$HOME/.dotbox/install.sh"
```

`~/.dotbox` 只是示例位置；脚本从自身位置解析仓库，不依赖执行时的当前目录。需要 Bash、Git 和系统基础命令，兼容 macOS 自带的 Bash 3.2；使用干净、已提交且配置了远程 upstream 的分支。安装器不提交、推送、重置或暂存任何内容。

安装时统一确认 OpenCode 和 Kitty，随后处理同名配置冲突，并询问是否启用每 6 小时自动更新（默认否；选择否会关闭当前平台已有的 dotbox 调度任务）。明确管理的文件仅为：

- `opencode/AGENTS.md`
- `opencode/agents/coding.md`、`ops.md`、`plan-designer.md`、`simplicity-reviewer.md`
- `opencode/commands/init.md`
- `opencode/skills/` 下列出的开发与运维技能及第三方来源、许可证文件
- `kitty/kitty.conf`

不安装 `opencode.jsonc`，不接管个人模型、MCP、凭证、其他配置或长期记忆。`kitty/current-theme.conf` 等本地主题和生成文件也不受管理，更新 `kitty.conf` 时不会删除它们。配置复制到 `${XDG_CONFIG_HOME:-$HOME/.config}`，不软链接整个目录。首次同名文件不同需确认后备份；后续发现受管文件被本地修改或删除会停止，重新安装也不会绕过保护。需要发布本机修改时，先手动更新仓库并 commit/push，再让其他设备自动拉取；安装器不会自动上传。源文件删除时，仅移除仍与基线一致的受管副本。

在实际仓库位置运行：

```bash
bash /path/to/dotbox/install.sh update               # 联网获取 upstream，仅快进并安全应用
bash /path/to/dotbox/install.sh status               # 本地版本、文件一致性、最近检查和自动更新状态
bash /path/to/dotbox/install.sh disable-auto-update  # 关闭自动更新，保留配置、备份和调度文件
```

`status` 不联网，不把上次检查或本地提交当作远程实时最新版。`update` 要求当前分支有远程 upstream，本地领先、分叉、未提交修改、目标冲突或网络错误均停止。所有操作共用非阻塞锁，已有任务运行时请稍后重试。

Linux 自动更新使用 `systemd --user` 的 `dotbox-update.timer`：用户管理器启动 5 分钟后首次检查，此后在每次任务结束 6 小时后再次检查。macOS 使用 `~/Library/LaunchAgents/io.github.chancelyg.dotbox-update.plist`：加载时检查一次，之后以 `21600` 秒为间隔；设备睡眠时不会被唤醒，错过的多个间隔会在唤醒后合并为一次。两者都不是每天某个固定钟点触发。调度器不可用时仍可手动安装和更新；不提供 cron 回退、不提权、不自动启用 Linux linger，退出登录后的运行取决于系统已有设置。Linux 可用 `journalctl --user -u dotbox-update.service` 查看服务输出；其他失败可手动运行 `update` 查看详情。

调度任务绑定实际仓库和 XDG 路径，运行安装时批准的脚本副本。仓库内 `install.sh` 变化后，自动更新只同步仓库，暂停配置应用；审阅后手动重新安装才能批准新版脚本。不会自动执行仓库钩子、重新启动 OpenCode 或 Kitty。`kitty.conf` 当前启用了 Kitty 自身的自动重载；OpenCode 配置更新后仍须退出并重新启动。仓库移动后需从新位置重新安装以刷新绑定；同一用户改用其他克隆需要确认，不生成多套调度任务。

安装版本、受管内容基线、批准脚本、最近检查及备份保存在 `${XDG_STATE_HOME:-$HOME/.local/state}/dotbox`，不写入仓库。配置或状态路径含符号链接、与仓库重叠时拒绝安装。普通应用错误会尝试恢复原配置，备份保留供手动恢复；断电或强制终止不保证自动恢复。备份不会自动清理，请按需自行管理。

### OpenCode Coding / Ops 与方案设计、审查

使用 Coding 或 Ops 模式时，可将对应代理与 `opencode/agents/plan-designer.md`、`opencode/agents/simplicity-reviewer.md` 一并安装到 `$HOME/.config/opencode/agents/`。`plan-designer` 是共享只读子代理，不覆盖 OpenCode 内置的主代理 `plan`。修改后退出并重启 OpenCode，使代理定义重新加载。

正式规划执行“主代理取证 → `plan-designer` 设计候选方案 → 主代理核验并形成草案 → `simplicity-reviewer` 独立审查 → 修订与展示最终方案 → 原授权流程 → 实施与验证”。设计与审查分开：前者比较真实备选并检查合理性，后者独立检查草案，主代理保留最终裁决与授权管理。既有能力、官方接口与原生配置优先；非标准补丁须说明依据、影响、验证、回退、维护与退出条件，明确区分临时缓解和根因修复。

设计默认单次新会话，只有关键输入改变才重新设计，不因每条审查意见自动回到设计代理；其 `READY` / `BLOCKED` 是候选设计状态，不表示授权或 reviewer 通过。reviewer 每轮使用新会话，同一计划阶段最多 5 轮，设计调用不计入此轮数。最终方案注明审查轮数和状态；轮数是提示词约束，不是程序级强制限制。子代理不可用时主代理明确说明未独立设计或审查，按对应标准自行处理；有效关键阻塞不因降级或达到上限自动放行。

方案质量审查与执行授权分开：Coding 的正式 Plan 仍须用户确认；Ops 保留 Local / Low 的现有授权方式，High 仍分别确认方案与批准执行，连接确认也不变。两个子代理只在客户端读取明确参考范围，不执行命令、连接远端或写文件；运行状态和版本匹配的官方资料由主代理取证提供。已确认的同份最终方案不重启规划，实施后不自动重新调用；简单改动例外见 `coding.md` 与 `ops.md`，High 不豁免。提示词和配置检查不能证明模型始终给出合理方案，实际行为仍需验证。

设计机制参考 [Superpowers brainstorming](https://github.com/obra/superpowers/blob/8ca22dba9a94f28898bbce59f2537ff4d87c747d/skills/brainstorming/SKILL.md) / [writing-plans](https://github.com/obra/superpowers/blob/8ca22dba9a94f28898bbce59f2537ff4d87c747d/skills/writing-plans/SKILL.md)、[Spec Kit planning](https://github.com/github/spec-kit/blob/838f1184d1b2ed254a99e8b818dbc23aa80a7f1f/templates/commands/plan.md) 和 [wshobson architect](https://github.com/wshobson/agents/blob/156b7a5e7a8b93642628a339ee4039c925b34c7f/plugins/ship-mate/agents/architect.md)；前两者是技能 / 命令工作流，后者是 agent。本仓库自行编写只读设计协议，不引入它们的写文件、提交、审批或平台流程。

### OpenCode 开发技能

安装器会将以下技能复制到 `$HOME/.config/opencode/skills/`，由 OpenCode 根据任务描述按需加载；它们只提供领域知识，不替代 Coding 的计划、Worktree、验证或 Git 流程：

- `responsive-design`：容器查询、流式排版、Grid/Flexbox 和响应式媒体。
- `accessibility-compliance`：WCAG 2.2、语义 HTML、键盘与焦点、ARIA 和辅助技术支持。
- `api-design-principles`：REST/GraphQL 资源、契约、错误、分页和版本演进。
- `postgresql-table-design`：PostgreSQL 类型、约束、索引、分区和安全模式演进。

技能来自 MIT 许可的 [`wshobson/agents`](https://github.com/wshobson/agents)，固定来源、引入范围和许可文本见 `opencode/skills/THIRD_PARTY_NOTICES.md`。技能或代理文件更新后，需要退出并重新启动 OpenCode。

### OpenCode Ops 按需协议

`opencode/agents/ops.md` 保留目标、授权、安全和验收规则；`opencode/skills/ops-workflows/SKILL.md` 按任务触发读取记忆维护、工作区与 Git、长任务的参考协议，不在每次排障时全量加载。该技能为本仓库维护，不属于上述第三方开发技能。

安装器同时管理 Ops 代理、技能入口及三个参考文件；手动复制时也须一并安装到对应配置路径。未登记主机不自动触发初始化提问，High 双确认和连接确认保持不变。配置更新后退出并重启 OpenCode。

## 公开范围

本仓库只保留可公开的通用配置，不收录凭证、私钥、Token、机器专属状态、缓存或日志。本地覆盖和敏感配置应保留在仓库之外。
