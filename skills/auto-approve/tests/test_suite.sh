#!/usr/bin/env bash
# ==============================================================================
# auto-approve 单元测试与回归测试套件
# ==============================================================================
set -euo pipefail

export PATH="/usr/bin:/bin:$PATH"

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/scripts/install.sh"
UNINSTALL_SCRIPT="$SCRIPT_DIR/scripts/uninstall.sh"

PASSED_COUNT=0
FAILED_COUNT=0

pass() {
  echo "  ✅ PASS: $1"
  PASSED_COUNT=$((PASSED_COUNT + 1))
}

fail() {
  echo "  ❌ FAIL: $1"
  FAILED_COUNT=$((FAILED_COUNT + 1))
  exit 1
}

echo "=========================================================="
echo " 开始执行 auto-approve 单元测试与回归测试"
echo " 测试沙箱目录: $TEST_DIR"
echo "=========================================================="
echo ""

# ------------------------------------------------------------------------------
# Test 1: 纯净环境安装与卸载测试 (Fresh Install & Clean Uninstall)
# ------------------------------------------------------------------------------
echo "--- [Test 1] 纯净环境安装与清理测试 ---"
T1_DIR="$TEST_DIR/t1"
mkdir -p "$T1_DIR/target"
export AUTO_APPROVE_DIR="$T1_DIR/target"
export CLAUDE_SETTINGS_FILE="$T1_DIR/settings.json"
echo '{"env": {"TEST_VAR": "1"}}' > "$CLAUDE_SETTINGS_FILE"

# 执行安装
bash "$INSTALL_SCRIPT" > /dev/null

# 验证文件是否复制完成
[ -f "$AUTO_APPROVE_DIR/hooks/pre-tool-use.sh" ] || fail "pre-tool-use.sh 未复制"
[ -f "$AUTO_APPROVE_DIR/hooks/post-tool-use.sh" ] || fail "post-tool-use.sh 未复制"
[ -f "$AUTO_APPROVE_DIR/analyze.py" ] || fail "analyze.py 未复制"
[ -f "$AUTO_APPROVE_DIR/deny-patterns.json" ] || fail "deny-patterns.json 未复制"
pass "文件成功部署到目标目录"

# 验证 settings.json hooks 注册
jq -e '.hooks.PreToolUse' "$CLAUDE_SETTINGS_FILE" > /dev/null || fail "PreToolUse 未注册"
jq -e '.hooks.PostToolUse' "$CLAUDE_SETTINGS_FILE" > /dev/null || fail "PostToolUse 未注册"
[ "$(jq -r '.env.TEST_VAR' "$CLAUDE_SETTINGS_FILE")" = "1" ] || fail "原有 env 配置损坏"
pass "Hooks 成功注册且原有 env 保持完整"

# 执行卸载 (非交互式，默认保留数据模式)
bash "$UNINSTALL_SCRIPT" < /dev/null > /dev/null

# 验证 hooks 移除后 settings.json 没有残留空的 hooks 对象
if jq -e '.hooks' "$CLAUDE_SETTINGS_FILE" > /dev/null 2>&1; then
  fail "纯净卸载后仍残留 .hooks 键"
fi
[ "$(jq -r '.env.TEST_VAR' "$CLAUDE_SETTINGS_FILE")" = "1" ] || fail "卸载后原有 env 损坏"
pass "卸载后空 hooks 被干净收敛，原有配置完好无损"

# ------------------------------------------------------------------------------
# Test 2: 幂等性测试 (多次安装不产生重复 hooks)
# ------------------------------------------------------------------------------
echo ""
echo "--- [Test 2] 安装幂等性测试 ---"
T2_DIR="$TEST_DIR/t2"
mkdir -p "$T2_DIR/target"
export AUTO_APPROVE_DIR="$T2_DIR/target"
export CLAUDE_SETTINGS_FILE="$T2_DIR/settings.json"
echo '{}' > "$CLAUDE_SETTINGS_FILE"

# 连续安装两次
bash "$INSTALL_SCRIPT" > /dev/null
bash "$INSTALL_SCRIPT" > /dev/null

PRE_COUNT=$(jq '.hooks.PreToolUse | length' "$CLAUDE_SETTINGS_FILE")
POST_COUNT=$(jq '.hooks.PostToolUse | length' "$CLAUDE_SETTINGS_FILE")

