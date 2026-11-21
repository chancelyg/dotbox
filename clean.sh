#!/usr/bin/env bash
# 仅清理旧 .dotbox-files 清单；默认预览，--apply 才删除。
set -euo pipefail
apply=false
case "${1:-}" in
    '') [[ $# == 0 ]] || { echo '用法：bash clean.sh [--apply]' >&2; exit 1; } ;;
    --apply) [[ $# == 1 ]] || { echo '用法：bash clean.sh [--apply]' >&2; exit 1; }; apply=true ;;
    *) echo '用法：bash clean.sh [--apply]' >&2; exit 1 ;;
esac

die() { printf '错误：%s\n' "$*" >&2; exit 1; }
check_path() {
    local p=$1
    [[ $p == /* && $p != *'/../'* && $p != *'/./'* && $p != *'//'* ]] || die "非法绝对路径：$p"
    while [[ $p != / ]]; do
        [[ ! -L $p ]] || die "不操作符号链接路径：$p"
        p=$(dirname -- "$p")
    done
}
check_file() {
    check_path "$1"
    [[ ! -e $1 || -f $1 ]] || die "目标不是普通文件：$1"
}

opencode=${XDG_CONFIG_HOME:-$HOME/.config}/opencode
pi=${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}
files=()
manifests=()
# 两端均完成校验后才开始删除；不要与安装或客户端更新并发执行。
for client in opencode pi; do
    if [[ $client == opencode ]]; then target=$opencode; else target=$pi; fi
    target=${target%/}
    [[ -n $target ]] || die '不能使用根目录'
    manifest=$target/.dotbox-files
    check_file "$manifest"
    if [[ ! -e $manifest ]]; then
        printf '没有旧清单，跳过：%s\n' "$manifest"
        continue
    fi
    while IFS= read -r name || [[ -n $name ]]; do
        [[ -n $name && $name != /* && $name != *..* && $name != */ && $name != *'//'* && /$name/ != *'/./'* ]] || die "清单含非法路径：$manifest"
        case "$client:$name" in
            opencode:AGENTS.md|opencode:agents/*.md|opencode:skills/*|opencode:licenses/*|opencode:commands/dotbox.md|pi:AGENTS.md|pi:skills/*|pi:licenses/*|pi:extensions/status.ts) ;;
            *) die "清单含非受管路径：$name" ;;
        esac
        check_file "$target/$name"
        files+=("$target/$name")
    done < "$manifest"
    manifests+=("$manifest")
done

for file in ${files[@]+"${files[@]}"} ${manifests[@]+"${manifests[@]}"}; do
    if [[ -e $file ]]; then printf '待删除：%s\n' "$file"; else printf '已缺失：%s\n' "$file"; fi
done
if ! $apply; then
    printf '仅预览。旧清单无内容基线，无法识别人工修改；请先保存需保留的副本，再运行 bash clean.sh --apply。\n'
    exit 0
fi
for file in ${files[@]+"${files[@]}"} ${manifests[@]+"${manifests[@]}"}; do
    check_file "$file"
    if [[ -e $file ]]; then
        rm -- "$file" || die "删除失败：$file；此前已报告删除的文件不会恢复，其余对象未继续处理"
        printf '已删除：%s\n' "$file"
    fi
done
printf '清理完成；保留目录、非受管文件及个人配置。未安装软链，未修改旧代理设置。\n'
