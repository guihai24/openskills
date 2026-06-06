#!/usr/bin/env bash
# context-monitor 安装脚本 —— 在 Claude Code 状态栏显示 context 使用百分比
# 用法: bash install.sh
#   可选: CLAUDE_HOME=/path/to/.claude bash install.sh   (自定义目标目录, 也用于测试)

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"
INSTALL_DIR="$CLAUDE_DIR/context-monitor"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
TARGET_SCRIPT="$INSTALL_DIR/statusline-context.py"

# 写入 settings 的 command: 默认用可移植的 $HOME 字面量(跨机器有效),
# 自定义 CLAUDE_HOME 时用绝对路径。
if [ -n "${CLAUDE_HOME:-}" ]; then
  SCRIPT_REF="$TARGET_SCRIPT"
else
  SCRIPT_REF='$HOME/.claude/context-monitor/statusline-context.py'
fi

echo "=== context-monitor 安装 ==="

# 依赖检查
command -v python3 >/dev/null 2>&1 || { echo "错误: 需要 python3"; exit 1; }
command -v jq      >/dev/null 2>&1 || { echo "错误: 需要 jq (用于增量改 settings.json)。安装: apt install jq 或 brew install jq"; exit 1; }

# 复制脚本
mkdir -p "$INSTALL_DIR"
cp "$SKILL_DIR/scripts/statusline-context.py" "$TARGET_SCRIPT"
chmod +x "$TARGET_SCRIPT"
echo "✓ 脚本已复制到 $TARGET_SCRIPT"

# 准备 settings.json
mkdir -p "$CLAUDE_DIR"
[ -f "$SETTINGS_FILE" ] || echo '{}' > "$SETTINGS_FILE"

# 改前备份 —— 绝不在无备份的情况下动用户配置
BACKUP="$SETTINGS_FILE.bak.$(date +%Y%m%d%H%M%S)"
cp "$SETTINGS_FILE" "$BACKUP"

# 检测已有 statusLine, 避免静默覆盖用户的其它配置
if jq -e '.statusLine' "$SETTINGS_FILE" >/dev/null 2>&1; then
  if jq -e '.statusLine.command | test("statusline-context.py")' "$SETTINGS_FILE" >/dev/null 2>&1; then
    echo "• 检测到已安装的 context-monitor, 更新为当前版本。"
  else
    echo "⚠️  检测到已有的 statusLine 配置:"
    jq -c '.statusLine' "$SETTINGS_FILE" | sed 's/^/      /'
    echo "    已备份到 $BACKUP, 本次仅覆盖 statusLine 字段(其余配置不动)。"
    echo "    如需保留原配置, 安装后从备份恢复 .statusLine 即可。"
  fi
fi

# 增量写入: 只设置 .statusLine 一个字段, 不碰其它任何配置
TMP=$(mktemp)
jq --arg cmd "python3 $SCRIPT_REF" \
   '.statusLine = {"type":"command","command":$cmd,"padding":0}' \
   "$SETTINGS_FILE" > "$TMP" && mv "$TMP" "$SETTINGS_FILE"
echo "✓ 已写入 statusLine 到 $SETTINGS_FILE"

# 自检: 脚本能否正常运行(喂一个最小输入, 应不崩溃)
if echo '{"model":{"id":"test"},"transcript_path":"/nonexistent"}' | python3 "$TARGET_SCRIPT" >/dev/null 2>&1; then
  echo "✓ 脚本自检通过"
else
  echo "✗ 脚本自检失败, 请检查 python3 与脚本"
  exit 1
fi

echo ""
echo "安装完成! 下次状态栏刷新(发一条消息或重启 Claude Code)即生效。"
echo "显示: <模型> <进度条> <百分比> (已用/上限)   绿<60% · 黄60-85% · 红≥85%"
echo "备份: $BACKUP"
echo "卸载: bash \"$SKILL_DIR/scripts/uninstall.sh\""
