#!/usr/bin/env bash
# 退出旧版受管安装，不永久删除归档，不接管个人文件。
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
        [[ ! -L $probe ]] || return 1
    done
}
unit_quote() {
    local value=$1
    value=${value//\\/\\\\}; value=${value//\"/\\\"}; value=${value//%/%%}
    printf '"%s"' "$value"
}
xml_escape() { printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }
apply=0
case "${1:-}" in '') ;; --apply) apply=1 ;; *) die '用法：bash uninstall.sh [--apply]（默认仅预览）' ;; esac
[[ $# -le 1 && -n ${HOME:-} ]] || die '参数过多或 HOME 未设置'
platform=$(uname -s)
case "$platform" in Linux|Darwin) ;; *) die '仅支持 Linux/macOS 旧安装' ;; esac
config=${XDG_CONFIG_HOME:-$HOME/.config}; config=${config%/}
state_home=${XDG_STATE_HOME:-$HOME/.local/state}; state_home=${state_home%/}
state=$state_home/dotbox; current=$state/current
safe_path "$current" && safe_path "$config" || die '配置或状态目录含符号链接'
[[ -d $current ]] || { printf '没有旧安装基线；不接管同名配置或调度任务。\n'; exit 0; }
for meta in config repository revision; do
    safe_path "$current/$meta" && [[ -f $current/$meta ]] || die "缺少可靠安装元数据：$meta"
done
[[ $(cat "$current/config") == "$config" ]] || die '配置位置与旧安装记录不同'
repo=$(cat "$current/repository")
safe_path "$repo" || die '旧仓库路径含链接，需人工核验'
[[ $config != "$state" && $config != "$state/"* && $state != "$config/"* ]] || die '状态和配置目录重叠'
for path in "$config" "$state"; do
    [[ $path != "$repo" && $path != "$repo/"* && $repo != "$path/"* ]] || die '旧仓库与配置或状态目录重叠'
done
# 固定白名单与旧安装器一致；不扫描私有配置、不移动整个目录。
files=(opencode/opencode.json opencode/cli.json opencode/AGENTS.md
    opencode/agents/coding.md opencode/agents/ops.md opencode/agents/planner.md
    opencode/plugins/status-sidebar/index.ts opencode/plugins/status-sidebar/rpc.ts opencode/plugins/status-sidebar/tui.tsx
    opencode/config.json opencode/agents/plan-designer.md opencode/agents/simplicity-reviewer.md
    opencode/commands/init.md opencode/skills/agent-browser/SKILL.md
    opencode/skills/responsive-design/SKILL.md opencode/skills/responsive-design/references/details.md
    opencode/skills/accessibility-compliance/SKILL.md opencode/skills/accessibility-compliance/references/details.md
    opencode/skills/api-design-principles/SKILL.md opencode/skills/api-design-principles/references/details.md
    opencode/skills/postgresql-table-design/SKILL.md opencode/skills/postgresql-table-design/references/details.md
    opencode/skills/ops-workflows/SKILL.md opencode/skills/ops-workflows/references/memory.md
    opencode/skills/ops-workflows/references/workspace-git.md opencode/skills/ops-workflows/references/long-tasks.md
    opencode/skills/ops-hosts/SKILL.md opencode/skills/THIRD_PARTY_NOTICES.md
    opencode/skills/LICENSES/wshobson-agents-MIT.txt kitty/kitty.conf)
selected=(); missing=(); retained=()
selected_count=0; missing_count=0; retained_count=0
for file in "${files[@]}"; do
    if ! safe_path "$current/$file" || ! safe_path "$config/$file"; then
        retained+=("$file（路径含链接）"); retained_count=$((retained_count + 1)); continue
    fi
    if [[ -f $current/$file && -f $config/$file ]] && cmp -s "$current/$file" "$config/$file"; then
        selected+=("$file")
        selected_count=$((selected_count + 1))
    elif [[ -f $current/$file && ! -e $config/$file ]]; then
        missing+=("$file")
        missing_count=$((missing_count + 1))
    elif [[ -e $config/$file || -e $current/$file ]]; then
        retained+=("$file（无可靠基线、非普通文件或已修改）")
        retained_count=$((retained_count + 1))
    fi
