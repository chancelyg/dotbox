#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET="${DOTBOX_SKILLS_DIR:-${HOME:?HOME 未设置}/.agents/skills}"

sync_skills() {
    local source name dest count=0
    mkdir -p -- "$TARGET"
    for source in "$ROOT"/skills/*; do
        [[ -d "$source" && -f "$source/SKILL.md" ]] || continue
        name="${source##*/}"
        dest="$TARGET/$name"
        if [[ -L "$dest" && "$(readlink -- "$dest")" == "$source" ]]; then
            printf '已安装：%s\n' "$name"
        elif [[ -e "$dest" || -L "$dest" ]]; then
            printf '跳过同名内容（未覆盖）：%s\n' "$dest"
            continue
        else
            ln -s -- "$source" "$dest"
            printf '已安装：%s\n' "$name"
        fi
        count=$((count + 1))
    done
    printf '完成：%s 个 Skills 已链接到 %s\n' "$count" "$TARGET"
}

prune_skills() {
    local dest source name
    for dest in "$TARGET"/*; do
        [[ -L "$dest" ]] || continue
        name="${dest##*/}"
        source="$ROOT/skills/$name"
        if [[ "$(readlink -- "$dest")" == "$source" && ! -f "$source/SKILL.md" ]]; then
            rm -- "$dest"
            printf '已移除失效链接：%s\n' "$name"
        fi
    done
}

printf 'dotbox Skills\n目标目录：%s\n1) 安装\n2) 升级（同步当前本地仓库）\n0) 退出\n' "$TARGET"
while true; do
    if ! read -r -p '请选择 [0/1/2]：' choice; then
        printf '\n已取消。\n'
        exit 0
    fi
    case "$choice" in
        1) sync_skills; break ;;
        2) prune_skills; sync_skills; break ;;
        0) exit 0 ;;
        *) printf '无效选项，请输入 0、1 或 2。\n' ;;
    esac
done
