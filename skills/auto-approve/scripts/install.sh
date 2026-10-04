#!/usr/bin/env bash
# auto-approve skill 安装脚本
# 用法: bash install.sh

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="${AUTO_APPROVE_DIR:-$HOME/.claude/auto-approve}"
SETTINGS_FILE="${CLAUDE_SETTINGS_FILE:-$HOME/.claude/settings.json}"

echo "=== auto-approve 安装 ==="
echo ""

# 检查依赖 (优先可用 jq)
if /usr/bin/jq --version &>/dev/null; then
  JQ="/usr/bin/jq"
elif command -v jq &>/dev/null; then
  JQ="jq"
else
  echo "错误: 需要 jq。请先安装: brew install jq"
  exit 1
fi

if ! command -v python3 &>/dev/null; then
  echo "错误: 需要 python3。"
  exit 1
fi

# 创建目录
mkdir -p "$TARGET_DIR/hooks" "$TARGET_DIR/data"

# 复制文件
cp "$SKILL_DIR/hooks/post-tool-use.sh" "$TARGET_DIR/hooks/"
cp "$SKILL_DIR/hooks/pre-tool-use.sh" "$TARGET_DIR/hooks/"
cp "$SKILL_DIR/analyze.py" "$TARGET_DIR/"
cp "$SKILL_DIR/deny-patterns.json" "$TARGET_DIR/"

chmod +x "$TARGET_DIR/hooks/post-tool-use.sh"
chmod +x "$TARGET_DIR/hooks/pre-tool-use.sh"
chmod +x "$TARGET_DIR/analyze.py"

echo "文件已复制到 $TARGET_DIR"

# 注册 hooks 到 settings.json
if [ ! -f "$SETTINGS_FILE" ]; then
  mkdir -p "$(dirname "$SETTINGS_FILE")"
  echo '{}' > "$SETTINGS_FILE"
fi

# 自动备份配置
BACKUP_FILE="${SETTINGS_FILE}.bak.$(date +%Y%m%d%H%M%S)_$$"
cp "$SETTINGS_FILE" "$BACKUP_FILE"
echo "已备份原配置至 $BACKUP_FILE"

# 幂等且非破坏性注册 hooks（保留用户原有其他 hooks 与配置）
PRE_HOOK="{\"hooks\":[{\"type\":\"command\",\"command\":\"bash $TARGET_DIR/hooks/pre-tool-use.sh\",\"timeout\":5000}]}"
POST_HOOK="{\"hooks\":[{\"type\":\"command\",\"command\":\"bash $TARGET_DIR/hooks/post-tool-use.sh\",\"timeout\":5000}]}"

TMP=$(mktemp)
$JQ \
  --argjson pre "$PRE_HOOK" \
  --argjson post "$POST_HOOK" '
  .hooks = (.hooks // {}) |
  .hooks.PreToolUse = (.hooks.PreToolUse // []) |
  (if (.hooks.PreToolUse | any([.. | strings] | any(contains("hooks/pre-tool-use.sh")))) then . else .hooks.PreToolUse += [$pre] end) |
  .hooks.PostToolUse = (.hooks.PostToolUse // []) |
  (if (.hooks.PostToolUse | any([.. | strings] | any(contains("hooks/post-tool-use.sh")))) then . else .hooks.PostToolUse += [$post] end)
' "$SETTINGS_FILE" > "$TMP" && mv "$TMP" "$SETTINGS_FILE"

echo "已安全注册 hooks 到 $SETTINGS_FILE"

echo ""
echo "安装完成！请重启 Claude Code 使 hooks 生效。"
echo "使用方法: 在 Claude Code 中输入 /auto-approve 触发分析"