done
units=$config/systemd/user; label=io.github.chancelyg.dotbox-update
plist=$HOME/Library/LaunchAgents/$label.plist
schedulers=(); scheduler_count=0
expected_service() {
    printf '# Managed by dotbox install.sh\n[Unit]\nDescription=Update dotbox OpenCode configuration\n[Service]\nType=oneshot\n'
    printf 'Environment=%s\n' "$(unit_quote "XDG_CONFIG_HOME=$config")" "$(unit_quote "XDG_STATE_HOME=$state_home")"
    printf 'ExecStart=:/bin/bash %s update %s\nTimeoutStartSec=5min\n' "$(unit_quote "$current/runner.sh")" "$(unit_quote "$repo")"
}
expected_timer() {
    printf '# Managed by dotbox install.sh\n[Unit]\nDescription=Update dotbox configuration every 6 hours\n[Timer]\nOnStartupSec=5min\nOnUnitInactiveSec=6h\n[Install]\nWantedBy=timers.target\n'
}
expected_plist() {
    printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' '<!-- Managed by dotbox install.sh -->' '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">' '<plist version="1.0">' '<dict>'
    printf '  <key>Label</key>\n  <string>%s</string>\n' "$label"
    printf '  <key>ProgramArguments</key>\n  <array>\n    <string>/bin/bash</string>\n    <string>%s</string>\n    <string>update</string>\n    <string>%s</string>\n  </array>\n' "$(xml_escape "$current/runner.sh")" "$(xml_escape "$repo")"
    printf '  <key>EnvironmentVariables</key>\n  <dict>\n    <key>XDG_CONFIG_HOME</key>\n    <string>%s</string>\n    <key>XDG_STATE_HOME</key>\n    <string>%s</string>\n  </dict>\n' "$(xml_escape "$config")" "$(xml_escape "$state_home")"
    printf '%s\n' '  <key>RunAtLoad</key>' '  <true/>' '  <key>StartInterval</key>' '  <integer>21600</integer>' '  <key>ProcessType</key>' '  <string>Background</string>' '</dict>' '</plist>'
}
if [[ $platform == Linux ]]; then
    for suffix in service timer; do
        path=$units/dotbox-update.$suffix
        safe_path "$path" || die '调度路径含链接'
        if [[ -e $path ]]; then
            [[ -f $path && $(cat "$path") == "$("expected_$suffix")" ]] || die '调度文件与已知安装格式不符，需人工核验'
            schedulers+=("$path")
            scheduler_count=$((scheduler_count + 1))
        fi
    done
else
    safe_path "$plist" || die '调度路径含链接'
    if [[ -e $plist ]]; then
        [[ -f $plist && $(cat "$plist") == "$(expected_plist)" ]] || die 'LaunchAgent 与已知安装格式不符，需人工核验'
        schedulers+=("$plist")
        scheduler_count=$((scheduler_count + 1))
    fi
fi
printf '可归档配置：%s；缺失：%s；保留：%s；调度文件：%s\n' "$selected_count" "$missing_count" "$retained_count" "$scheduler_count"
# Bash 3.2 的 nounset 不支持直接展开空数组。
for file in ${selected[@]+"${selected[@]}"}; do printf '  归档 %s\n' "$file"; done
for file in ${retained[@]+"${retained[@]}"}; do printf '  保留 %s\n' "$file"; done
for path in ${schedulers[@]+"${schedulers[@]}"}; do printf '  停用并归档 %s\n' "$path"; done
(( apply )) || { printf '仅预览；执行请使用 --apply，并在终端确认。\n'; exit 0; }
[[ -t 0 ]] || die '执行必须在交互终端确认，管道输入不作为批准'
printf '确认停用上述旧调度并归档？临时目录可能被系统清理。[y/N] '
read -r answer || die '未确认'
[[ $answer == y || $answer == Y ]] || { printf '已取消。\n'; exit 0; }
lock=$state/update.lock
safe_path "$lock" && safe_path "$state/lock" || die '锁路径含链接'
if [[ $platform == Linux ]]; then
    command -v flock >/dev/null || die '缺少 flock，无法与旧更新器互斥'
    exec 9>"$state/lock"
    flock -n 9 || die '旧更新器正在运行，未卸载'
