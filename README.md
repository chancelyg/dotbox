# dotbox

个人可公开分享的配置。OpenCode 与 Pi 共用全局规则和 Skills，客户端只保留原生配置与扩展。

## 内容

| 路径 | 用途 |
| --- | --- |
| [`global/AGENTS.md`](global/AGENTS.md) | 两端共用的全局规则 |
| [`skills/`](skills/) | 讨论、调查、规划、方案复核及专项技能 |
| [`docs/coding.md`](docs/coding.md) / [`docs/ops.md`](docs/ops.md) | 代码 / 运维仓库初始化参考 |
| [`opencode/`](opencode/README.md) | 可选配置与插件，使用原生 Build / Plan |
| [`pi/`](pi/README.md) | 可选单行状态栏扩展 |
| `codex/`、`kitty/` | 其他工具配置，独立选用 |
| [`clean.sh`](clean.sh) | 旧安装清理，默认仅预览 |
| [`AGENTS.md`](AGENTS.md) | 本仓库开发约定，不是全局安装源 |

初始化项目时，让助手调查实际用途、环境和已有约定，参考 `docs/coding.md` 或 `docs/ops.md` 制定项目自己的 `AGENTS.md`。不要机械复制；这些文档不会自动加载，也不会自动更新已初始化仓库的流程。

## 旧安装清理

首次使用可跳过。有过旧脚本安装时，先在仓库根运行：

```bash
bash clean.sh          # 查看两端旧 .dotbox-files 清单中的删除对象
bash clean.sh --apply  # 确认并保存需要保留的副本后执行
```

旧清单只有路径，无法识别人工修改。脚本仅删除清单内文件和清单，保留目录及非受管内容；没有清单则跳过，异常路径或符号链接会阻止清理。不操作新的共享链接，不修改个人 JSON 或其他仓库。不要与安装、更新并发执行。

旧个人配置或项目配置中的 `default_agent: coding/ops`、Build / Plan 禁用项需自行移除；非受管旧代理及同名技能也需核对，避免遮蔽共享内容。

## 软链安装

先克隆到稳定路径，然后在仓库根执行下列 Bash 命令。两端自动发现 `~/.agents/skills`，无需各装一份。

```bash
repo=$(pwd -P)
opencode=${XDG_CONFIG_HOME:-$HOME/.config}/opencode
pi=${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}

link() {
    if [ -L "$2" ] && [ "$(readlink "$2")" = "$1" ]; then
        return 0
    fi
    if [ -e "$2" ] || [ -L "$2" ]; then
        printf '目标已存在，请先核对处理：%s\n' "$2" >&2
        return 1
    fi
    ln -s "$1" "$2"
}

# 在子 shell 中遇错即停；不覆盖已有文件或目录。
(
    set -e
    mkdir -p "$opencode" "$pi" "$HOME/.agents"
    link "$repo/global/AGENTS.md" "$opencode/AGENTS.md"
    link "$repo/global/AGENTS.md" "$pi/AGENTS.md"
    link "$repo/skills" "$HOME/.agents/skills"
)
```

`~/.agents/skills` 若已存在，先自行保存和整理其内容；不要强制覆盖或递归删除。客户端原有同名技能副本需移除或另行处理，避免不同发现优先级导致两端加载不同版本。Pi 若存在 `AGENTS.override.md`，也需先核对是否遮蔽全局规则。

安装仅共享指令，不统一权限、模型、MCP 或会话。OpenCode 的代理权限不会迁移为 Pi 的执行限制。可选状态栏见 [Pi 说明](pi/README.md)。

## 更新与移除

在仓库执行 `git pull` 即更新软链源，无需同步脚本。Pi 运行 `/reload`；OpenCode 必要时重载配置或新建会话，并核对加载结果。修改仓库源文件会直接影响后续加载，不存在额外安装隔离。

移除时先用 `readlink` 核实链接指向，再仅删除链接本身；不要删除目标仓库内容。`clean.sh` 只处理旧安装，不负责新链接卸载。

不保存凭证或私有机器信息。第三方来源与许可见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。共享路径依据 OpenCode V2 与 Pi 1.5.2 文档；文件可读不代表模型必定按预期执行。
