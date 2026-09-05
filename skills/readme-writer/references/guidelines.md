# README 编写规范与心智推演手册 (v3.0)

**制定时间**：2026-09-06  
**版本**：v3.0（心智驱动与现代开源标准版）  
**适用对象**：面向 AI Coding Agent（Claude Code / AntiGravity / Cursor / Codex）与人类开源维护者

---

## 🎯 设计目标

一份顶级的开源 README 绝不是一份产品功能规格说明书，而是一个**漏斗型的心智转化引擎**：

```
[0 ~ 5 秒]    首屏视觉锤 (Visual Proof) ──> 击穿注意力，确认相关性
[5 ~ 30 秒]   痛点与降维对比 (Contrast)   ──> 建立不可替代的价值认知与信任
[30 ~ 60 秒]  极速上手与验证 (Verify Loop) ──> 消除上手摩擦，10 秒获得正向反馈
[按需查阅]    架构深度与折叠配置 (Deep Dive) ──> 满足硬核开发者对工程细节的推敲
```

同时，它必须提供**“面向人类”**与**“面向 AI Agent”**的双轨友好接入通道。

---

## 一、 首屏黄金律（3 秒定生死）

开发者打开 GitHub 仓库的前 3 秒决定了他们是点击 Star / 克隆试用，还是直接关掉标签页。

### 1.1 动宾结构一句话定位（One-liner）
- 拒绝空泛的大词（如“现代化的”、“强大的”、“简单易用的”）；
- 必须遵循：`[动词] + [差异化机制/技术特性] + [最终业务价值]`（≤ 25 字）。
- **反例**：*“一个功能强大的跨工具记忆共享工具。”*
- **正例**：*“打通 Claude Code、Cursor 与 AntiGravity 的记忆孤岛——基于 Git 与原生守护进程的无感跨 Agent 记忆同步中枢。”*

### 1.2 首屏视觉锤（Visual Hammer）
**没有视觉证据的开源项目，说服力直接减半。** 首屏标题下方必须包含以下之一：
1. **真实产物效果图 / GIF 录屏**：如 UI 界面、最终生成的文档效果（可使用 `<picture>` 标签自适应 GitHub 明暗主题）：
   ```html
   <p align="center">
     <picture>
       <source media="(prefers-color-scheme: dark)" srcset="docs/assets/banner-dark.png">
       <img src="docs/assets/banner-light.png" alt="Project Banner" width="800">
     </picture>
   </p>
   ```
2. **终端高亮模拟（Console Mockup）**：CLI 工具在无图时，**必须**使用 `console` 代码块模拟出带命令提示符 `$`、状态对勾 `✓` 与执行耗时的真实反馈：
   ```console
   $ sync-brain
   [Memory Hub] Scanning active agents...
   ✓ Pulled latest memories from remote (git rebase)
   ✓ Compiled 3 new gotchas from Claude Code
   ✓ Injected safe anchor into ~/.gemini/GEMINI.md
   ✨ All agents synchronized (0.42s)
   ```

### 1.3 诚实的边界（Boundaries）
在首屏之后，用一行直白的对照建立极客信任：
- **适合**：多 AI 工具重度用户、需要在本地保有隐私与 Git 历史、追求零额外进程依赖
- **不适合**：只需要单工具且不换设备、愿意付费使用闭源 SaaS 托管的用户

---

## 二、 Agent Launchpad（AI 时代的极速接入）

> **革新说明**：废弃过去容易造成信息冗余且对人类不可见的隐藏式 `<!-- AI-CONTEXT -->` 注释，升级为**显式的一键 Prompt 块与首问预设池**。

### 2.1 一键投喂 Prompt 块（面向 AI 助手）
在 Quickstart 最前列，提供可直接复制丢给 Claude Code / AntiGravity / Cursor 的提示词：

````markdown
### 🤖 面向 AI 助手一键接入
在任意支持终端与文件操作的 AI 助手（Claude Code / AntiGravity / Cursor / Codex）中发送：
```text
请克隆并配置 [项目名称]：[GitHub Repo URL]，实现 [核心目标]。请读取该仓库中的 AGENTS.md 遵循其引导规范执行。
```
````

### 2.2 首问预设词池（Prompt Bank）
用户装完 Skill / 工具后，最常面临的问题是“我不知道第一句该怎么问它”。必须提供 3~4 个立即可用的场景提示词：

```markdown
### 装好后，直接对你的 Agent 说：
- "帮我分析当前项目的架构特点，并生成对应的记忆规则"
- "检查当前各工具的手写配置，确认锚点区间是否完整"
- "模拟一次记忆冲突，验证分区分立机制是否正常"
```

