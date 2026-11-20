# dotbox

个人可公开分享的 AI 工具配置。共同规则和 Skills 使用同一份源文件，OpenCode 与 Pi 各自保留原生的加载方式。

## 目录

- [`global/AGENTS.md`](global/AGENTS.md)：客户端无关的共同偏好、授权、调查和验证规则。
- [`skills/`](skills/)：Discuss、Investigate、Plan、Review-plan 工作方法，以及 API、PostgreSQL、响应式、无障碍和浏览器专项技能。
- [`opencode/`](opencode/README.md)：Coding / Ops 主代理、项目定位命令、安装脚本和可选配置。
- [`pi/`](pi/README.md)：Pi 全局规则和 Skills 的安装说明，不定义自有代理体系。
- 根 `AGENTS.md`：本仓库开发约定，不是全局安装源。

四个工作方法 Skills 都在当前会话中使用，不创建子代理、不提供权限隔离，也不将方案复核声称为独立审核。项目特有的开发、运维和验证约定保存在项目 `AGENTS.md`。

## OpenCode

```bash
git clone https://github.com/chancelyg/dotbox.git "$HOME/.dotbox"
bash "$HOME/.dotbox/opencode/setup.sh"
```

更新本地克隆后运行 `opencode/update.sh`；卸载使用 `opencode/uninstall.sh`。这些脚本只处理 OpenCode，不处理 Pi。脚本直接执行，没有预览或 `--apply` 模式，具体受管范围见 [OpenCode 说明](opencode/README.md)。

## Pi

```bash
bash "$HOME/.dotbox/pi/install.sh"
```

共同规则和 Skills 安装到 `${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}`。更新本地克隆后重跑安装脚本；卸载使用 `pi/uninstall.sh`。脚本按 `.dotbox-files` 清单管理文件，详细冲突与接管规则见 [Pi 说明](pi/README.md)。不需要 `package.json`，不覆盖个人模型、认证、MCP 或设置。

## 公开范围

不保存凭证、私钥、Token、私有主机信息、机器状态、缓存、日志或个人覆盖。第三方技能来源与许可见 [THIRD_PARTY_NOTICES.md](skills/THIRD_PARTY_NOTICES.md)。

OpenCode 文档基线为 2.0.32，Pi 文档基线为 1.5.2。历史 OpenCode v1 配置保留在 `opencode-v1` 标签。本仓库不安装客户端程序或迁移会话数据。
