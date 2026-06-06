#!/usr/bin/env bash
# context-monitor 卸载脚本
# 用法: bash uninstall.sh
#   可选: CLAUDE_HOME=/path/to/.claude bash uninstall.sh   (与 install 对应)

set -euo pipefail

CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"
INSTALL_DIR="$CLAUDE_DIR/context-monitor"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

echo "=== context-monitor 卸载 ==="

# 只移除本 skill 写入的 statusLine —— 校验 command 指向本脚本才删, 不误伤用户其它 statusLine
if [ -f "$SETTINGS_FILE" ] && command -v jq >/dev/null 2>&1; then
  if jq -e '.statusLine.command | test("statusline-context.py")' "$SETTINGS_FILE" >/dev/null 2>&1; then
    BACKUP="$SETTINGS_FILE.bak.$(date +%Y%m%d%H%M%S)"
    cp "$SETTINGS_FILE" "$BACKUP"
    TMP=$(mktemp)
    jq 'del(.statusLine)' "$SETTINGS_FILE" > "$TMP" && mv "$TMP" "$SETTINGS_FILE"
    echo "✓ 已移除 statusLine (备份: $BACKUP)"
  else
    echo "• settings.json 的 statusLine 不是 context-monitor 写的(或不存在), 跳过, 不误伤。"
  fi
fi

# 删除安装的脚本目录
if [ -d "$INSTALL_DIR" ]; then
  rm -rf "$INSTALL_DIR"
  echo "✓ 已删除 $INSTALL_DIR"
fi

echo ""
echo "卸载完成。下次状态栏刷新即恢复。"
