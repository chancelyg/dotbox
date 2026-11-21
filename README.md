# dotbox

dotbox 只维护客户端无关的 AI Agent 全局规则与 Skills，不提供客户端配置、插件或安装脚本。

## 内容

| 路径 | 用途 |
| --- | --- |
| [`global/AGENTS.md`](global/AGENTS.md) | 全局规则：共同偏好、授权边界、调查与验证原则 |
| [`skills/`](skills/) | 共享工作方法与专项技能 |
| [`AGENTS.md`](AGENTS.md) | 本仓库维护约定，不是全局规则源 |
| [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md)、[`LICENSES/`](LICENSES/) | 第三方来源与许可 |

## 使用与维护

按所用客户端的原生机制加载 `global/AGENTS.md`，发现或注册 `skills/`；具体接入方式由使用者管理，不覆盖个人文件。

全局规则提供共同偏好，项目事实和特殊约定由目标项目的 `AGENTS.md` 维护。Skills 是按需加载的工作方法，不定义独立代理，也不改变工具权限。

更新仓库后，由客户端重新加载相应内容；文件可读不代表已加载或模型行为已经验证。个人配置、凭证和机器状态不进入本仓库。
