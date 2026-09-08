#!/usr/bin/env bash
# Linux 可选安装入口；配置仍按仓库中的原生路径归档。
set -Eeuo pipefail
umask 077

# 先解析整个函数，避免更新 checkout 时 Bash 继续读取已被替换的脚本。
main() {
die() { printf '错误：%s\n' "$*" >&2; exit 1; }
ask() { local answer; read -r -p "$* [y/N] " answer || return 1; [[ $answer == y || $answer == Y ]]; }
hash() { sha256sum -- "$1" | cut -d ' ' -f 1; }

[[ $(uname -s) == Linux ]] || die '目前仅支持 Linux。'
for tool in git realpath flock sha256sum mktemp cp mv cmp; do
    command -v "$tool" >/dev/null || die "缺少依赖：$tool"
done
action=${1:-install}
case "$action" in install|update|status|disable-auto-update) ;; *) die '用法：bash install.sh [install|update|status|disable-auto-update]' ;; esac
[[ $# -le 1 || ( $# -eq 2 && $action == update ) ]] || die '参数过多。'
script=$(realpath -- "${BASH_SOURCE[0]}")
repo=$(dirname -- "$script")
# 第二个参数仅供定时器运行已批准的脚本副本时绑定仓库。
[[ $# -lt 2 ]] || repo=$(realpath -e -- "$2")
config=${XDG_CONFIG_HOME:-$HOME/.config}
state=${XDG_STATE_HOME:-$HOME/.local/state}/dotbox
unit=dotbox-update
files=(opencode/AGENTS.md opencode/agents/coding.md opencode/agents/ops.md
       opencode/agents/simplicity-reviewer.md opencode/commands/init.md)

# 不沿链接覆盖文件，也不让本地状态或配置写回源码仓库。
safe_path() {
    [[ $1 == /* && $1 != *[[:cntrl:]]* ]] || die "需要不含控制字符的绝对路径：$1"
    [[ $(realpath -m -s -- "$1") == "$(realpath -m -- "$1")" ]] || die "路径含符号链接：$1"
}
safe_path "$config"
safe_path "$state"
config=$(realpath -m -- "$config")
state=$(realpath -m -- "$state")
[[ $repo != *[[:cntrl:]]* ]] || die '仓库路径不能含控制字符。'
for path in "$config" "$state"; do
    [[ $path != "$repo" && $path != "$repo/"* && $repo != "$path/"* ]] || die '仓库不能与配置或状态目录重叠。'
done
[[ $config != "$state" && $config != "$state/"* && $state != "$config/"* ]] || die '配置和状态目录不能重叠。'
current=$state/current
units=$config/systemd/user
if [[ ! -d $current && $action == status ]]; then
    printf '尚未安装。\n'
    exit 0
fi
mkdir -p -- "$state"
safe_path "$state/lock"
exec 9>"$state/lock"
flock -n 9 || die '另一个安装或更新正在运行，请稍后重试。'
safe_path "$current"
safe_path "$state/last-check"
[[ ! -e $current || -d $current ]] || die '安装状态不是目录。'
# 安装器自己的状态不允许链接；不读取其他应用的状态。
if [[ -d $current ]]; then
    for path in repository config revision runner.sh "${files[@]}"; do
        safe_path "$current/$path"
    done
    [[ $(<"$current/config") == "$config" ]] || die '配置目录与上次安装不同，请使用原 XDG_CONFIG_HOME。'
fi

transaction=
applying=0
finish() {
    local code=$? file failed=0
    trap - EXIT INT TERM
    if (( applying )); then
        printf '应用未完成，正在恢复原配置……\n' >&2
        for file in "${files[@]}"; do
            if [[ -f $transaction/before/$file ]]; then
                cp -p -- "$transaction/before/$file" "$config/$file" || failed=1
            elif [[ -f $transaction/absent/$file ]]; then
                rm -f -- "$config/$file" || failed=1
            fi
        done
        if [[ -d $transaction/previous-state ]]; then
            if [[ -d $current ]] && ! mv -- "$current" "$transaction/failed-state"; then
                failed=1
            else
                mv -- "$transaction/previous-state" "$current" || failed=1
            fi
        elif [[ -d $current && ! -d $candidate ]]; then
            mv -- "$current" "$transaction/failed-state" || failed=1
        fi
        (( failed == 0 )) || printf '恢复失败，请从备份手动恢复：%s\n' "$transaction" >&2
    fi
    if [[ $action == update ]]; then
        printf '%s 更新退出码=%s（0 表示已完成；详情见命令输出或用户 journal）\n' "$(date -Is)" "$code" >"$state/last-check"
    fi
    exit "$code"
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

systemd_available() { command -v systemctl >/dev/null && systemctl --user show-environment >/dev/null 2>&1; }
check_units() {
    local suffix line
    for suffix in service timer; do
        safe_path "$units/$unit.$suffix"
        if [[ -e $units/$unit.$suffix ]]; then
            [[ -f $units/$unit.$suffix ]] || die "unit 不是普通文件：$unit.$suffix"
            IFS= read -r line <"$units/$unit.$suffix"
            [[ $line == '# Managed by dotbox install.sh' ]] || die "不修改非 dotbox unit：$unit.$suffix"
        fi
    done
}
auto_status() {
    if ! systemd_available; then printf '不可查询（用户 systemd 不可用）';
    elif systemctl --user is-enabled --quiet "$unit.timer"; then
        if systemctl --user is-active --quiet "$unit.timer"; then printf '开启'; else printf '已启用但未运行'; fi
    else printf '关闭'; fi
}
check_local() {
    local file
    for file in "${files[@]}"; do
        safe_path "$config/$file"
        [[ ! -e $config/$file || -f $config/$file ]] || die "目标不是普通文件：$file"
        if [[ -f $current/$file ]]; then
            if [[ ! -f $config/$file ]] || ! cmp -s -- "$current/$file" "$config/$file"; then
                die "受管文件已被本地修改或删除：$file"
            fi
        fi
    done
}

if [[ $action == status ]]; then
    printf '管理对象：OpenCode\n仓库：%s\n配置目录：%s\n安装版本：%s\n' "$(<"$current/repository")" "$config" "$(<"$current/revision")"
    if [[ -d $(<"$current/repository") ]]; then
        printf '仓库当前版本：'
        git -C "$(<"$current/repository")" rev-parse HEAD
    else printf '仓库已移动或不存在，请从新位置重新安装。\n'; fi
    printf '自动更新：%s\n' "$(auto_status)"
    if [[ -f $state/last-check ]]; then
        safe_path "$state/last-check"
        printf '最近检查：%s\n' "$(<"$state/last-check")"
    fi
    printf '这是本地状态，不代表远程当前版本；执行 update 联网检查。\n'
    check_local
    printf '受管文件：与安装基线一致。\n'
    exit 0
fi

if [[ $action == disable-auto-update ]]; then
    check_units
    [[ -f $units/$unit.timer ]] || die '此配置目录没有 dotbox 安装器生成的定时器。'
    systemd_available || die '用户 systemd 不可用，无法确认定时器已关闭。'
    systemctl --user disable --now "$unit.timer"
    printf '自动更新已关闭；配置、备份和 unit 文件保留。\n'
    exit 0
fi

[[ $(git -C "$repo" rev-parse --show-toplevel) == "$repo" ]] || die '脚本必须位于 Git 仓库根目录。'
[[ -z $(git -C "$repo" status --porcelain --untracked-files=all) ]] || die '仓库存在未提交内容；请先自行处理，安装器不会重置或暂存。'
git -C "$repo" symbolic-ref -q HEAD >/dev/null || die '不支持 detached HEAD，请使用分支。'
check_local
if [[ -d $current && $(<"$current/repository") != "$repo" ]]; then
    [[ $action == install ]] || die '更新仓库与安装绑定不同，请重新安装。'
    ask "现有安装绑定其他位置，是否改绑到 $repo？" || die '未改绑。'
fi

if [[ $action == update ]]; then
    [[ -d $current ]] || die '请先运行交互安装。'
    upstream=$(git -C "$repo" rev-parse --symbolic-full-name '@{upstream}') || die '当前分支未配置 upstream。'
    branch=$(git -C "$repo" symbolic-ref --short HEAD)
    remote=$(git -C "$repo" config --get "branch.$branch.remote")
    [[ $remote != . ]] || die '自动更新需要远程 upstream。'
    export GIT_TERMINAL_PROMPT=0
    git -C "$repo" -c core.hooksPath=/dev/null fetch --no-tags "$remote"
    git -C "$repo" merge-base --is-ancestor HEAD "$upstream" || die '本地领先或已分叉，不自动合并。'
    # 避免快进覆盖 ignored 路径；同时保留 Git 自身的保护。
    while IFS= read -r -d '' path; do
        [[ ! -e $repo/$path && ! -L $repo/$path ]] || die "更新路径与本地文件冲突：$path"
    done < <(git -C "$repo" diff --name-only --diff-filter=A -z HEAD "$upstream")
    git -C "$repo" -c core.hooksPath=/dev/null merge --ff-only --no-overwrite-ignore "$upstream"
    [[ -f $repo/install.sh && ! -L $repo/install.sh ]] || die '安装脚本不是普通文件，请人工检查仓库更新。'
    [[ $(hash "$repo/install.sh") == "$(hash "$current/runner.sh")" ]] || die '安装脚本已更新；配置尚未应用，请审阅后手动运行 install.sh 重新批准。'
else
    printf '可安装对象：1) OpenCode（代理、全局指令及 init 命令，不含 opencode.jsonc）\n'
    ask '是否安装 OpenCode？' || exit 0
fi

revision=$(git -C "$repo" rev-parse HEAD)
if [[ $action == update && $(<"$current/revision") == "$revision" ]]; then
    printf '受管配置已是本次检查版本：%s\n' "$revision"
    exit 0
fi
transaction=$(mktemp -d "$state/backup-XXXXXXXX")
candidate=$transaction/next-state
mkdir -p -- "$candidate" "$transaction/before" "$transaction/absent"
printf '%s\n' "$repo" >"$candidate/repository"
printf '%s\n' "$config" >"$candidate/config"
printf '%s\n' "$revision" >"$candidate/revision"
[[ -f $repo/install.sh && ! -L $repo/install.sh ]] || die '安装脚本必须是普通文件。'
cp -- "$repo/install.sh" "$candidate/runner.sh"
for file in "${files[@]}"; do
    entry=$(git -C "$repo" ls-tree "$revision" -- "$file")
    if [[ -n $entry ]]; then
        [[ $entry == '100644 '* ]] || die "源配置不是普通文件：$file"
        mkdir -p -- "$(dirname -- "$candidate/$file")"
        git -C "$repo" show "$revision:$file" >"$candidate/$file"
    fi
    if [[ -f $config/$file && ! -f $current/$file && -f $candidate/$file ]] && ! cmp -s -- "$config/$file" "$candidate/$file"; then
        if [[ $action != install ]] || ! ask "已有不同配置 $file，是否备份并替换？"; then
            die "未授权替换：$file"
        fi
    fi
    if [[ -f $candidate/$file || -f $current/$file ]]; then
        if [[ -f $config/$file ]]; then
            mkdir -p -- "$(dirname -- "$transaction/before/$file")"
            cp -p -- "$config/$file" "$transaction/before/$file"
        else
            mkdir -p -- "$(dirname -- "$transaction/absent/$file")"
            touch -- "$transaction/absent/$file"
        fi
        printf '应用：%s%s\n' "$file" "$( [[ -f $candidate/$file ]] || printf '（源已删除，将移除受管副本）' )"
    fi
done
# 所有检查和备份完成后才写配置；普通错误/信号回滚，断电需使用保留备份。
applying=1
for file in "${files[@]}"; do
    if [[ -f $candidate/$file ]]; then
        mkdir -p -- "$(dirname -- "$config/$file")"
        cp -- "$candidate/$file" "$config/$file"
    elif [[ -f $current/$file ]]; then
        rm -- "$config/$file"
    fi
done
[[ ! -d $current ]] || mv -- "$current" "$transaction/previous-state"
mv -- "$candidate" "$current"
applying=0
printf '已安装 OpenCode：%s\n备份：%s\n请退出并重新启动 OpenCode，使新配置生效。\n' "$revision" "$transaction"

# systemd 不经过 shell；禁止变量展开，并独立转义 unit 的引号和 specifier。
unit_quote() {
    local value=$1
    value=${value//\\/\\\\}; value=${value//\"/\\\"}; value=${value//%/%%}
    printf '"%s"' "$value"
}
if [[ $action == install ]]; then
    if ! systemd_available; then
        printf '用户 systemd 不可用，未配置自动更新；仍可手动执行 update。\n'
        exit 0
    fi
    check_units
    printf '自动更新会每天同步当前分支 upstream 并应用上述配置，包括代理权限规则。\n不会重启 OpenCode、启用 linger 或申请 root；退出登录后的运行取决于系统设置。\n'
    if ! ask '是否启用自动更新？（选择否将关闭已有 dotbox 定时器）'; then
        if [[ -f $units/$unit.timer ]] && { systemctl --user is-enabled --quiet "$unit.timer" || systemctl --user is-active --quiet "$unit.timer"; }; then
            systemctl --user disable --now "$unit.timer"
        fi
        exit 0
    fi
    git -C "$repo" rev-parse '@{upstream}' >/dev/null || die '配置已安装，但启用自动更新需要分支 upstream。'
    mkdir -p -- "$units"
    {
        printf '# Managed by dotbox install.sh\n[Unit]\nDescription=Update dotbox OpenCode configuration\n[Service]\nType=oneshot\n'
        printf 'Environment=%s\n' "$(unit_quote "XDG_CONFIG_HOME=$config")" "$(unit_quote "XDG_STATE_HOME=${state%/dotbox}")"
        printf 'ExecStart=:/bin/bash %s update %s\n' "$(unit_quote "$current/runner.sh")" "$(unit_quote "$repo")"
        printf 'TimeoutStartSec=5min\n'
    } >"$transaction/$unit.service"
    printf '# Managed by dotbox install.sh\n[Unit]\nDescription=Daily dotbox update\n[Timer]\nOnCalendar=daily\nPersistent=true\nRandomizedDelaySec=15min\n[Install]\nWantedBy=timers.target\n' >"$transaction/$unit.timer"
    cp -- "$transaction/$unit.service" "$units/$unit.service"
    cp -- "$transaction/$unit.timer" "$units/$unit.timer"
    systemctl --user daemon-reload
    systemctl --user enable --now "$unit.timer"
    printf '每日自动更新已开启；仓库移动后请从新位置重新运行 install.sh。\n'
fi
}

main "$@"
