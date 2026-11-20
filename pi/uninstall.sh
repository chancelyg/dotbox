#!/usr/bin/env bash
# 只删除 Pi .dotbox-files 清单内的文件，不清空个人配置目录。
set -euo pipefail
[[ $# == 0 ]] || { echo '用法：bash pi/uninstall.sh' >&2; exit 1; }
target=${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}
target=${target%/}
manifest=$target/.dotbox-files
die() { printf '错误：%s\n' "$*" >&2; exit 1; }
check_path() {
    local p=$1
    [[ $p == /* && $p != *'/../'* && $p != *'/./'* ]] || die "需要不含 . 或 .. 分段的绝对路径：$p"
    while [[ $p != / ]]; do
        [[ ! -L $p ]] || die "不操作符号链接：$p"
        p=$(dirname -- "$p")
    done
}
[[ -n $target ]] || die '不能使用根目录'
check_path "$manifest"
[[ -e $manifest ]] || { echo '没有 dotbox 安装清单，无需卸载。'; exit 0; }
[[ -f $manifest ]] || die '安装清单不是普通文件'
files=()
while IFS= read -r name || [[ -n $name ]]; do
    [[ $name != /* && $name != *..* ]] || die '安装清单含非法路径'
    case "$name" in AGENTS.md|skills/*|licenses/*|extensions/status.ts) ;; *) die '安装清单含非标准路径' ;; esac
    check_path "$target/$name"
    [[ ! -e $target/$name || -f $target/$name ]] || die "目标不是普通文件：$name"
    files+=("$name")
done < "$manifest"
for name in ${files[@]+"${files[@]}"}; do rm -f -- "$target/$name"; done
rm -- "$manifest"
printf '已卸载 Pi 的 dotbox 规则、Skills 和状态栏；个人配置和其他文件保留。请运行 /reload。\n'