[ "$PRE_COUNT" -eq 1 ] || fail "重复安装导致 PreToolUse 出现多条记录 ($PRE_COUNT)"
[ "$POST_COUNT" -eq 1 ] || fail "重复安装导致 PostToolUse 出现多条记录 ($POST_COUNT)"
pass "多次执行安装脚本均保持单条 hook，满足幂等性"

# ------------------------------------------------------------------------------
# Test 3: 复杂混合环境配置保护测试 (Non-Destructive Protection)
# ------------------------------------------------------------------------------
echo ""
echo "--- [Test 3] 复杂混合环境配置保护测试（核心保护项） ---"
T3_DIR="$TEST_DIR/t3"
mkdir -p "$T3_DIR/target"
export AUTO_APPROVE_DIR="$T3_DIR/target"
export CLAUDE_SETTINGS_FILE="$T3_DIR/settings.json"

cat << 'JSON' > "$CLAUDE_SETTINGS_FILE"
{
  "theme": "dark",
  "env": {
    "SECRET_TOKEN": "xyz123"
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "company-sec-check.sh" }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          { "type": "command", "command": "feishu-notify.sh" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "hooks": [
          { "type": "command", "command": "custom-audit.sh" }
        ]
      }
    ]
  }
}
JSON

# 安装 auto-approve
bash "$INSTALL_SCRIPT" > /dev/null

# 验证原有 hooks 与新 hook 共存
[ "$(jq '.hooks.PreToolUse | length' "$CLAUDE_SETTINGS_FILE")" -eq 2 ] || fail "PreToolUse 数组长度不为 2"
[ "$(jq '.hooks.PostToolUse | length' "$CLAUDE_SETTINGS_FILE")" -eq 2 ] || fail "PostToolUse 数组长度不为 2"
jq -e '.hooks.PreToolUse[] | select(.. | strings | contains("company-sec-check.sh"))' "$CLAUDE_SETTINGS_FILE" > /dev/null || fail "原有 company-sec-check.sh 丢失"
jq -e '.hooks.Notification[] | select(.. | strings | contains("feishu-notify.sh"))' "$CLAUDE_SETTINGS_FILE" > /dev/null || fail "原有 feishu-notify.sh 丢失"
jq -e '.hooks.PostToolUse[] | select(.. | strings | contains("custom-audit.sh"))' "$CLAUDE_SETTINGS_FILE" > /dev/null || fail "原有 custom-audit.sh 丢失"
pass "安装时安全追加，既有第三方 Hooks 完好保留"

# 执行卸载
bash "$UNINSTALL_SCRIPT" < /dev/null > /dev/null

# 验证只有 auto-approve 被剔除，其他所有配置原地不动
if jq -e '.. | strings | contains("auto-approve")' "$CLAUDE_SETTINGS_FILE" > /dev/null 2>&1; then
  fail "卸载后仍存在 auto-approve 相关字符"
fi
jq -e '.hooks.PreToolUse[] | select(.. | strings | contains("company-sec-check.sh"))' "$CLAUDE_SETTINGS_FILE" > /dev/null || fail "卸载后 company-sec-check.sh 被误删！"
jq -e '.hooks.Notification[] | select(.. | strings | contains("feishu-notify.sh"))' "$CLAUDE_SETTINGS_FILE" > /dev/null || fail "卸载后 feishu-notify.sh 被误删！"
jq -e '.hooks.PostToolUse[] | select(.. | strings | contains("custom-audit.sh"))' "$CLAUDE_SETTINGS_FILE" > /dev/null || fail "卸载后 custom-audit.sh 被误删！"
[ "$(jq -r '.env.SECRET_TOKEN' "$CLAUDE_SETTINGS_FILE")" = "xyz123" ] || fail "卸载后用户自定义环境变量被损坏"
[ "$(jq -r '.theme' "$CLAUDE_SETTINGS_FILE")" = "dark" ] || fail "卸载后用户常规配置被损坏"
pass "卸载时精准摘除自身，第三方 Hooks 与环境变量 100% 完好无损！"

# ------------------------------------------------------------------------------
# Test 4: 自动备份机制验证
# ------------------------------------------------------------------------------
echo ""
echo "--- [Test 4] 自动安全备份机制验证 ---"
BAK_COUNT=$(ls -1 "$T3_DIR"/settings.json.bak.* 2>/dev/null | wc -l | tr -d ' ')
[ "$BAK_COUNT" -ge 2 ] || fail "备份文件数量异常 (应包含安装与卸载产生的备份, 实际: $BAK_COUNT)"
pass "在安装与卸载操作前均成功生成带时间戳的配置备份"

