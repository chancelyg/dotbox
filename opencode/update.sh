#!/usr/bin/env bash
# 用户先更新本地克隆，再同步全局标准文件；不自动 git pull。
set -euo pipefail
[[ $# == 0 ]] || { echo '用法：bash update.sh' >&2; exit 1; }
repo=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
exec bash "$repo/setup.sh" --update
