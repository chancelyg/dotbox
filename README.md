# dotbox

个人常用、可公开分享的配置，以及 OpenCode 标准代理、规则、技能和分发脚本。`main` 使用 OpenCode v2 原生格式，当前版本基线为 **2.0.32**。

## OpenCode 快速开始

```bash
git clone https://github.com/chancelyg/dotbox.git "$HOME/.dotbox"
bash "$HOME/.dotbox/setup.sh"
```

`setup.sh` 将以下标准文件复制到 `${XDG_CONFIG_HOME:-$HOME/.config}/opencode`：

- 共同规则 `AGENTS.md`
- Coding、Ops 主代理，以及 Discuss、Investigator、Planner、Reviewer 子代理
- 全部标准 Skills 及其支持文件
- 项目定位命令 `/dotbox`

脚本使用目标目录中的 `.dotbox-files` 记录受管文件。同名非受管文件会阻止安装，不自动覆盖、认领或合并；安装不会修改个人 JSON 配置、模型、MCP、插件或默认代理。

安装后，在目标项目运行 `/dotbox`。命令会调查项目现有规则和用途，建议合适的主模式，并在确认后只增量设置项目配置中的 `default_agent`。详细说明见 [OpenCode README](opencode/README.md)。

## 更新与卸载

先由用户自行更新本地克隆，再同步标准文件：

```bash
git -C "$HOME/.dotbox" pull --ff-only
bash "$HOME/.dotbox/update.sh"
```

`update.sh` 不自动执行 `git pull`，只从当前克隆覆盖受管文件，并删除清单中已经退役的标准文件。

卸载会直接删除 `.dotbox-files` 清单内的受管文件及清单本身，不清空 OpenCode 配置目录，也不处理个人配置和项目文件：

```bash
bash "$HOME/.dotbox/uninstall.sh"
```

三个脚本都没有预览或 `--apply` 模式。需要检查影响范围时，可先查看 `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/.dotbox-files`。

`install.sh` 是为旧调用方式保留的退役入口，只输出当前命令说明并以非零状态退出，不修改文件或联网。

## 功能导航

- [OpenCode 详细说明](opencode/README.md)：安装范围、项目定位、更新和卸载规则。
- [共同规则](opencode/AGENTS.md)：授权、调查、验证、长期记忆和子代理调用边界。
- [代理](opencode/agents/)：Coding、Ops 主模式及 Discuss、Investigator、Planner、Reviewer 子代理。
- [Skills](opencode/skills/)：开发领域和浏览器自动化专项方法。
- [CLI 配置](opencode/cli.json)：可选的终端界面配置，不由脚本安装。
- [状态侧边栏](opencode/plugins/status-sidebar/)：可选插件，不由脚本安装。
- [配置参考](opencode/opencode.json) 与 [带注释示例](opencode/opencode.jsonc)：仅供按需审阅，不替换个人配置。

## 公开范围

仓库仅保留可公开的通用配置。凭证、私钥、Token、私有主机信息、机器状态、缓存、日志和个人覆盖应留在仓库外。第三方技能来源与许可见 [THIRD_PARTY_NOTICES.md](opencode/skills/THIRD_PARTY_NOTICES.md)。

历史 `opencode-v1` 标签固定 v1 兼容版本（`be42c2c`，当时验证版本 1.18.35），不跟随 `main` 更新。本仓库不安装 OpenCode 程序，也不迁移会话数据。
