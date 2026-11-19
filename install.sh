#!/usr/bin/env bash
# 兼容保留的退役入口；不转调脚本，不修改文件或联网。
printf '%s\n' \
    'install.sh 已退役，仅为兼容旧调用方式而保留。' \
    '首次安装：bash setup.sh' \
    '更新受管文件：bash update.sh' \
    '卸载受管文件：bash uninstall.sh' \
    '详细说明：opencode/README.md' >&2
exit 1
