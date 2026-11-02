# OpenCode 项目引入与更新

**已有项目先看 [更新记录](#更新记录)，再按 [后续更新](#后续更新) 审阅实际差异。首次使用看 [首次引入](#首次引入)；旧全局安装先看 [旧安装迁移](#旧安装迁移)。** 本文是唯一引入与更新入口，不提供 `/onboard` 或自定义 `/init`。

## 首次引入

1. 克隆 dotbox，在任意目录运行克隆内的 `setup.sh`。脚本从自身位置解析克隆，只创建带受管标记和本 README 路径的 `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/dotbox.md`，不安装配置、代理、技能或插件，不启动 AI。
2. 在**目标仓库**打开 OpenCode，首次选用内置 **Build**，发送：

   > 请读取 `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/dotbox.md` 指向的 README，按其中的首次引入流程调查当前项目，向我集中确认 Coding 或 Ops 及重要差异，再生成项目配置。

   这里的路径由代理按实际环境解析，不要求用户提供 dotbox 克隆路径。导航缺失或失效时先报告并请用户重新运行 setup，不猜测路径或扫描主目录。`dotbox.md` 只是导航文件，不是自动加载的全局规则。
3. 按下面的调查、确认、生成和验收流程完成。初始化属于当前工作区的项目元数据维护，不默认创建功能 Worktree、安装依赖、启动服务、部署或执行 Git 提交。

### 调查与集中确认

执行引入的代理先检查 Git 状态、适用的祖先/根/子目录 `AGENTS.md`、README、清单与锁文件、CI、验证入口及主要架构。按需调查 `CLAUDE.md`、Cursor / Copilot 规则和已有 OpenCode 配置、代理、命令、技能与指令引用；保留局部适用范围和有效人工约定，不读取或展开凭证、私密引用。

从项目证据确定用途与现状后，一次集中展示重要决策及冲突，请用户确认：

- **Coding 或 Ops**：选择一个主模式；说明选用的流程、必要技能与拟修改文件。普通项目不额外强制 TDD 或多代理调查。
- **Coding** 默认保留源代理完整的 Worktree、计划、实施、验证、交付与受授权 Git 流程；仅由已确认的项目约定覆盖，例如原地开发，不把默认流程删成简短口号。
- **Ops** 保留目标、Local / Remote 授权、连接、风险确认与验收边界；从本仓库已整理的 Ops 模板与技能引入共同方法，结合目标项目现有 runbook 适配，不要求访问模板作者的运维仓库，也不复制私有主机清单。
- 展示现有自定义主代理、全局遗留与所选模式的冲突。**用户其他自定义代理未经确认不得禁用**；用户选择保留其他主模式时，说明未达到“唯一主模式”，不伪称完成。
- 模型继承用户现有选择，不硬编码 Provider 或模型；个人 MCP、凭证与无关配置不动。全局偏好源 [`AGENTS.md`](AGENTS.md) 仅作参考，不盲目复制到项目。

项目事实不足时标明未知，只就影响产出的缺口澄清；不猜测测试命令，不为形式创建空文档或技能。

### 生成自包含项目文件

确认后增量生成或合并：

| 文件 | 内容边界 |
| --- | --- |
| 项目 `AGENTS.md` | 项目事实、精确验证命令与前置条件、特殊边界、已有文档导航及简短引入记录；不复制通用代理流程 |
| `.opencode/agents/coding.md` **或** `ops.md` | 所选主模式完整流程与授权规则，适配项目实际路径 |
| `.opencode/agents/planner.md` | 保留可按需调用的只读设计/审查子代理及完整交接协议 |
| `.opencode/skills/` | 仅必要专项方法及其被引用的支持文件、来源与许可 |
| 原有项目原生配置，或 `.opencode/opencode.jsonc` | 合并主模式选择与禁用项，保留其他有效设置 |

生成文件必须自包含：不通过 `{file:...}`、软链接或运行时指令依赖 dotbox 克隆；内部引用改为项目内实际路径，技能支持文件一起引入。克隆仅用于以后审阅更新，不是日常工作前提。

选 Coding 的最小模式配置如下；选 Ops 时将 `default_agent` 改为 `ops`，禁用项改为未选的 `coding`：

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "default_agent": "coding",
  "agents": {
    "build": { "disabled": true },
    "plan": { "disabled": true },
    "ops": { "disabled": true }
  }
}
```

此片段须与已生成的主代理配合，并按现有配置增量合并，不是覆盖整份配置的模板。禁用内置 `build`、`plan` 及未选的旧 dotbox 自定义主模式；`planner`、内置 `explore` 与 `general` 保留。已确认归属的旧 `plan-designer` / `simplicity-reviewer` 需列入迁移处理，其他用户代理先展示冲突并确认。

v2 的 `agents.<id>.disabled: true` 在对应配置加载点移除代理；后续来源仍需核验。`default_agent` 只影响尚未选择代理的会话，**不会替换已有会话的选择**。权限规则追加且最后匹配生效，`skills` 数组跨来源累加；不能把“项目配置优先”解释成所有字段整块覆盖。OpenCode 内置技能依然存在，不宣称项目只剩所选技能。

### 流程与技能选择

- [Coding](agents/coding.md)：通用开发工作流；测试方法按任务需要选择，不把 TDD 作为额外初始化门槛。
- [Ops](agents/ops.md)：运维授权与执行边界。两个主要技能是 [ops-hosts](skills/ops-hosts/SKILL.md)（主机管理）与 [ops-workflows](skills/ops-workflows/SKILL.md)（运维开发验证与发布、记忆、工作区/Git、长任务）；引入其必要参考文件，不把每份 runbook 都技能化。
- [Planner](agents/planner.md)：用户明确 `@planner` 时按源协议进入设计/独立审查；结果不代替实施授权或行为验证，不自动切换回内置 Plan。
- 开发领域按需选用 [响应式](skills/responsive-design/SKILL.md)、[无障碍](skills/accessibility-compliance/SKILL.md)、[API 设计](skills/api-design-principles/SKILL.md)、[PostgreSQL](skills/postgresql-table-design/SKILL.md)。保留 [第三方来源与许可](skills/THIRD_PARTY_NOTICES.md)。
- [agent-browser](skills/agent-browser/SKILL.md) 仅在浏览器自动化任务需要时选用，不默认安装浏览器工具或配置 MCP。

**代理承载流程，AGENTS 承载项目事实和特殊边界，skill 承载专项方法。** 避免将相同约束复制到多处。

### 验收与记录

检查生成文件的原生语法、真实引用、脱敏与最终 diff；核对有效配置来源及代理列表。随后由用户在**新会话**确认所选主模式，检查旧全局代理/命令是否残留。存在残留、后续配置重新引入代理或用户保留其他主模式时，报告实际结果，不能仅凭 JSON 写好就宣布“唯一”。

静态检查只能证明文件和配置结构，不能证明模型会遵守授权、Planner 调用或 Worktree 流程。实际行为验收另按用户授权进行；初始化不默认执行真实 SSH、部署、提交、合并或推送，也不自动重启服务。

在项目 `AGENTS.md` 保留一条短记录，例如“dotbox：上次审阅 `<完整提交号>`；选用 Coding、Planner、API 设计；项目例外：原地开发”。提交号由代理对导航定位的克隆执行 `git -C <克隆目录> rev-parse HEAD` 取得；有未提交差异时注明“另含未提交差异，尚无对应提交”，不虚构本轮 SHA。该记录表示审阅基线，不是运行时加载证明。

## 后续更新

在已初始化项目的所选主模式中发送：

> 请沿 dotbox 导航读取 README 更新记录，依据项目 AGENTS.md 的上次审阅提交与选用项审阅实际差异，说明哪些值得引入，确认后只更新相关项目文件。

由用户先将 dotbox 克隆更新到希望审阅的版本；不自动拉取或覆盖脏工作区。代理读取更新记录，并比较旧记录提交与当前实际版本中相关源文件的 Git 差异；旧提交不可取得、记录缺失或克隆有本地差异时说明限制，先建立可核对基线，不伪称完整增量审阅。

按项目已有定制选择性引入，保留未选用项和有效人工约定；重要行为、权限或模式变化集中确认。完成检查后更新 AGENTS 中的短记录即可，不建立额外状态系统、版本盖章器或自动同步任务。README 是导航和变更说明，不能替代实际 diff。

## 旧安装迁移

在原 dotbox 克隆运行：

```bash
bash uninstall.sh          # 仅预览
bash uninstall.sh --apply  # 交互确认后执行
```

卸载仅处理旧全局代理、技能、自定义命令、`opencode/AGENTS.md` 和自动更新任务：与旧安装基线一致的范围内文件、经核实的 dotbox 调度和必要元数据归档到临时目录，执行时输出位置；修改过、无基线或链接对象保留并报告，不触碰私有文件。**侧边栏整套文件、`cli.json`、`opencode.json`、旧 `config.json` 和 Kitty 配置不在卸载范围内，即使有旧基线也保留。** 不拆分插件，也不需要重新安装这些保留内容；如需完整移除它们，另行审阅并明确授权。执行模式停用核实的旧调度，不自动重启 OpenCode。预览不等于迁移执行，归档也不等于模型已停止加载旧内容。

`install.sh` 仅作无副作用、非零退出的退役提示。保留项需用户核对归属后另行处理；旧全局代理、技能、命令未清理前不能承诺项目隔离或唯一主模式。完成迁移后再运行 setup、按本文引入并新建会话核验。本次修改文档或脚本不代表已替用户执行迁移。

## 可选 UI 与配置参考

[`cli.json`](cli.json)、[状态侧边栏](plugins/status-sidebar/)、[`opencode.json`](opencode.json) 和 [`opencode.jsonc`](opencode.jsonc) 保留供按需审阅选用，setup 不安装。CLI 配置属于用户级终端界面设置；插件按 v2 官方方式配置，不能因引入项目代理就顺带覆盖个人 UI、模型或 MCP。侧边栏仅显示可验证的额度指标，不把凭证输出到界面、日志或缓存。

## 更新记录

### 卸载范围修正

- 仅退出旧全局规则与自动更新，不再归档 UI、侧边栏或通用配置，避免插件部分文件被修改时发生拆分。
- 使用旧版卸载脚本但尚未执行的用户，更新脚本后重新预览；若已经归档插件文件，先核对归档和当前修改，再在确认后恢复缺失文件，不覆盖现有定制。setup 不会自动补装插件。

### 项目化引入（本轮，提交号以实际 Git 记录为准）

- 全局安装与定时同步退役；setup 只写 README 导航，uninstall 提供有基线的保守迁移。
- 删除自定义 init；首次由 Build 调查与集中确认，再生成自包含的 Coding 或 Ops 项目配置。
- 项目中禁用 Build / Plan 与未选 dotbox 主模式，保留 Planner / Explore / General；其他用户代理先确认冲突。
- 取消额外强制 TDD / 多代理初始化；明确流程、项目事实和专项方法分层。
- 精简 Coding/Ops 的重复规则；Code 仍默认完整 Worktree，Ops 的授权集中在主代理，技能只提供方法。新增隔离开发验证参考，不把项目主机、路径或 live 架构选择推广为全局规则。
- 移除代理固定模型和安装盖章，主代理保留独立的凭证、授权与证据底线，不依赖另装全局规则。
- 后续按项目 AGENTS 的短记录审阅 README 和真实差异，选择性更新，不自动同步。

本文基线为本机 **OpenCode 2.0.32**；文档可随上游演进，其他版本需核对。官方 v2 依据：[Agents](https://opencode.ai/v2/docs/agents/)、[Skills](https://opencode.ai/v2/docs/skills/)、[Commands](https://opencode.ai/v2/docs/commands/)、[Config](https://opencode.ai/v2/docs/config/)。
