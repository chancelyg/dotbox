# dotbox

dotbox 保存可公开分享的配置、AI CLI 共同规则、Skills 和仓库流程参考；不是应用项目。

## 内容

| 路径 | 用途 |
| --- | --- |
| [`global/AGENTS.md`](global/AGENTS.md) | AI CLI 共用的全局规则 |
| [`skills/`](skills/) | 讨论、调查、规划、方案复核及专项技能 |
| [`docs/coding.md`](docs/coding.md) / [`docs/ops.md`](docs/ops.md) | 代码 / 运维仓库初始化参考 |
| [`opencode/`](opencode/README.md) | 可选配置与插件，使用原生 Build / Plan |
| [`pi/`](pi/README.md) | 可选单行状态栏扩展 |
| `codex/`、`kitty/` | 其他工具配置，独立选用 |
| [`clean.sh`](clean.sh) | 旧安装清理，默认仅预览 |
| [`AGENTS.md`](AGENTS.md) | 本仓库开发约定，不是全局安装源 |

初始化项目时，让助手调查实际用途、环境和已有约定，参考 `docs/coding.md` 或 `docs/ops.md` 制定项目自己的 `AGENTS.md`。不要机械复制；这些文档不会自动加载，也不会自动更新已初始化仓库的流程。

## 配置

将仓库克隆到稳定路径。以下 `/绝对路径/dotbox` 请替换为实际路径；配置项合并到已有文件，数组追加，不覆盖个人设置。

### OpenCode

在全局配置 `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.jsonc`（已有 `opencode.json` 时沿用）中添加：

```json
{
  "instructions": ["/绝对路径/dotbox/global/AGENTS.md"],
  "skills": ["/绝对路径/dotbox/skills"]
}
```

`instructions` 是追加加载，不替换自动发现的规则。若此前已将同一份规则链接到 OpenCode 的全局 `AGENTS.md`，核实后移除该链接，避免重复加载；不要删除其他个人规则。

### Pi

在 `${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/settings.json` 中添加：

```json
{
  "skills": ["/绝对路径/dotbox/skills"]
}
```

Pi 没有对应的 `instructions` 配置项。将 `${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/AGENTS.md` 作为单文件软链，指向仓库的 `global/AGENTS.md`。目标已有文件时先核对并保留个人内容，不强制覆盖；同目录的 `AGENTS.override.md` 会优先加载，也需检查。

## 可选界面扩展

### OpenCode 侧边栏

在上述 OpenCode 全局配置中追加插件**目录**：

```json
{
  "plugins": ["/绝对路径/dotbox/opencode/plugins/status-sidebar"]
}
```

一个条目同时加载服务端和 TUI 部分，不要填写 `index.ts`，也不要在 `cli.json` 重复注册。在全局 `cli.json`（与 OpenCode 全局配置同目录）中确保侧栏未被隐藏：

```json
{
  "session": { "sidebar": "auto" }
}
```

重新打开终端界面；若本地插件未重载，使用后台服务时执行 `opencode service restart` 后重新打开。侧栏仅在终端宽度足够时显示。插件展示主机、CPU/RAM、生成速度、最近用户消息，以及可获取的 OpenAI 订阅额度或 DeepSeek 余额；额度查询会使用已有认证访问相应服务。详细行为和排查见 [OpenCode 说明](opencode/README.md#状态侧边栏)。

### Pi 状态栏

在上述 Pi `settings.json` 中追加扩展**文件**：

```json
{
  "extensions": ["/绝对路径/dotbox/pi/extensions/status.ts"]
}
```

运行 `/reload`，在交互式 TUI 底部检查模型、思考等级、目录、上下文和 CPU/RAM。不要同时保留旧安装副本或另一个替换 footer 的扩展；无需安装脚本或软链。显示限制见 [Pi 说明](pi/README.md#可选单行状态栏)。

停用时移除相应 `plugins` / `extensions` 路径条目，再重启 OpenCode 或在 Pi 中运行 `/reload`；不要删除其他插件设置。

## 更新与移除

在仓库执行 `git pull` 即更新共享内容，无需同步脚本。Pi 运行 `/reload`；OpenCode 必要时重载配置或新建会话，并核对加载结果。修改仓库源文件会直接影响后续加载。

移除时，仅从客户端配置中删除本仓库对应的路径条目；Pi 的规则软链先用 `readlink` 核实，再仅删除链接本身。不要删除个人配置或目标仓库内容。`clean.sh` 只处理旧清单安装。

不保存凭证或私有机器信息。第三方来源与许可见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。接入示例依据 OpenCode V2 与 Pi 1.5.2 文档；文件可读不代表模型必定按预期执行。

## 旧安装清理

首次使用可跳过。有过旧脚本安装时，先在仓库根运行：

```bash
bash clean.sh          # 查看 OpenCode / Pi 旧清单中的删除对象
bash clean.sh --apply  # 确认并保存需要保留的副本后执行
```

旧清单只有路径，无法识别人工修改。脚本仅删除清单内文件和清单，保留目录及非受管内容；没有清单则跳过，异常路径或符号链接会阻止清理。不操作新的共享链接，不修改个人 JSON 或其他仓库。不要与安装、更新并发执行。

旧个人配置或项目配置中的 `default_agent: coding/ops`、Build / Plan 禁用项需自行移除；非受管旧代理及同名技能也需核对，避免遮蔽共享内容。