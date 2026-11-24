#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET="${DOTBOX_SKILLS_DIR:-${HOME:?HOME 未设置}/.agents/skills}"

uninstall_skills() {
    local dest name count=0
    for dest in "$TARGET"/*; do
        [[ -L "$dest" ]] || continue
        name="${dest##*/}"
        if [[ "$(readlink -- "$dest")" == "$ROOT/skills/$name" ]]; then
            rm -- "$dest"
            printf '已卸载：%s\n' "$name"
            count=$((count + 1))
        fi
    done
    printf '完成：已卸载 %s 个 Skills；其他内容保持不变。\n' "$count"
}

uninstall_all() {
    # 当前仅包含 Skills，保留独立入口供后续扩展。
    uninstall_skills
}

printf 'dotbox 卸载\n目标目录：%s\n1) 卸载 Skills\n2) 全部卸载\n0) 退出\n' "$TARGET"
while true; do
    if ! read -r -p '请选择 [0/1/2]：' choice; then
        printf '\n已取消。\n'
        exit 0
    fi
    case "$choice" in
        1|2)
            if ! read -r -p '确认卸载？[y/N]：' confirm; then
                printf '\n已取消。\n'
                exit 0
            fi
            case "$confirm" in
                y|Y|yes|YES)
                    if [[ "$choice" == 1 ]]; then
                        uninstall_skills
                    else
                        uninstall_all
                    fi
                    ;;
                *) printf '已取消。\n' ;;
            esac
            break
            ;;
        0) exit 0 ;;
        *) printf '无效选项，请输入 0、1 或 2。\n' ;;
    esac
done