fi
mkdir "$lock" 2>/dev/null || die '旧更新锁存在，未抢占；请核实运行或遗留状态'
archive=; moving=0; moved_count=0; moved_sources=(); moved_destinations=()
finish() {
    local code=$? i
    trap - EXIT INT TERM
    if (( moving )); then
        printf '归档未完成，尝试恢复本次已移动文件；不会重启旧调度。\n' >&2
        for ((i=moved_count-1; i>=0; i--)); do
            if ! safe_path "${moved_sources[$i]}" || ! safe_path "${moved_destinations[$i]}"; then
                printf '恢复路径已含链接，保留归档：%s\n' "${moved_destinations[$i]}" >&2
            elif [[ -e ${moved_sources[$i]} || -L ${moved_sources[$i]} ]]; then
                printf '恢复目标已占用，保留归档：%s\n' "${moved_destinations[$i]}" >&2
            elif ! mv -- "${moved_destinations[$i]}" "${moved_sources[$i]}"; then
                printf '恢复失败：%s\n' "${moved_destinations[$i]}" >&2
            fi
        done
    fi
    rm -f -- "$lock/owner"
    rmdir -- "$lock" || printf '锁未能释放：%s\n' "$lock" >&2
    [[ -z $archive ]] || printf '归档及恢复说明：%s\n' "$archive"
    exit "$code"
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
printf '%s\n' "$$" >"$lock/owner"
# 持锁后复核已批准的文件，不扩大预览范围。
for file in ${selected[@]+"${selected[@]}"}; do
    safe_path "$config/$file" && safe_path "$current/$file" && [[ -f $config/$file && -f $current/$file ]] && cmp -s "$config/$file" "$current/$file" || die "批准后内容变化：$file"
done
for path in ${schedulers[@]+"${schedulers[@]}"}; do
    safe_path "$path" && [[ -f $path ]] || die '调度文件在批准后变化'
    if [[ $platform == Linux ]]; then
        [[ $(cat "$path") == "$("expected_${path##*.}")" ]] || die '调度内容在批准后变化'
    else
        [[ $(cat "$path") == "$(expected_plist)" ]] || die '调度内容在批准后变化'
    fi
done
tmpbase=${TMPDIR:-}
if [[ -z $tmpbase ]]; then
    if [[ -d /tmp/opencode ]]; then tmpbase=/tmp/opencode; else tmpbase=/tmp; fi
fi
# macOS /tmp 可为系统链接，仅规范化临时根；归档仍须与源码和配置隔离。
tmpbase=$(cd -P -- "$tmpbase" && pwd)
safe_path "$tmpbase" || die '临时根不安全'
for path in "$repo" "$config" "$state"; do
    [[ $tmpbase != "$path" && $tmpbase != "$path/"* ]] || die '归档不能放入源码、配置或状态目录'
done
archive=$(mktemp -d "$tmpbase/dotbox-uninstall.XXXXXXXX")
mkdir "$archive/metadata"
for meta in config repository revision opencode-bin runner.sh; do
    safe_path "$current/$meta" || die '元数据含链接'
    [[ ! -e $current/$meta || -f $current/$meta ]] || die '元数据不是普通文件'
    [[ ! -f $current/$meta ]] || cp -p -- "$current/$meta" "$archive/metadata/$meta"
done
{
    printf '# 旧版卸载归档\n\n配置根：%s\n状态根：%s\n平台：%s\n\n' "$config" "$state" "$platform"
    printf '%s\n' '临时目录可能被系统清理；需长期保存请自行移至安全位置。'
    printf '%s\n' 'config/ 保留配置相对路径；原路径见 manifest.tsv；metadata/ 为安装记录副本。'
    printf '%s\n' '恢复前逐项核对目标未被后来修改，再复制对应归档文件到 manifest.tsv 原路径。'
    printf '%s\n' '调度不会自动恢复；重新启用前必须审阅旧 runner，避免意外自动更新。'
    printf '%s\n' 'state/current 和未知旧备份保留原处；没有卸载 OpenCode 程序。'
    for file in ${missing[@]+"${missing[@]}"}; do printf '原本缺失：%s\n' "$file"; done
    for file in ${retained[@]+"${retained[@]}"}; do printf '保留：%s\n' "$file"; done
} >"$archive/README.md"
: >"$archive/manifest.tsv"
manager=0
if [[ $platform == Linux ]]; then
    if command -v systemctl >/dev/null && systemctl --user show-environment >/dev/null 2>&1; then manager=1; fi
    if (( manager )); then
        for suffix in service timer; do
            fragment=$(systemctl --user show "dotbox-update.$suffix" -p FragmentPath --value) || die '不能核实加载的调度路径'
            [[ -z $fragment || $fragment == "$units/dotbox-update.$suffix" ]] || die '加载了其他来源的同名调度'
            [[ -z $fragment || -f $fragment ]] || die '有已加载但文件缺失的调度，需人工核验'
            [[ -z $fragment || $scheduler_count -gt 0 ]] || die '预览后出现已加载调度，需重新预览'
            dropins=$(systemctl --user show "dotbox-update.$suffix" -p DropInPaths --value) || die '不能核实调度覆盖项'
            [[ -z $dropins ]] || die '调度存在个人覆盖项，未接管'
        done
        active=$(systemctl --user show dotbox-update.service -p ActiveState --value) || die '不能核实更新器状态'
        case "$active" in inactive|failed|'') ;; *) die '更新服务仍在运行，未强制停止' ;; esac
        printf 'service=%s\n' "$active" >>"$archive/scheduler-state.txt"
    fi
    if (( scheduler_count )); then
        (( manager )) || die '用户 systemd 不可用，无法确认旧调度停止'
        systemctl --user show dotbox-update.timer -p ActiveState -p UnitFileState >>"$archive/scheduler-state.txt"
        [[ ! -f $units/dotbox-update.timer ]] || systemctl --user disable --now dotbox-update.timer
        active=$(systemctl --user show dotbox-update.timer -p ActiveState --value)
        enabled=$(systemctl --user show dotbox-update.timer -p UnitFileState --value)
        [[ $active == inactive || $active == failed || -z $active ]] || die 'timer 未停止'
        [[ $enabled != enabled && $enabled != enabled-runtime ]] || die 'timer 仍启用'
        active=$(systemctl --user show dotbox-update.service -p ActiveState --value)
        case "$active" in inactive|failed|'') ;; *) die '停用 timer 后更新服务仍在运行，未搬动配置' ;; esac
    fi
