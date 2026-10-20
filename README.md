# dotbox

个人常用、可公开分享的配置文件归档。

`main` 维护 OpenCode **v2 原生配置**，当前以 **2.0.32** 为验证基线。`opencode-v1` 标签固定 v1 兼容版本（提交 `be42c2c`，验证版本 1.18.35），不将 v2 原生文件交给 v1 使用。

继续使用 v1 时，从该标签创建自己的本地分支再运行旧安装器；旧安装器不接受 detached HEAD。不要让 v1 安装继续自动跟随 `origin/main`：先关闭原定时更新，再选择固定版本，且不要为该分支设置跟随 main 的 upstream。切换前自行处理工作区改动，安装器不会回滚或覆盖已被本地修改的配置。程序升级参照 [v2 安装与迁移指南](https://opencode.ai/v2/docs/migrate-v1/)，本仓库不替换 OpenCode 二进制、凭证或会话数据。

## 目录约定

仓库根目录对应 `$HOME/.config`，配置保持原始路径层级，不按应用类型重新分类：

- `opencode/opencode.json` → `$HOME/.config/opencode/opencode.json`（低优先级默认配置）
- `opencode/cli.json` → `$HOME/.config/opencode/cli.json`（终端界面与快捷键配置）
- `opencode/plugins/status-sidebar/` → `$HOME/.config/opencode/plugins/status-sidebar/`（V2 状态侧边栏）
- `opencode/agents/` → `$HOME/.config/opencode/agents/`
- `opencode/skills/` → `$HOME/.config/opencode/skills/`

## 使用

按需将目标文件复制或链接到对应配置路径。使用前请检查配置是否适合当前系统和已安装的软件版本。

### Linux / macOS 可选安装

不使用安装器也可以继续单独参考、复制配置。main 的安装器仅支持 OpenCode v2，保留配置的原有目录结构。先独立安装 v2，并确认 `opencode --version` 返回 2.x；程序缺失、版本查询失败或非 2.x 时拒绝安装和更新，不影响本地 `status` 查询或关闭自动更新。

```bash
git clone https://github.com/chancelyg/dotbox.git "$HOME/.dotbox"
bash "$HOME/.dotbox/install.sh"
```

`~/.dotbox` 只是示例位置；脚本从自身位置解析仓库，不依赖执行时的当前目录。需要 Bash、Git 和系统基础命令，兼容 macOS 自带的 Bash 3.2；使用干净、已提交且配置了远程 upstream 的分支。安装器不提交、推送、重置或暂存任何内容。

安装时确认 OpenCode，随后处理同名配置冲突，并询问是否启用每 6 小时自动更新（默认否；选择否会关闭当前平台已有的 dotbox 调度任务）。明确管理的文件仅为：

- `opencode/opencode.json`（低层位置被个人配置占用时跳过，不接管）
- `opencode/cli.json`
- `opencode/plugins/status-sidebar/index.ts`、`rpc.ts`、`tui.tsx`
- `opencode/AGENTS.md`
- `opencode/agents/coding.md`、`ops.md`、`planner.md`
- `opencode/commands/init.md`
- `opencode/skills/` 下列出的开发与运维技能及第三方来源、许可证文件

不安装参考文件 `opencode.jsonc`，不接管个人模型、MCP、凭证、其他配置或长期记忆。配置复制到 `${XDG_CONFIG_HOME:-$HOME/.config}`，不软链接整个目录；仅 Coding / Ops 的固定版本槽在复制时盖章，其余文件原样复制。除下述兜底配置的跳过规则外，首次同名文件不同需确认后备份；后续发现受管文件被本地修改或删除会停止，重新安装也不会绕过保护。需要发布本机修改时，先手动更新仓库并 commit/push，再让其他设备自动拉取；安装器不会自动上传。源文件删除时，仅移除仍与基线一致的受管副本。

`cli.json` 默认启用按当前工作目录隔离的垂直会话 Tabs，顶部横向 Tabs 不再显示；每个非紧凑 Tab 在标题下方显示项目名及可用的 Git 分支。使用 `Ctrl+O` 选择最近会话或项目。除 OpenCode 原生切换键外，`Shift+↑` / `Shift+↓` 分别切换上一个 / 下一个会话；为避免输入框抢占按键，默认的多行文本 `input.select.up/down` 绑定被禁用。状态侧边栏补充 HOST、会话平均与最近一轮模型速度、OpenAI Subscription / DeepSeek API 可验证额度、CPU & RAM 和最后一条用户消息；无可用额度时自动隐藏 THE USAGE。

状态侧边栏按 V2 的运行边界拆分：`tui.tsx` 只负责本地界面，`index.ts` 在 OpenCode 服务端通过 active integration 解析凭证，`rpc.ts` 只向 TUI 返回脱敏后的额度指标。凭证不进入 UI、日志或磁盘缓存；Provider 请求仅访问代码中固定的官方 HTTPS 端点，并有超时、响应大小限制、禁止重定向、内存 TTL 和失败退避。当前额度适配器仅包括已验证的 OpenAI Subscription 与 DeepSeek API；其他 Provider 不推断、不显示。

Kitty 已停止支持。安装器仅保留 `kitty/kitty.conf` 的退役路径：有旧安装基线且仍一致的副本会备份并删除，本地修改或删除仍会阻塞。无基线的个人配置、主题（如 `current-theme.conf`）和目录不会被清理。

在实际仓库位置运行：

```bash
bash /path/to/dotbox/install.sh update               # 联网获取 upstream，仅快进并安全应用
bash /path/to/dotbox/install.sh status               # 本地版本、文件一致性、最近检查和自动更新状态
bash /path/to/dotbox/install.sh disable-auto-update  # 关闭自动更新，保留配置、备份和调度文件
```

`status` 不联网，不把上次检查或本地提交当作远程实时最新版。`update` 要求当前分支有远程 upstream，本地领先、分叉、未提交修改、目标冲突或网络错误均停止。所有操作共用非阻塞锁，已有任务运行时请稍后重试。

Linux 自动更新使用 `systemd --user` 的 `dotbox-update.timer`：用户管理器启动 5 分钟后首次检查，此后在每次任务结束 6 小时后再次检查。macOS 使用 `~/Library/LaunchAgents/io.github.chancelyg.dotbox-update.plist`：加载时检查一次，之后以 `21600` 秒为间隔；设备睡眠时不会被唤醒，错过的多个间隔会在唤醒后合并为一次。两者都不是每天某个固定钟点触发。调度器不可用时仍可手动安装和更新；不提供 cron 回退、不提权、不自动启用 Linux linger，退出登录后的运行取决于系统已有设置。Linux 可用 `journalctl --user -u dotbox-update.service` 查看服务输出；其他失败可手动运行 `update` 查看详情。

调度任务绑定实际仓库和 XDG 路径，运行安装时批准的脚本副本，并复用记录的 OpenCode 程序路径检查 v2 版本，避免定时器缺少交互 shell 的 PATH。程序移动后重新安装以刷新路径。仓库内 `install.sh` 变化后，自动更新只同步仓库，暂停配置应用；审阅后手动重新安装才能批准新版脚本。不会自动执行仓库钩子、升级程序或重启 OpenCode 服务。仓库移动后需从新位置重新安装以刷新绑定；同一用户改用其他克隆需要确认，不生成多套调度任务。

安装版本、受管内容基线、批准脚本、最近检查及备份保存在 `${XDG_STATE_HOME:-$HOME/.local/state}/dotbox`，不写入仓库。配置或状态路径含符号链接、与仓库重叠时拒绝安装。普通应用错误会尝试恢复原配置，备份保留供手动恢复；断电或强制终止不保证自动恢复。备份不会自动清理，请按需自行管理。

### OpenCode 默认配置与个人覆盖

依据 [OpenCode 2.0.29 配置发现源码](https://github.com/anomalyco/opencode/blob/v2.0.29/packages/core/src/config/discovery.ts) 和 [v2 配置文档](https://opencode.ai/v2/docs/config/)，全局自动发现的文件从低到高为 `opencode.json` → `opencode.jsonc`，不包含旧 `config.json`。安装器只管理 `opencode.json`，支持覆盖的字段以个人 `opencode.jsonc` 为优先；列表等字段按各自的原生合并规则处理，不能一概承诺覆盖。其他版本使用前须核对兼容性；不使用优先级更高的 `OPENCODE_CONFIG`、inline 或系统 managed 配置充当兜底。

默认文件仅含压缩设置 `auto=true`、`buffer=10000` 和常见生成目录的 `watcher.ignore`，不设置模型、Provider、MCP、权限或插件，不自动安装依赖或要求凭证。v2 不支持旧 `prune` 和 `tail_turns`，近期上下文采用默认 token 预算，不将两轮硬换算为 token 数；需要调整时使用 `keep.tokens`。依据 [v2 压缩文档](https://opencode.ai/v2/docs/compaction/) 和 [配置 schema](https://opencode.ai/config.json)。个人覆盖示例（写入自己的 `opencode.jsonc`）：

```jsonc
{
    "$schema": "https://opencode.ai/config.json",
    "compaction": { "keep": { "tokens": 20000 } },
    "watcher": { "ignore": ["custom-output/**"] }
}
```

`compaction` 按字段叠加，例如只设 `keep.tokens` 仍保留默认层的 `buffer`。与 v1 不同，v2 的 [`watcher.ignore` 按来源累加](https://github.com/anomalyco/opencode/blob/v2.0.29/packages/core/src/config/plugin/location-watcher.ts)，个人列表不能撤销默认层的忽略项；需要取消这些项时应先调整仓库默认配置，不能通过改受管副本绕过更新保护。权限规则同样追加并按最后匹配决定。Markdown 代理定义在全局 JSON 后加载，个人 JSON 不保证覆盖其所有字段。

非受管 `opencode.json` 已存在时，即使字节相同也跳过。安装器不搬迁或合并个人文件，跳过项不进入受管基线，安装输出和 `status` 会说明未管理。旧受管 `config.json` 仅在仍与基线一致时备份并删除；本地修改或删除会阻塞迁移。无基线的个人 `config.json` 和旧 TOML `config` 保留不动，但不作为 v2 自动加载来源，需用户自行迁移有效设置。受管路径的符号链接及非普通文件仍拒绝。

仅存在 `opencode.json` 时，OpenCode 原生支持的配置保存操作可能写回它；请先创建个人 `opencode.jsonc` 再进行个人设置。受管默认文件被改写或删除后，更新会按基线保护停止，不会通过重新安装静默重置。个人 JSON 文件不由安装器创建或改写。

参考 `opencode.jsonc` 已转为 v2 的 `agents`、`providers`、`permissions`、`mcp.servers` 和 `plugins`；仍只供手动参考，不随安装器分发。代理权限使用有序规则，`shell` / `subagent` 分别替代 v1 的 `bash` / `task`，不改变既有拒绝边界；`/init` 使用 `subagent: false` 留在当前会话。现有技能目录和 `AGENTS.md` 无需为 v2 改名。

### 版本标识

- **OpenCode 程序版本**：运行 `opencode --version`，与 dotbox 配置版本分开。
- **磁盘安装版本**：运行安装器 `status` 查看完整提交号；仓库 HEAD 可能已更新但尚未应用，两者分别显示，不代表远程最新版。
- **代理提示词版本**：Coding / Ops 在已有末行中显示 `dotbox@<12 位提交号>`，完整提交号保留在代理正文。它表示该代理安装时所在的 dotbox 提交，不是模型版本或独立的代理语义版本。

安装器只替换 Coding / Ops 正文中的唯一固定版本槽，渲染后的文件同时用于安装与基线比较，失败时随配置和 revision 一起恢复。缺失或重复版本槽会在应用前停止。手动复制源文件显示 `dotbox@未盖章`；Planner 仍只返回 JSON，不追加标识。

标识来自实际提示词自报，不是程序级可信证明，不能读取磁盘新版本来冒充已加载。v2 支持配置、代理和命令热更新；全局及向上发现的 `AGENTS.md` 会在后续请求前引入变更，已经加载的嵌套规则另有更新限制。可用 `opencode debug agents` 检查解析后的代理，迁移验收建议新建会话；不要在包含私有配置的环境中公开完整 debug 输出。热更新不保证正在进行的请求或模型输出已使用新版。v2 默认使用共享后台服务，退出 CLI 不等于停止该服务；程序升级须另行重启服务，安装器不代做。详见 [v2 CLI](https://opencode.ai/v2/docs/cli/) 和 [指令更新](https://opencode.ai/v2/docs/instructions/)。

全局 `opencode/AGENTS.md` 仅保留跨角色偏好与原则；Coding 执行流程、Ops 授权流程和 Planner 只读输出分别由各代理定义。通用原则不授予执行权限，不让子代理自行提问或要求只读角色运行测试。

### OpenCode Coding / Ops 与方案设计、审查

Coding / Ops 默认自行查证、形成必要方案并按授权执行验证；不因正式 Plan、多文件、High、Skill 或普通失败自动启动子代理。只有用户在当前消息中实际输入 `@planner` 明确调用时，才启动完整流程；自然语言请求设计 / 审查、同意建议、仅提及名称或询问用法均不能代替 @ 调用。重要未决取舍可由主代理简短建议用户输入 `@planner`，收到实际调用前不得启动。

将 `opencode/agents/planner.md` 与 Coding / Ops 代理一并安装到 `$HOME/.config/opencode/agents/`，确认 v2 已发现这些代理。用户只需调用一次，例如：

```text
@planner 为这次改动设计方案并独立审查
```

一个代理定义包含 design / review 两阶段：默认设计，主代理复用结果、核验形成草案，随后自动以全新会话调用同一个 planner 的 `phase=review`，必要时裁决、修订及复审，最后展示 Plan、实际审查轮次 / 结论和关键边界。无需用户第二次 @。原设计的真实方案比较、证据和可行性检查，以及审查的完整性、必要性、复用、验证和简约性标准均保留，主代理保留最终裁决与授权管理。

设计与每轮审查均为主会话下独立的新子会话，不恢复或复用已有子会话；审查不接收设计推理或历轮争论，独立性指上下文而非不同模型。不让子代理自行递归调用，无需修改 v2 的 `experimental.subagent_depth`，也不覆盖内置主代理 `plan`。原生机制依据 [v2 agents](https://opencode.ai/v2/docs/agents/)；使用其他版本时核对兼容性。

`READY / BLOCKED` 是设计状态，`PASS / REVISE / BLOCKED` 是审查结论，不代表实施授权或实际验证通过。设计不计审查轮数，最多 5 轮审查，失败调用也计数；首轮 PASS 即结束，不为获得 PASS 空转或每轮重设计。未通过、修订后未复审、达到上限或代理不可用须如实呈现，不将自审记为独立 PASS；有效安全、授权或关键前提阻塞不因降级、轮数耗尽或用户确认消失。完整交接及边界协议见 `planner.md`。

未经用户 @ 调用时不例行报告未调用代理。一次 @ 仅启动当前 Plan，完成、取消或进入实施后关闭，不永久启用或自动延续到其他任务 / 新 Plan；本轮内部审查与必要补证无需再次 @。调用不改变 Coding 正式 Plan 确认、Ops Local / Low 授权、High 方案及执行双确认、连接确认或 Git 权限；已确认的同份 Plan 和实施中的普通修复不重启流程。触发、自动衔接和五轮限制是提示词协议，不是程序级保证；配置解析不能证明实际调用正确，须用调用轨迹验证，不宣称未测的行为成功。

安装器保留 `plan-designer.md`、`simplicity-reviewer.md` 两个旧路径作为退役对象，不再提供其源定义；只删除有安装基线且仍与基线一致的副本，本地修改或删除仍会阻塞，无基线的个人同名文件不会自动清理。手动安装者应在确认归属后自行移除旧定义，不能盲删个人代理。安装脚本更新需审阅后重新批准；代理更新按上述热更新与验收边界处理。

设计机制参考 [Superpowers brainstorming](https://github.com/obra/superpowers/blob/8ca22dba9a94f28898bbce59f2537ff4d87c747d/skills/brainstorming/SKILL.md) / [writing-plans](https://github.com/obra/superpowers/blob/8ca22dba9a94f28898bbce59f2537ff4d87c747d/skills/writing-plans/SKILL.md)、[Spec Kit planning](https://github.com/github/spec-kit/blob/838f1184d1b2ed254a99e8b818dbc23aa80a7f1f/templates/commands/plan.md) 和 [wshobson architect](https://github.com/wshobson/agents/blob/156b7a5e7a8b93642628a339ee4039c925b34c7f/plugins/ship-mate/agents/architect.md)；前两者是技能 / 命令工作流，后者是 agent。本仓库自行编写只读设计协议，不引入它们的写文件、提交、审批或平台流程。

### OpenCode 开发技能

安装器会将以下技能复制到 `$HOME/.config/opencode/skills/`，由 OpenCode 根据任务描述按需加载；它们只提供领域知识，不替代 Coding 的计划、Worktree、验证或 Git 流程：

- `responsive-design`：容器查询、流式排版、Grid/Flexbox 和响应式媒体。
- `accessibility-compliance`：WCAG 2.2、语义 HTML、键盘与焦点、ARIA 和辅助技术支持。
- `api-design-principles`：REST/GraphQL 资源、契约、错误、分页和版本演进。
- `postgresql-table-design`：PostgreSQL 类型、约束、索引、分区和安全模式演进。
- `agent-browser`：按已安装 CLI 的实际版本加载浏览器自动化工作流；不自动安装程序或创建 MCP。

前四个领域技能来自 MIT 许可的 [`wshobson/agents`](https://github.com/wshobson/agents)，固定来源、引入范围和许可文本见 `opencode/skills/THIRD_PARTY_NOTICES.md`。`agent-browser` 为本仓库维护的本机工具使用入口。更新后核对实际加载内容，不将磁盘变化视为已有会话已采用新内容。

### OpenCode Ops 按需协议

`opencode/agents/ops.md` 保留目标、授权、安全和验收规则；`opencode/skills/ops-workflows/SKILL.md` 按任务触发读取记忆维护、工作区与 Git、长任务的参考协议，不在每次排障时全量加载。`opencode/skills/ops-hosts/SKILL.md` 汇总主机管理，由 Ops 在添加、删除、验证或测试主机连接时主动加载。这两个技能为本仓库维护，不属于上述第三方开发技能。

| 请求示例 | 行为 |
| --- | --- |
| 添加主机 demo，地址 example.com，端口 2222，用户 ubuntu | 准备只显示待安装公钥、服务器指纹、服务器等级；一次简短确认后连接、核验，成功才登记 |
| 删除主机 demo | 一次确认后只删本地登记，不连接、不撤销服务器公钥、不清理共享 SSH 配置或信任记录 |
| 验证主机 demo | 默认检查本地参数、公钥、签名后端和已有信任，不登录、不自动修复 |
| 验证 demo 的服务器指纹 | 确认网络采集范围后比对可信证据，不自动接受新密钥 |
| 测试 demo / 全部主机连接 | 对当前清单中明确展示的固定集合一次确认，逐台全新认证与身份检查，不逐台弹窗、不扫描网段 |

主机管理直接沿既有技能处理，不自动启动 planner。添加准备仅三项：去私有注释的完整公钥、主机算法及 SHA256 指纹（注明可信来源或待核验）、服务器等级。无可靠本地等级记录显示 High（未核实），不提前登录查询。默认不附安装命令、教程、大确认卡或重复目标；需要时再提供。用户独立安装公钥并通过控制台等可信渠道比对指纹后，一次简短“确认”批准已明确目标的连接与本地登记，随后连续验证和登记。未知写入范围须作必要短说明并取得授权，不能为简洁静默扩大范围；公钥、签名后端、跳板或安全前提缺失时只处理对应缺口。

连接使用选定裸公钥和严格主机校验，排除其他钥匙、密码、证书替代与旧连接复用。指纹冲突、撤销或身份不符立即停止；测试汇总成功、失败、阻塞、未执行，添加还区分连接通过但登记失败。要求 Ops 代为安装或撤销远端公钥仍是独立 High 变更，方案认可与执行批准不合并。

实际主机清单、公钥引用和信任记录沿用客户端运维仓库及 SSH 原生位置，不写入本公开配置归档；没有公钥时不会生成密钥或读取私钥。未登记主机不自动触发远端初始化，主机管理不包含提交或部署。协议与静态配置检查不能代替真实 SSH 行为测试。

安装器同时管理 Ops 代理、两个技能入口及 `ops-workflows` 的三个参考文件；手动复制时也须一并安装到对应配置路径。安装器清单变化属于 `install.sh` 更新，需审阅后重新运行安装器批准，自动更新不会直接执行新版脚本。迁移后建议新建会话核验角色和标识。

## 公开范围

本仓库只保留可公开的通用配置，不收录凭证、私钥、Token、机器专属状态、缓存或日志。本地覆盖和敏感配置应保留在仓库之外。
