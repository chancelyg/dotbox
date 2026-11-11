#!/usr/bin/env bash
# 安装全局标准文件。由 update.sh 传入 --update 更新；不修改个人 JSON 配置。
set -euo pipefail
repo=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
target=${XDG_CONFIG_HOME:-$HOME/.config}/opencode
manifest=$target/.dotbox-files
mode=${1:-install}
[[ $# -le 1 && ( $mode == install || $mode == --update ) ]] || { echo '用法：bash setup.sh' >&2; exit 1; }
die() { printf '错误：%s\n' "$*" >&2; exit 1; }
check_path() {
    local p=$1
    [[ $p == /* && $p != *'/../'* ]] || die "需要绝对路径：$p"
    while [[ $p != / ]]; do
        [[ ! -L $p ]] || die "不操作符号链接：$p"
        p=$(dirname -- "$p")
    done
}
valid() {
    [[ $1 != /* && $1 != *..* ]] || return 1
    case "$1" in AGENTS.md|agents/*.md|skills/*|licenses/*|commands/dotbox.md) return 0 ;; *) return 1 ;; esac
}
check_path "$manifest"
[[ $target != "$repo" && $target != "$repo/"* && $repo != "$target/"* ]] || die '配置与源码目录不能重叠'
[[ ! -e $manifest || -f $manifest ]] || die '安装清单不是普通文件'
[[ $mode != --update || -f $manifest ]] || die '尚未安装，请先运行 setup.sh'
[[ -d $repo/opencode/agents && -d $repo/opencode/skills ]] || die '缺少代理或技能源目录'

files=(AGENTS.md commands/dotbox.md)
sources=("$repo/opencode/AGENTS.md" "$repo/opencode/commands/dotbox.md")
while IFS= read -r -d '' source; do
    name=${source#"$repo/opencode/"}
    # 许可说明不能放在 skills 根目录，否则 OpenCode 会把它识别为技能。
    case "$name" in
        skills/THIRD_PARTY_NOTICES.md|skills/LICENSES/*) name=licenses/${name#skills/} ;;
    esac
    files+=("$name"); sources+=("$source")
done < <(find "$repo/opencode/agents" "$repo/opencode/skills" \( -type f -o -type l \) -print0)

# 写入前检查整个范围。同名个人文件不认领；受管文件按标准源直接替换。
for i in "${!files[@]}"; do
    name=${files[$i]}
    valid "$name" && [[ $name != *$'\n'* ]] || die "非法文件路径：$name"
    check_path "${sources[$i]}"; check_path "$target/$name"
    [[ -f ${sources[$i]} ]] || die "缺少源文件：$name"
    [[ ! -e $target/$name || -f $target/$name ]] || die "目标不是普通文件：$name"
    if [[ -e $target/$name ]]; then
        [[ -f $manifest ]] && grep -Fxq -- "$name" "$manifest" || die "已有非 dotbox 文件，请先处理：$target/$name"
    fi
done
old=()
if [[ -f $manifest ]]; then
    while IFS= read -r name; do
        valid "$name" || die '安装清单含非法路径'
        check_path "$target/$name"
        [[ ! -e $target/$name || -f $target/$name ]] || die "目标不是普通文件：$name"
        old+=("$name")
    done < "$manifest"
fi

mkdir -p -- "$target"
# 先登记范围，写入中断后可重新运行同一版本的 setup/update。
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
printf '已安装 %s 个标准文件到 %s。在项目中运行 /dotbox。\n' "${#files[@]}" "$target"
