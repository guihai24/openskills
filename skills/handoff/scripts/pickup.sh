#!/usr/bin/env bash
# pickup.sh — 接手时把交接单与真实仓库状态摆在一起，便于对账。
#
# 设计原则：只读。交接单是"上一棒说的话"，git 是"真相"。
# 接手方必须先核对两者是否一致——防止上一棒没真正交接干净就喊了交接。

set -euo pipefail

HANDOFF_FILE="${1:-HANDOFF.md}"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "ERROR: 当前目录不在 git 仓库内。" >&2
  exit 1
fi

if [ ! -f "$HANDOFF_FILE" ]; then
  echo "NO_HANDOFF: 未找到 $HANDOFF_FILE。可能没有待接手的交接单，或文件名不同。" >&2
  exit 2
fi

echo "=== 交接单：$HANDOFF_FILE ==="
cat "$HANDOFF_FILE"

echo
echo "=== 对账：当前工作区状态 ==="
if [ -z "$(git status --porcelain)" ]; then
  echo "CLEAN: 工作区干净（与'已交接、留干净工作区'的预期一致）。"
else
  echo "DIRTY: 工作区有未提交改动 —— 请与交接单核对这是否在预期内。"
  git status --short
fi

echo
echo "=== 对账：最近 8 条 commit（核对交接单提到的 hash 是否都在）==="
git log -8 --oneline || true