else
    domain=gui/$(id -u)
    if (( scheduler_count == 0 )) && command -v launchctl >/dev/null && launchctl print "$domain/$label" >/dev/null 2>&1; then
        die '存在无对应受管 plist 的已加载任务，需人工核验'
    fi
    if (( scheduler_count )); then
        launchctl print "$domain" >/dev/null 2>&1 || die '用户 launchd 不可用，无法确认旧调度停止'
        if loaded=$(launchctl print "$domain/$label" 2>/dev/null); then
            # 核实运行中对象，而不是仅凭磁盘上的同名 plist 认领任务。
            loaded_path=$(printf '%s\n' "$loaded" | sed -n 's/^[[:space:]]*path = //p')
            loaded_program=$(printf '%s\n' "$loaded" | sed -n 's/^[[:space:]]*program = //p')
            loaded_args=$(printf '%s\n' "$loaded" | awk '/^[[:space:]]*arguments = \{/ {inside=1; next} inside && /^[[:space:]]*\}/ {exit} inside {sub(/^[[:space:]]*/, ""); print}')
            expected_args=$(printf '/bin/bash\n%s\nupdate\n%s' "$current/runner.sh" "$repo")
            [[ $loaded_path == "$plist" && $loaded_program == /bin/bash && $loaded_args == "$expected_args" ]] || die '已加载 LaunchAgent 的来源或参数不符，未停用'
            if printf '%s\n' "$loaded" | grep -Eq '^[[:space:]]*(pid = [1-9]|state = running)'; then
                die '旧更新任务仍在运行，未强制停止'
            fi
            printf 'loaded\n' >"$archive/scheduler-state.txt"
            launchctl bootout "$domain/$label"
            if launchctl print "$domain/$label" >/dev/null 2>&1; then die 'LaunchAgent 仍在加载'; fi
        else
            printf 'not-loaded\n' >"$archive/scheduler-state.txt"
        fi
    fi
fi
archive_file() {
    local source=$1 relative=$2 destination=$archive/$2
    mkdir -p -- "$(dirname -- "$destination")"
    printf '%s\t%s\n' "$source" "$relative" >>"$archive/manifest.tsv"
    mv -- "$source" "$destination"
    moved_sources+=("$source"); moved_destinations+=("$destination")
    moved_count=$((moved_count + 1))
}
moving=1
for file in ${selected[@]+"${selected[@]}"}; do
    mkdir -p -- "$(dirname -- "$archive/baseline/$file")"
    cp -p -- "$current/$file" "$archive/baseline/$file"
    archive_file "$config/$file" "config/$file"
done
for path in ${schedulers[@]+"${schedulers[@]}"}; do archive_file "$path" "scheduler/${path##*/}"; done
if [[ $platform == Linux ]] && (( scheduler_count )); then systemctl --user daemon-reload; fi
moving=0
printf '已归档 %s 个配置和 %s 个调度文件；保留 %s 项，不自动删除归档。\n' "$selected_count" "$scheduler_count" "$retained_count"
(( retained_count == 0 )) || printf '存在保留项：旧全局行为可能仍生效，请按清单人工处理。\n'
