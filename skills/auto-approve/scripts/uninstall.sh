#!/usr/bin/env bash
# auto-approve skill 卸载脚本
# 用法: bash uninstall.sh

set -euo pipefail

TARGET_DIR="${AUTO_APPROVE_DIR:-$HOME/.claude/auto-approve}"
SETTINGS_FILE="${CLAUDE_SETTINGS_FILE:-$HOME/.claude/settings.json}"

echo "=== auto-approve 卸载 ==="
echo ""

# 检查依赖 (优先可用 jq)
if /usr/bin/jq --version &>/dev/null; then
  JQ="/usr/bin/jq"
elif command -v jq &>/dev/null; then
  JQ="jq"
else
  JQ=""
fi

# 精准移除 hooks 注册（保留用户原有其他 hooks 与配置）
if [ -f "$SETTINGS_FILE" ] && [ -n "$JQ" ]; then
  if $JQ -e '.hooks' "$SETTINGS_FILE" &>/dev/null; then
    # 自动备份配置
    BACKUP_FILE="${SETTINGS_FILE}.bak.$(date +%Y%m%d%H%M%S)_$$"
    cp "$SETTINGS_FILE" "$BACKUP_FILE"
    echo "已备份原配置至 $BACKUP_FILE"

    TMP=$(mktemp)
    $JQ '
      if .hooks then
        if .hooks.PreToolUse then
          .hooks.PreToolUse = [
            .hooks.PreToolUse[] |
            select([.. | strings] | any(contains("hooks/pre-tool-use.sh")) | not)
          ] |
          if (.hooks.PreToolUse | length) == 0 then del(.hooks.PreToolUse) else . end
        else . end |
        if .hooks.PostToolUse then
          .hooks.PostToolUse = [
            .hooks.PostToolUse[] |
            select([.. | strings] | any(contains("hooks/post-tool-use.sh")) | not)
          ] |
          if (.hooks.PostToolUse | length) == 0 then del(.hooks.PostToolUse) else . end
        else . end |
        if (.hooks | length) == 0 then del(.hooks) else . end
      else . end
    ' "$SETTINGS_FILE" > "$TMP" && mv "$TMP" "$SETTINGS_FILE"
    echo "已从 $SETTINGS_FILE 精准移除 auto-approve hooks（其余配置与 hooks 均完整保留）"
  fi
fi

# 询问是否保留数据（支持非交互式默认保留）
echo ""
keep_data="y"
if [ -t 0 ]; then
  read -rp "是否保留审计日志和已学习规则？[Y/n] " input_ans || input_ans="y"
  if [ -n "$input_ans" ]; then
    keep_data="$input_ans"
  fi
fi

if [[ "$keep_data" =~ ^[Nn] ]]; then
  rm -rf "$TARGET_DIR"
  echo "已删除 $TARGET_DIR（含所有数据）"
else
  rm -f "$TARGET_DIR/hooks/pre-tool-use.sh"
  rm -f "$TARGET_DIR/hooks/post-tool-use.sh"
  rm -f "$TARGET_DIR/analyze.py"
  rm -f "$TARGET_DIR/deny-patterns.json"
  rmdir "$TARGET_DIR/hooks" 2>/dev/null || true
  echo "已删除脚本，保留 $TARGET_DIR/data/"
fi

echo ""
echo "卸载完成。请重启 Claude Code。"
