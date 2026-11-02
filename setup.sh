#!/usr/bin/env bash
# 只注册 README 引导命令，不安装代理、不启动 OpenCode。
set -euo pipefail
umask 077
die() { printf '错误：%s\n' "$*" >&2; exit 1; }
safe_path() {
    local path=$1 part probe= rest
    [[ $path == /* && $path != *[[:cntrl:]]* ]] || die "需要不含控制字符的绝对路径：$path"
    rest=${path#/}
    while [[ -n $rest ]]; do
        part=${rest%%/*}
        if [[ $rest == */* ]]; then rest=${rest#*/}; else rest=; fi
        case "$part" in ''|.|..) die '路径不能含空分段、. 或 ..' ;; esac
        probe=$probe/$part
        [[ ! -L $probe ]] || die "路径不能经过符号链接：$probe"
    done
}
[[ $# == 0 ]] || die '用法：bash setup.sh'
[[ -n ${HOME:-} ]] || die 'HOME 未设置'
[[ ! -L ${BASH_SOURCE[0]} ]] || die '请直接运行克隆中的脚本，不使用符号链接'
repo=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
[[ -f $repo/opencode/README.md && ! -L $repo/opencode/README.md ]] || die '缺少 opencode/README.md'
# 命令模板会展开 $ 参数和 !`shell`；路径不能被误当作模板表达式。
[[ $repo != *[[:cntrl:]]* && $repo != *'$'* && $repo != *'`'* ]] || die '克隆路径不能含控制字符、$ 或反引号（命令模板保留字符）'
config=${XDG_CONFIG_HOME:-$HOME/.config}; config=${config%/}
safe_path "$config/opencode/commands/onboard.md"
[[ $config != "$repo" && $config != "$repo/"* && $repo != "$config/"* ]] || die '配置目录不能与克隆目录重叠'
target=$config/opencode/commands/onboard.md
marker='# Managed by dotbox setup.sh: onboard command'
if [[ -e $target ]]; then
    [[ -f $target ]] || die '命令目标不是普通文件'
    { IFS= read -r first && IFS= read -r second; } <"$target" || die '不能读取已有文件标识'
    [[ $first == '---' && $second == "$marker" ]] || die '已有个人 onboard.md，未覆盖'
fi
mkdir -p -- "$config/opencode/commands"
tmp=$(mktemp "$config/opencode/commands/.dotbox-onboard.XXXXXXXX")
legacy_tmp=
trap 'rm -f -- "$tmp"; if [[ -n $legacy_tmp ]]; then rm -f -- "$legacy_tmp"; fi' EXIT
{
    printf '%s\n' '---' "$marker" 'description: 按 dotbox README 初始化、收尾或更新当前仓库规则' 'subagent: false' '---' ''
    printf '%s\n' '请求参数（仅支持留空或 update，其他需求请在普通聊天中说明）：' '' '$ARGUMENTS' ''
    printf '%s\n' '保持当前会话和当前代理，不切换到固定代理。' ''
    printf '本地克隆：%s\n\n权威说明：%s/opencode/README.md\n\n' "$repo" "$repo"
    printf '%s\n' '先读取权威说明，再按参数与仓库现状进入首次引入、待切换收尾或 update 流程；说明缺失时停止并报告，不扫描其他克隆。'
    printf '%s\n' '用户确认前不写入。不得在当前执行代理仍为 Build/Plan 或身份不明时禁用它；先完成新代理准备，切换后再收尾。'
    printf '%s\n' '不要把 dotbox 克隆误当作待初始化项目；克隆移动后重新运行 setup.sh。'
} >"$tmp"
if [[ -f $target ]] && cmp -s "$tmp" "$target"; then
    printf '/onboard 无需更新：%s\n' "$target"
else
    mv -- "$tmp" "$target"
    printf '已注册 /onboard：%s\n未安装代理、技能或其他配置。\n' "$target"
fi

# 只删除本脚本旧版的原样导航；人工修改、其他克隆或链接均保留。
legacy=$config/opencode/dotbox.md
if [[ -e $legacy || -L $legacy ]]; then
    if [[ -L $legacy ]]; then
        printf '保留链接 dotbox.md，不读取其目标。\n'
    elif [[ -f $legacy ]]; then
        legacy_tmp=$(mktemp "$config/opencode/.dotbox-legacy.XXXXXXXX")
        {
            printf '%s\n\n# dotbox 使用入口\n\n' '<!-- Managed by dotbox setup.sh: navigation only -->'
            printf '本地克隆：%s\n\n权威说明：%s/opencode/README.md\n\n' "$repo" "$repo"
            printf '%s\n' '在需要初始化的目标仓库打开 OpenCode，使用 Build 并说：' ''
            printf '%s\n' '> 按 OpenCode 配置目录中的 dotbox.md 初始化当前仓库。' ''
            printf '%s\n' '更新时由当前项目代理执行：' '' '> 按 dotbox.md 检查并引入适用的更新。' ''
            printf '%s\n' '请读取上面的权威说明；本文件仅导航，不授予安装、迁移或部署权限。'
            printf '%s\n' '不要把 dotbox 克隆误当作待初始化项目；克隆移动后重新运行 setup.sh。'
        } >"$legacy_tmp"
        if cmp -s "$legacy" "$legacy_tmp"; then
            rm -- "$legacy"
            printf '已移除原样旧导航 dotbox.md。\n'
        else
            printf '保留已有 dotbox.md（个人内容、修改或其他克隆）；不再将它作为入口。\n'
        fi
    else
        printf '保留非普通文件 dotbox.md；不再将它作为入口。\n'
    fi
fi
printf '在目标仓库运行 /onboard；后续更新运行 /onboard update。初始化先保留 Build，切换新代理后再收尾。\n'
