#!/usr/bin/env bash
# 只删除 .dotbox-files 清单内的标准文件，不清空全局配置目录。
set -euo pipefail
[[ $# == 0 ]] || { echo '用法：bash uninstall.sh' >&2; exit 1; }
target=${XDG_CONFIG_HOME:-$HOME/.config}/opencode
manifest=$target/.dotbox-files
die() { printf '错误：%s\n' "$*" >&2; exit 1; }
check_path() {
    local p=$1
    [[ $p == /* && $p != *'/../'* ]] || die "需要绝对路径：$p"
    while [[ $p != / ]]; do
        [[ ! -L $p ]] || die "不操作符号链接：$p"
        p=$(dirname -- "$p")
    done
}
check_path "$manifest"
[[ -e $manifest ]] || { echo '没有 dotbox 安装清单，无需卸载。'; exit 0; }
[[ -f $manifest ]] || die '安装清单不是普通文件'
files=()
while IFS= read -r name; do
    [[ $name != /* && $name != *..* ]] || die '安装清单含非法路径'
    case "$name" in AGENTS.md|agents/*.md|skills/*|licenses/*|commands/dotbox.md) ;; *) die '安装清单含非标准路径' ;; esac
    check_path "$target/$name"
    [[ ! -e $target/$name || -f $target/$name ]] || die "目标不是普通文件：$name"
    files+=("$name")
done < "$manifest"
for name in ${files[@]+"${files[@]}"}; do rm -f -- "$target/$name"; done
rm -- "$manifest"
printf '已卸载 dotbox 标准文件；个人配置及项目文件保留。\n'