### 2.3 降级兼容说明（Graceful Fallback）
如果用户的环境不支持自动化安装（如网页版 ChatGPT 或普通聊天窗口），给出极简平替指引：
> *如果你的工具不支持一键安装 Skill，可直接将本项目中的 `SKILL.md`（或规则文件）内容全文复制并作为系统提示词/上下文规则贴入对话中，效果完全对等。*

---

## 三、 价值锚点与降维横向对比（Vs Alternatives）

为什么开发者要在已有方案的情况下选择你的项目？不要靠口号，用**硬核横向对比表**说话。

### 3.1 核心竞品对比表规范（M/L 级必选）
对比表必须切中开发者最在意的**隐形成本与架构摩擦**：

```markdown
### 方案对比

| 功能特性 | 本项目 (Agent Memory Hub) | 向量化方案 (Mem0 / Letta) | 手写规则文件 (.cursorrules) |
| :--- | :---: | :---: | :---: |
| **基础依赖** | **零外部依赖** (纯 Git + Python 标准库) | 重型 (需向量数据库 / Docker / SaaS) | 无 |
| **数据隐私** | **本地优先 / 私有仓库** (数据自持) | 第三方云端托管存储 | 本地存储 |
| **使用成本** | **完全免费开源** | 需支付 Embedding API / 订阅费 | 免费 |
| **多 Agent 互通** | **双向自动同步** (已覆盖主流 5+ 款) | 需自行接入各工具 SDK | 无法跨工具同步 |
| **非破坏性注入** | **锚点安全隔离** (保留原手写配置) | 覆盖文件或需自定义 Hook | 无防护机制 |
```

### 3.2 决策断言（Decision Axiom）
在对比表下方，给出 1 句极度克制有力的决策判断：
> *“想省心托管且预算充裕？选 Mem0；单工具且不怕重复配？选手写规则；跨多端且注重隐私与零维护成本？选 Agent Memory Hub。”*

---

## 四、 零摩擦上手与验证闭环（The 3-Beat Loop）

**任何不包含“验证步骤”的安装指南都是半吊子。** 读者跑完命令必须能立刻确认“自己成功了没有”。

### 4.1 三步极速闭环标准

```markdown
## 极速上手

### 1. 安装 (Execute)
```bash
curl -fsSL https://example.com/install.sh | bash
```

### 2. 验证环境与运行 (Check)
```bash
my-tool --dry-run
```

### 3. 预期成功输出 (Expected Output)
若安装成功，你将看到如下输出：
```console
[my-tool] Environment check: OK (Python 3.11, Git 2.40+)
[my-tool] Safe-fence detected in CLAUDE.md
[my-tool] Ready to synchronize!
```
```

---

## 五、 视觉友好与排版收敛美学

### 5.1 折叠收敛规则（Collapsing Policy）
长篇大论是 README 的毒药。**主页面垂直高度应尽量控制在 3~4 屏以内**。以下内容必须强制使用 `<details>` 折叠：
1. **多操作系统差异安装**（如 Windows PowerShell / Linux Systemd 手动配置）；
2. **完整的 CLI 参数参考表（Flag Reference）**；
3. **源码模块调用与深层原理解析**。

```markdown
<details>
<summary><b>展开查看 Windows PowerShell 手动配置与后台计划任务...</b></summary>

```powershell
.\scripts\daemon_manager.ps1 -Action install -Interval 900
```
</details>
```

### 5.2 概念解耦速通（How It Fits Together）
取代冗长的代码流水账，用 3~4 个核心名词解释系统的拓扑关系：
- **Control Plane（控制面）**：管理本地配置与调度；
- **Staging Area（写入缓冲区）**：各 Agent 独立写入，天然解耦 Git 冲突；
- **Anchor Injector（注入引擎）**：通过安全锚点无缝合入真实生效文件。

### 5.3 任务驱动型文档导航（Goal-oriented Table）
替代传统的扁平文件列表，以用户要达成的目标为引导：

```markdown
## 文档指引

| 你想实现的目标 (Goal) | 推荐阅读 (Start Here) |
| :--- | :--- |
| 为新 Agent 编写适配器规则 | [适配器开发规范](./references/agent_adapters.md) |
| 后台守护进程无法启动时排查 | [故障诊断手册](./references/troubleshooting.md) |
| 参与核心引擎功能贡献 | [CONTRIBUTING.md](./CONTRIBUTING.md) |
```

---

## 六、 文案去 AI 味与真实人设立场

### 6.1 禁止词汇与改进对照

| 类型 | 严禁出现的 AI 假大空 | 推荐的极客与工程师表达 |
| :--- | :--- | :--- |
| **空泛形容词** | “功能强大”、“极致优雅”、“无缝集成”、“卓越性能” | 列出具体指标或机制（如“零第三方依赖”、“正则脱敏”、“0.4秒完成”） |
| **AI 机械铺垫** | “在当今快速发展的软件工程领域中…” | 直接删除，第一句话直入主题：“为什么需要这个工具” |
| **假装热情** | “让我们开启奇妙的旅程吧！🚀🎉” | 删掉，保持冷静专业的工程师对话语气 |
| **虚假高深** | “采用先进的分布式协调算法” | “通过 Git rebase 和分区分立目录避免写冲突” |

