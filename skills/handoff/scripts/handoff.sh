#!/usr/bin/env bash
# handoff.sh — 采集交接所需的客观工作区快照。
#
# 设计原则：本脚本只读，绝不改动仓库（不 add / 不 commit / 不跑测试）。
# 它的职责是把"客观事实"摆出来，让上层（agent + 用户）基于事实决策。
# 自动 commit 的风险太高（半成品、敏感文件），所以提交动作交给流程，
# 由 agent 提议、用户确认后再执行。

set -euo pipefail

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "ERROR: 当前目录不在 git 仓库内，无法交接。" >&2
  exit 1
fi

echo "=== 分支 ==="
git branch --show-current || echo "(detached HEAD)"

echo
echo "=== 工作区状态 ==="
if [ -z "$(git status --porcelain)" ]; then
  echo "CLEAN: 工作区干净，无未提交改动。"
else
  echo "DIRTY: 存在未提交改动。"
  git status --short
fi

echo
echo "=== 改动统计（未暂存 / 已暂存）==="
git diff --stat || true
git diff --cached --stat || true

echo
echo "=== 最近 8 条 commit ==="
git log -8 --oneline || true

echo
echo "=== ⚠️ 疑似敏感/不应提交的文件 ==="
# 通用模式，不绑定任何具体项目：本地配置、环境变量、密钥、证书。
# 命中的文件应在交接单里显式标注"不提交"，避免凭证混进交接 commit。
sensitive="$(git status --porcelain | awk '{print $NF}' \
  | grep -Ei '(\.local\.|(^|/)\.env($|\.)|secret|credential|\.pem$|\.key$|\.p12$|id_rsa)' || true)"
if [ -n "$sensitive" ]; then
  echo "$sensitive"
else
  echo "(无)"
fi

echo
echo "=== 探测到的测试命令 ==="
# 仅探测、不执行。是否真的跑测试由流程决定（开源通用 skill 不能假设测试无副作用）。
detected=""
if [ -f package.json ] && grep -q '"test"' package.json; then
  detected="npm test"
elif [ -f Makefile ] && grep -qE '^test:' Makefile; then
  detected="make test"
elif [ -f pyproject.toml ] || [ -f pytest.ini ] || [ -f setup.cfg ]; then
  detected="pytest"
elif [ -f Cargo.toml ]; then
  detected="cargo test"
elif [ -f go.mod ]; then
  detected="go test ./..."
fi
if [ -n "$detected" ]; then
  echo "$detected"
else
  echo "UNKNOWN: 未能自动识别测试命令，请在交接单里标注测试状态为'未知/需人工'。"
fi
