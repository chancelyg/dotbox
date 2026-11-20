#!/usr/bin/env bash
# 安装或更新 Pi 共同规则与 Skills；不修改个人设置，不联网。
set -euo pipefail
[[ $# == 0 ]] || { echo '用法：bash pi/install.sh' >&2; exit 1; }
repo=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
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
valid() {
    [[ $1 != /* && $1 != *..* && $1 != *$'\n'* ]] || return 1
    case "$1" in AGENTS.md|skills/*|licenses/*) return 0 ;; *) return 1 ;; esac
}
[[ -n $target && $target != "$repo" && $target != "$repo/"* && $repo != "$target/"* ]] || die '配置与源码目录不能重叠或使用根目录'
check_path "$manifest"
[[ ! -e $manifest || -f $manifest ]] || die '安装清单不是普通文件'
[[ ! -e $target/AGENTS.override.md && ! -L $target/AGENTS.override.md ]] || die '已有 AGENTS.override.md 会遮蔽全局规则，请先处理'
[[ -d $repo/skills ]] || die '缺少技能源目录'
files=(AGENTS.md)
sources=("$repo/global/AGENTS.md")
while IFS= read -r -d '' source; do
    name=${source#"$repo/"}
    case "$name" in
        skills/THIRD_PARTY_NOTICES.md|skills/LICENSES/*) name=licenses/${name#skills/} ;;
    esac
    files+=("$name"); sources+=("$source")
done < <(find "$repo/skills" \( -type f -o -type l \) -print0)

# 完整预检；同内容副本可接管，便于从手动安装迁移。
for i in "${!files[@]}"; do
    name=${files[$i]}
    valid "$name" || die "非法源路径：$name"
    check_path "${sources[$i]}"; check_path "$target/$name"
    [[ -f ${sources[$i]} ]] || die "缺少源文件：$name"
    [[ ! -e $target/$name || -f $target/$name ]] || die "目标不是普通文件：$name"
    if [[ -e $target/$name ]]; then
        if [[ ! -f $manifest ]] || ! grep -Fxq -- "$name" "$manifest"; then
            cmp -s -- "${sources[$i]}" "$target/$name" || die "已有不同内容的非受管文件：$target/$name"
        fi
    fi
done
old=()
if [[ -f $manifest ]]; then
    while IFS= read -r name || [[ -n $name ]]; do
        valid "$name" || die '安装清单含非法路径'
        check_path "$target/$name"
        [[ ! -e $target/$name || -f $target/$name ]] || die "目标不是普通文件：$name"
        old+=("$name")
    done < "$manifest"
fi
mkdir -p -- "$target"
printf '%s\n' "${files[@]}" ${old[@]+"${old[@]}"} | sort -u > "$manifest"
for i in "${!files[@]}"; do
    mkdir -p -- "$(dirname -- "$target/${files[$i]}")"
    cp -- "${sources[$i]}" "$target/${files[$i]}"
done
for name in ${old[@]+"${old[@]}"}; do
    if ! printf '%s\n' "${files[@]}" | grep -Fxq -- "$name"; then
        rm -f -- "$target/$name"
    fi
done
printf '%s\n' "${files[@]}" > "$manifest"
printf '已同步 %s 个文件到 %s。请在 Pi 中运行 /reload 并检查加载诊断。\n' "${#files[@]}" "$target"