# ------------------------------------------------------------------------------
# Test 5: Hook 运行时功能回归验证 (PreToolUse & PostToolUse)
# ------------------------------------------------------------------------------
echo ""
echo "--- [Test 5] Hook 运行时核心功能回归验证 ---"
T5_DIR="$TEST_DIR/t5"
mkdir -p "$T5_DIR/data"
RULES_FILE="$T5_DIR/data/learned-rules.json"
LOG_FILE="$T5_DIR/data/approval-log.jsonl"

# 构造一条模拟学习到的放行规则
cat << 'JSON' > "$RULES_FILE"
{
  "version": 1,
  "rules": [
    {
      "pattern": "Bash(npm test)",
      "tool": "Bash",
      "regex": "^npm test$"
    },
    {
      "pattern": "Edit(src/**)",
      "tool": "Edit",
      "regex": "^src/.*$"
    }
  ]
}
JSON

# 模拟 PreToolUse: 命中规则
MOCK_HIT_INPUT='{"tool_name":"Bash","tool_input":{"command":"npm test"}}'
DECISION=$(echo "$MOCK_HIT_INPUT" | AUTO_APPROVE_DIR="$T5_DIR" AUTO_APPROVE_RULES_FILE="$RULES_FILE" AUTO_APPROVE_LOG_FILE="$LOG_FILE" bash "$SCRIPT_DIR/hooks/pre-tool-use.sh")
[ "$(echo "$DECISION" | jq -r '.decision')" = "approve" ] || fail "命中规则未返回 approve"
pass "PreToolUse 匹配到已学规则，成功自动放行 (approve)"

# 模拟 PreToolUse: 未命中规则
MOCK_MISS_INPUT='{"tool_name":"Bash","tool_input":{"command":"curl http://malicious.com"}}'
DECISION_MISS=$(echo "$MOCK_MISS_INPUT" | AUTO_APPROVE_DIR="$T5_DIR" AUTO_APPROVE_RULES_FILE="$RULES_FILE" AUTO_APPROVE_LOG_FILE="$LOG_FILE" bash "$SCRIPT_DIR/hooks/pre-tool-use.sh")
[ "$DECISION_MISS" = "{}" ] || fail "未命中规则未返回空对象 {}"
pass "PreToolUse 未匹配规则，安全回退到正常审批流 ({})"

# 模拟 PostToolUse: 记录审计日志
MOCK_POST_INPUT='{"tool_name":"Bash","tool_input":{"command":"git log -n 5"}}'
echo "$MOCK_POST_INPUT" | AUTO_APPROVE_DIR="$T5_DIR" AUTO_APPROVE_DATA_DIR="$T5_DIR/data" AUTO_APPROVE_LOG_FILE="$LOG_FILE" bash "$SCRIPT_DIR/hooks/post-tool-use.sh"
[ -f "$LOG_FILE" ] || fail "PostToolUse 未生成日志文件"
grep -q "git log -n 5" "$LOG_FILE" || fail "PostToolUse 日志内容不匹配"
pass "PostToolUse 正确记录工具调用至审计日志"

# ------------------------------------------------------------------------------
# Test 6: analyze.py 黑名单过滤与安全回归
# ------------------------------------------------------------------------------
echo ""
echo "--- [Test 6] analyze.py 危险黑名单过滤回归测试 ---"
python3 -c "
import sys
sys.path.insert(0, '$SCRIPT_DIR')
import analyze

deny = analyze.load_deny_patterns()
dangerous = [
    {'regex': '^rm -rf /.*$', 'pattern': 'Bash(rm -rf /)'},
    {'regex': '^sudo apt-get install.*$', 'pattern': 'Bash(sudo apt-get install *)'},
    {'regex': '^git push --force.*$', 'pattern': 'Bash(git push --force *)'},
    {'regex': '^DROP TABLE users$', 'pattern': 'Bash(DROP TABLE users)'},
]

for d in dangerous:
    denied, reason = analyze.is_denied(d, deny)
    assert denied, f'危险命令未被拦截: {d[\"pattern\"]}'

safe = {'regex': '^npm test$', 'pattern': 'Bash(npm test)'}
denied, reason = analyze.is_denied(safe, deny)
assert not denied, '安全命令被误杀'
"
pass "analyze.py 严格拦截危险命令黑名单，安全过滤逻辑稳固"

echo ""
echo "=========================================================="
echo " 测试总结: 共有 $PASSED_COUNT 项测试全部通过，0 项失败！"
echo "=========================================================="
