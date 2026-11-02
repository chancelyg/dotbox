#!/usr/bin/env bash
# 保留旧入口用于说明退役；不转调脚本，不修改文件或联网。
printf '%s\n' 'install.sh 已退役。' \
    '旧安装：运行 bash uninstall.sh 预览，bash uninstall.sh --apply 确认归档。' \
    '新入口：运行 bash setup.sh 注册 /onboard，参阅 opencode/README.md。' \
    '旧定时任务执行独立 runner 副本；本提示不代表它已停止。' >&2
exit 1