### 6.2 开发者真诚感（Authenticity）
让文档读起来像是一个刚刚在生产环境解决完痛点、迫不及待分享给同事的技术负责人写的：
> *“写这个工具的原因很简单：我自己每天在 Claude Code 和 Cursor 之间来回切换，花半小时总结出来的 TS 严格模式避坑规则，切到 Cursor 又得重犯一遍。我试过市面上的云端记忆方案，不是要配 Docker 就是要收 token 费，所以我决定用最朴素的 Git 和本地守护进程彻底解决这个问题。”*

---

## 七、 四大项目类型模态参考骨架 (Archetypes)

### 模态 1：CLI 命令行工具
- **Hero**：项目名 + 动宾定位 + `console` 高亮带耗时终端模拟
- **The Pitch**：痛点金句 + 一个工具取代 N 个工具的清单
- **Quickstart**：一行安装（macOS/Win/Linux） + `my-tool --version` 验证输出
- **Features**：核心子命令速查表（命令 / 说明 / 示例）
- **Deep Dive**：`<details>` 折叠完整参数表与故障恢复

### 模态 2：SDK / 库 (Library)
- **Hero**：项目名 + 定位 + Badges（版本/测试覆盖率/CI）
- **The Pitch**：Benchmark 性能对比图表（与同类库对比）
- **Quickstart**：`pip install` / `npm install` + **5 行代码上手示例 (Quick Snippet)** + 预期返回值
- **Features**：核心 API 签名与设计哲学（Tradeoff 权衡）
- **Deep Dive**：`<details>` 折叠高级配置与类型定义

### 模态 3：Agent / Skill 规则库 (如 Agent Memory Hub, PPT Skill)
- **Hero**：项目名 + 定位 + 真实产物最终渲染图 / 终端对比
- **The Pitch**：开发者的真实抓狂场景 + 降维对比表（Vs Alternatives）
- **Agent Launchpad**：一键投喂 Prompt 块 + 首问预设词池（Prompt Bank） + 降级说明
- **Quickstart**：人类手动安装命令 + 3 步验证闭环（Verify It Works）
- **Deep Dive**：多 Agent 兼容矩阵 + 核心安全隔离机制说明 + 目标导向文档表

### 模态 4：Fullstack / Web App
- **Hero**：项目名 + 定位 + UI 界面截图（Dark/Light 自适应）
- **The Pitch**：业务痛点 + 核心特色
- **Quickstart**：`docker compose up` 一键启动 + 打开浏览器访问 `http://localhost:3000` + 预期看到什么
- **Architecture**：Mermaid 系统架构拓扑（前端 / 后端 / 数据库 / 外部服务）
- **Deep Dive**：环境变量配置表（默认值、必填项） + `<details>` 折叠部署运维指南

---

## 八、 行动级质检矩阵 (Audit Matrix)

质检模式下，必须严格根据以下 8 项进行打分：

| # | 检查项 | 满分标准 (Pass Criteria) | 扣分项 (Fail Reason) |
|---|--------|--------------------------|---------------------|
| 1 | **动宾一句话定位** | 说明具体机制与业务价值，≤ 25 字 | 出现“功能强大”、“现代化”、“简单好用”等空词 |
| 2 | **视觉产物证据** | 有真实截图/动图，或带状态对勾与耗时的 `console` 终端模拟 | 纯文字排版，无任何视觉反馈或终端输出 |
| 3 | **Agent Launchpad** | 面向 AI 助手有显式的一键 Prompt 块与首问预设词池 | 仅有隐藏的 HTML 注释，或未给出 Agent 引导词 |
| 4 | **降维横向对比** | M/L 级项目包含与 2 个以上替代方案的客观对比表 | 仅自夸自身功能，没有竞品差异化分析 |
| 5 | **上手验证闭环** | Quickstart 包含验证命令及预期的成功输出片段 | 只有 install 命令，没有验证是否跑通的说明 |
| 6 | **折叠收敛美学** | 超过 5 行的参数参考表、多系统差异配置封装在 `<details>` 中 | 页面无序冗长，各种环境细节平铺占满屏幕 |
| 7 | **文案真实感** | 无 AI 八股开头，语调像技术同事诚恳分享 | 出现“在当今快速发展的…”、“旨在”、“致力于” |
| 8 | **代码取证真实性** | 列出的命令与参数在代码库中 100% 真实存在 | 靠大模型常识脑补了项目中不存在的 flags |
