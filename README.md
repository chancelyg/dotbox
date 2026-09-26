# dotbox

个人常用、可公开分享的配置文件归档。

## 目录约定

仓库根目录对应 `$HOME/.config`，配置保持原始路径层级，不按应用类型重新分类：

- `kitty/kitty.conf` → `$HOME/.config/kitty/kitty.conf`
- `opencode/agents/` → `$HOME/.config/opencode/agents/`

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
- `opencode/agents/coding.md`、`ops.md`、`simplicity-reviewer.md`
- `opencode/commands/init.md`
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

### OpenCode Coding 与计划审查

使用 Coding 模式时，可一并安装 `opencode/agents/coding.md` 和 `opencode/agents/simplicity-reviewer.md` 到 `$HOME/.config/opencode/agents/`。修改后退出并重启 OpenCode，使代理定义重新加载。

Coding 对正式 Plan 执行“规划 → 简约性挑战 → 修订 → 实现 → 验证”：每轮使用新的只读 reviewer 会话，合理方案直接放行，同一任务最多 5 轮。轮数是主代理提示词约束，不是程序级强制限制；计划审查不替代实际测试。子代理未配置、未加载、无调用权限或调用失败时，Coding 明确说明未进行独立审查，退回自审后继续；已知有效阻塞问题仍须解决，不因跳过或达到上限而自动放行。具体规则见 `opencode/agents/coding.md`。

## 公开范围

本仓库只保留可公开的通用配置，不收录凭证、私钥、Token、机器专属状态、缓存或日志。本地覆盖和敏感配置应保留在仓库之外。
