---
name: context-monitor
version: 1.0.0
description: >
  在 Claude Code 状态栏实时显示 context 使用百分比, 逼近上限时变色预警,
  让你在"中途爆 context"之前主动 /compact。一键安装: 用 jq 增量写 settings.json
  (不覆盖既有配置, 改前自动备份), 并正确处理 /compact 边界(postTokens)、
  跳过 API 出错留下的全 0 合成消息、按 1M/200k 自动判断上下文上限。
  触发场景: 监控 context / 上下文用量、状态栏显示 token、防止上下文超限、
  "context 满了来不及 compact"、配置 status line。即使用户没明说"状态栏",
  只要想"看见"上下文用量、或防止会话中途爆掉, 都应使用本 skill。
  Installs a Claude Code status-line meter that shows live context-window usage
  with color warnings, so you can /compact before overflowing mid-session.
metadata:
  author: github.com/huaguihai
  requires: python3, jq
allowed-tools:
  - Bash
  - Read
---

# context-monitor — Claude Code 上下文用量状态栏

在状态栏实时显示 context 占用，绿/黄/红三档预警，避免会话中途突然爆 context 来不及 /compact。

```
Opus 4.8 ██░░░░░░░░ 18% (180k/1000k)
```

## 为什么需要它

Claude Code 有 autocompact 兜底，但你**看不见** context 逼近的过程——往往是"突然报超限"才发现，这时已经来不及主动 /compact。这个 skill 给状态栏加一个实时计量条，让你在变黄、变红时就主动下手。

## 安装

前置：`python3`、`jq`。

```bash
bash ~/.claude/skills/context-monitor/scripts/install.sh
```

做的事：把脚本复制到 `~/.claude/context-monitor/`、用 `jq` **增量**写入 settings.json 的 `statusLine` 字段（其余配置原样不动，**改前自动备份** `settings.json.bak.<时间戳>`）、最后自检脚本可运行。

安装后**下次状态栏刷新**（发一条消息或重启 Claude Code）即生效。之后改脚本本身无需重启——statusLine 每次刷新都重新执行脚本。

> 装到 OpenClaw 或自定义目录：`CLAUDE_HOME=~/.openclaw bash .../install.sh`（前提是该 harness 支持 statusLine）。

## 显示含义

`<模型名> <进度条> <百分比> (<已用>/<上限>)`，颜色三档：

- 🟢 绿 `<60%` 充裕　🟡 黄 `60–85%` 留意，可准备 /compact　🔴 红 `≥85%` 该 /compact 了

## 工作原理（及三个关键坑）

脚本从 stdin 读取 Claude Code 传入的会话信息（含 `transcript_path`），反向扫描 transcript 取最近一次的 context 占用 = `input_tokens + cache_read_input_tokens + cache_creation_input_tokens`。三个容易踩的坑，脚本都处理了——这也是它存在的价值：

1. **跳过全 0 的合成消息**：API 出错会在 transcript 末尾留下一条 `<synthetic>` 全 0 usage 消息。天真地取"最后一条 usage"会读到 0、误显示 0%。脚本跳过 token 全 0 的消息。

2. **/compact 边界（最隐蔽）**：`/compact` 会追加一条带 `compactMetadata` 的消息，其中 `postTokens` 是压缩后的真实大小——但**这条消息本身没有 usage**。若只取"最后一条 usage"，会穿透到压缩**之前**的旧值，表现为"compact 完了百分比还是不降"。脚本的规则是：反向遍历时，compact 边界（`postTokens`）和真实 usage **谁先遇到用谁**——于是 compact 后的空窗期显示 `postTokens`（已压缩），等你发新消息后自动切换到含工具/系统提示开销的真实值。

3. **1M vs 200k 上限**：Opus 1M context 模型上限 100 万 token，其余 20 万。脚本按 statusLine 传入的 model id 是否含 `1m` 自动判断；可用环境变量 `CLAUDE_CTX_LIMIT` 强制覆盖。

## 自定义

- **上限**：`export CLAUDE_CTX_LIMIT=1000000`，或改脚本 `context_limit()` 的默认值
- **颜色阈值**：改脚本里 `pct >= 85` / `pct >= 60` 两个数
- **进度条长度**：改脚本 `bar_len`

## 文件结构

```
~/.claude/context-monitor/statusline-context.py   # statusLine 调用的脚本
~/.claude/settings.json                            # 增量加了一个 statusLine 字段
~/.claude/settings.json.bak.<时间戳>               # 改动前的自动备份
```

## 卸载

```bash
bash ~/.claude/skills/context-monitor/scripts/uninstall.sh
```

只移除本 skill 写入的 statusLine（会校验 `command` 指向本脚本才删，**不误伤你别的 statusLine**），并删除 `~/.claude/context-monitor/`，改前同样自动备份 settings.json。

## 边界说明

- 仅适用于支持 statusLine 机制的 Claude Code；OpenClaw 等若无 statusLine 则不适用。
- 百分比是"逼近度"参考，不等于 autocompact 的精确触发点。它的作用是让你**看见**并主动决策，而不是替代 autocompact。
