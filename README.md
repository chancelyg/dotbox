# dotbox

个人常用、可公开分享的配置文件归档。

## 目录约定

仓库根目录对应 `$HOME/.config`，配置保持原始路径层级，不按应用类型重新分类：

- `kitty/kitty.conf` → `$HOME/.config/kitty/kitty.conf`
- `opencode/agents/` → `$HOME/.config/opencode/agents/`

## 使用

按需将目标文件复制或链接到对应配置路径。使用前请检查配置是否适合当前系统和已安装的软件版本。

### Linux 可选安装

不使用安装器也可以继续单独参考、复制配置。安装器仅支持 OpenCode，不改变配置的原有目录结构。

```bash
git clone https://github.com/chancelyg/dotbox.git "$HOME/.dotbox"
bash "$HOME/.dotbox/install.sh"
```

`~/.dotbox` 只是示例位置；脚本从自身位置解析仓库，不依赖执行时的当前目录。需要 Bash、Git、GNU coreutils、diffutils 的 `cmp` 和 util-linux 的 `flock`；使用干净、已提交的分支。安装器不提交、重置或暂存任何内容。

安装时确认 OpenCode，随后处理同名配置冲突，并询问是否启用每日自动更新（默认否；选择否会关闭已有 dotbox 定时器）。明确管理的文件仅为：

- `opencode/AGENTS.md`
- `opencode/agents/coding.md`、`ops.md`、`simplicity-reviewer.md`
- `opencode/commands/init.md`

不安装 `opencode.jsonc`，不接管个人模型、MCP、凭证、其他配置或长期记忆。配置复制到 `${XDG_CONFIG_HOME:-$HOME/.config}`，不软链接整个目录。首次同名文件不同需确认后备份；后续发现受管文件被本地修改或删除会停止，重新安装也不会绕过保护。需要恢复更新时，先自行保存本地修改，再恢复到安装基线。源文件删除时，仅移除仍与基线一致的受管副本。

在实际仓库位置运行：

```bash
bash /path/to/dotbox/install.sh update               # 联网获取 upstream，仅快进并安全应用
bash /path/to/dotbox/install.sh status               # 本地版本、文件一致性、最近检查和定时器状态
bash /path/to/dotbox/install.sh disable-auto-update  # 关闭定时器，保留配置和备份
```

`status` 不联网，不把上次检查或本地提交当作远程实时最新版。`update` 要求当前分支有远程 upstream，本地领先、分叉、未提交修改、目标冲突或网络错误均停止。所有操作共用非阻塞锁，已有任务运行时请稍后重试。

自动更新仅使用 `systemd --user` 的 `dotbox-update.timer`，每天运行，错过的日历任务会在定时器重新激活后补跑。没有可用用户 systemd 时仍可手动安装和更新；不提供 cron 回退、不提权、不自动启用 linger，退出登录后能否运行由系统已有设置决定。可用 `journalctl --user -u dotbox-update.service` 查看失败详情。

定时器绑定实际仓库和 XDG 路径，运行安装时批准的脚本副本。仓库内 `install.sh` 变化后，自动更新只同步仓库，暂停配置应用；审阅后手动重新安装才能批准新版脚本。不会自动执行仓库钩子或重新启动 OpenCode。仓库移动后需从新位置重新安装以刷新绑定；同一用户改用其他克隆需要确认，不生成多套定时器。

安装版本、受管内容基线、批准脚本、最近检查及备份保存在 `${XDG_STATE_HOME:-$HOME/.local/state}/dotbox`，不写入仓库。配置或状态路径含符号链接、与仓库重叠时拒绝安装。普通应用错误会尝试恢复原配置，备份保留供手动恢复；断电或强制终止不保证自动恢复。备份不会自动清理，请按需自行管理。配置更新后须退出并重新启动 OpenCode，已有会话不会热加载新规则。

### OpenCode Coding 与计划审查

使用 Coding 模式时，可一并安装 `opencode/agents/coding.md` 和 `opencode/agents/simplicity-reviewer.md` 到 `$HOME/.config/opencode/agents/`。修改后退出并重启 OpenCode，使代理定义重新加载。

Coding 对正式 Plan 执行“规划 → 简约性挑战 → 修订 → 实现 → 验证”：每轮使用新的只读 reviewer 会话，合理方案直接放行，同一任务最多 5 轮。轮数是主代理提示词约束，不是程序级强制限制；计划审查不替代实际测试。子代理未配置、未加载、无调用权限或调用失败时，Coding 明确说明未进行独立审查，退回自审后继续；已知有效阻塞问题仍须解决，不因跳过或达到上限而自动放行。具体规则见 `opencode/agents/coding.md`。

## 公开范围

本仓库只保留可公开的通用配置，不收录凭证、私钥、Token、机器专属状态、缓存或日志。本地覆盖和敏感配置应保留在仓库之外。
