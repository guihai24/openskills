# 给 Codex 的 AGENTS.md 约定片段

Codex 没有 Claude Code 的 skill 系统，但能读文件、跑 bash、用 git。把下面这段加进项目根目录的
`AGENTS.md`（或你的 Codex 配置），Codex 就能和 Claude Code 共用同一套交接协议、同一个 `HANDOFF.md`。

把 `<skill-dir>` 替换成本 skill 的实际路径（如 `~/.claude/skills/handoff`）。

```markdown
## 工作交接协议

本项目可能在 Claude Code / Codex 等不同 agent 间轮换。切换时遵守以下交接协议：

**交接出去时**（用户说"交接 / 准备换 agent / 整理进度"）：
1. 跑 `bash <skill-dir>/scripts/handoff.sh` 采集客观状态，对账后再写总结。
2. 按该脚本同目录 `references/HANDOFF_TEMPLATE.md` 的结构，把进度写进项目根目录 `HANDOFF.md`，
   "进行中/下一步"要具体到文件和验证标准。
3. 把改动整理成原子 commit，**列方案给用户确认后再提交**，不要自动提交。
   `*.local.*`、`.env*`、密钥证书等敏感文件绝不进 commit。
4. 自检工作区是否干净，如实报告测试状态。

**接手时**（用户说"接手 / 继续上一个 agent 的活"）：
1. 跑 `bash <skill-dir>/scripts/pickup.sh` 读交接单并与 git 真实状态对账。
2. 发现交接单与仓库不一致（该干净却 DIRTY、hash 找不到等），先向用户指出。
3. 复述理解和下一步，确认后再动手。
```
