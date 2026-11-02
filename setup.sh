#!/usr/bin/env bash
# 只放置文档导航，不安装配置、不启动 OpenCode。
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
config=${XDG_CONFIG_HOME:-$HOME/.config}; config=${config%/}
safe_path "$config/opencode/dotbox.md"
[[ $config != "$repo" && $config != "$repo/"* && $repo != "$config/"* ]] || die '配置目录不能与克隆目录重叠'
target=$config/opencode/dotbox.md
marker='<!-- Managed by dotbox setup.sh: navigation only -->'
if [[ -e $target ]]; then
    [[ -f $target ]] || die '导航目标不是普通文件'
    IFS= read -r first <"$target" || die '不能读取已有文件标识'
    [[ $first == "$marker" ]] || die '已有个人 dotbox.md，未覆盖'
fi
mkdir -p -- "$config/opencode"
tmp=$(mktemp "$config/opencode/.dotbox-navigation.XXXXXXXX")
trap 'rm -f -- "$tmp"' EXIT
{
    printf '%s\n\n# dotbox 使用入口\n\n' "$marker"
    printf '本地克隆：%s\n\n权威说明：%s/opencode/README.md\n\n' "$repo" "$repo"
    printf '%s\n' '在需要初始化的目标仓库打开 OpenCode，使用 Build 并说：' ''
    printf '%s\n' '> 按 OpenCode 配置目录中的 dotbox.md 初始化当前仓库。' ''
    printf '%s\n' '更新时由当前项目代理执行：' '' '> 按 dotbox.md 检查并引入适用的更新。' ''
    printf '%s\n' '请读取上面的权威说明；本文件仅导航，不授予安装、迁移或部署权限。'
    printf '%s\n' '不要把 dotbox 克隆误当作待初始化项目；克隆移动后重新运行 setup.sh。'
} >"$tmp"
if [[ -f $target ]] && cmp -s "$tmp" "$target"; then
    printf '导航无需更新：%s\n' "$target"
else
    mv -- "$tmp" "$target"
    printf '已放置导航：%s\n未安装代理、技能或其他配置。\n' "$target"
fi
