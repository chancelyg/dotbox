# dotbox

个人常用、可公开分享的配置与 OpenCode 项目流程参考。`main` 使用 OpenCode v2 原生格式，版本基线为 **2.0.32**。

## OpenCode 入口

**首次引入、旧版迁移和后续更新统一阅读 [OpenCode README](opencode/README.md)。** 按目标项目选择 Coding 或 Ops，由 AI 调查现有约定、确认重要差异后生成自包含的项目文件。

```bash
git clone https://github.com/chancelyg/dotbox.git "$HOME/.dotbox"
bash "$HOME/.dotbox/setup.sh"
```

`setup.sh` 从自身位置定位克隆，只注册 `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/commands/onboard.md`，不安装全局代理、技能或其他配置，也不启动 AI。在目标仓库用 Build 执行 `/onboard`，无需记住克隆路径；生成并验证新代理后，切换到它再执行 `/onboard` 收尾，最后才禁用 Build / Plan。后续由项目代理运行 `/onboard update`。

旧安装用户先按上述 README 预览 `uninstall.sh`；确认迁移范围后才使用 `--apply`。`install.sh` 已退役，仅提示并非零退出，不再安装或自动更新。

## 功能导航

- [Coding / Ops / Planner / Reviewer](opencode/agents/)：开发、运维、按需只读规划与独立方案审查的源协议。
- [Skills](opencode/skills/)：开发领域、浏览器及 Ops 专项方法；按项目需要选用。
- [CLI 配置](opencode/cli.json)：垂直会话 Tabs、项目与分支显示、会话切换快捷键。
- [状态侧边栏](opencode/plugins/status-sidebar/)：主机、模型速度、CPU / RAM、最后一条用户消息及可验证的 Provider 额度；按需选用，不由 setup 安装。
- [默认配置](opencode/opencode.json) 与 [原生配置参考](opencode/opencode.jsonc)：仅作选用参考，不替换个人模型、MCP 或凭证。

## 目录与公开范围

仓库根目录保持 `$HOME/.config` 下的原始路径层级；这不表示所有文件都应复制到全局配置。OpenCode 项目引入方式以其 README 为准。

仅保留可公开的通用配置；凭证、私钥、Token、机器状态、缓存、日志和私有覆盖留在仓库外。第三方技能来源与许可见 [THIRD_PARTY_NOTICES.md](opencode/skills/THIRD_PARTY_NOTICES.md)。

历史 `opencode-v1` 标签固定 v1 兼容版本（`be42c2c`，当时验证版本 1.18.35），不跟随 main 自动更新；程序迁移参见 [官方 v2 迁移指南](https://opencode.ai/v2/docs/migrate-v1/)。本仓库不替换 OpenCode 程序或会话数据。
