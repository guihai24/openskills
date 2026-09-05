# README 编写规范与心智推演手册 (v3.1)

**制定时间**：2026-09-06  
**版本**：v3.1（现代极简与 SVG 矢量排版标准版）  
**适用对象**：面向 AI Coding Agent（Claude Code / AntiGravity / Cursor / Codex）与人类开源维护者

---

## 🎨 核心美学原则：告别廉价塑料感

### 1. 彻底拔除 Unicode Emoji（Zero Emoji Clutter）
在过去的 AI 生成文本中，大模型极其喜欢在每个标题前加一个花哨的表情符号（如 🚀, ⚡, 🤖, 🏗️, 🗂️, 📖 等）。这种做法会带来极强的“廉价模板感”和“假大空 AI 味”。
- **硬性红线**：禁止在各级标题（`#`、`##`、`###`）前堆砌 Emoji。
- **专业做法**：使用纯文字标题，或在必要时使用**统一风格的单色 SVG 矢量图标**。

### 2. SVG 矢量图标使用规范 (SVG First)
在 GitHub Markdown 环境中，直接内联 `<svg>` 标签会被过滤，但通过 `<img>` 标签引用 SVG 完全原生受支持。

- **本地图标引用（推荐）**：在项目中设立 `docs/assets/icons/` 目录，存放简洁的单色 24x24 矢量图标，通过相对路径引用：
  ```html
  <img src="docs/assets/icons/terminal.svg" width="18" height="18" valign="middle" /> 终端速查
  ```
- **CDN 矢量图标引用**：使用 Lucide 或 SimpleIcons 等免鉴权矢量源：
  ```html
  <img src="https://api.iconify.design/lucide:terminal.svg?color=%230A7CFF" width="18" height="18" valign="middle" />
  ```
- **排版对齐**：图标高度统一限制为 16px ~ 20px，必须添加 `valign="middle"` 或 `align="center"` 确保与中英文字符基线垂直居中。

---

## 一、 首屏黄金律（3 秒定生死）

### 1.1 动宾结构一句话定位
必须遵循：`[动词] + [差异化机制/技术特性] + [最终业务价值]`（≤ 25 字）。
- **反例**：*“一个功能强大的跨工具记忆共享工具。”*
- **正例**：*“打通 Claude Code、Cursor 与 AntiGravity 的记忆孤岛——基于 Git 与原生守护进程的跨 Agent 自动化同步中枢。”*

### 1.2 首屏视觉锤（Visual Hammer）
**没有视觉证据的开源项目，说服力直接减半。** 首屏必须包含以下之一：
1. **产物效果图 / 架构图**（支持 GitHub 暗黑/明亮模式自适应）：
   ```html
   <p align="center">
     <picture>
       <source media="(prefers-color-scheme: dark)" srcset="docs/assets/banner-dark.png">
       <img src="docs/assets/banner-light.png" alt="Banner" width="800">
     </picture>
   </p>
   ```
2. **终端高亮模拟（Console Mockup）**：CLI 工具在无图时，**必须**使用 `console` 代码块模拟带命令提示符 `$`、状态对勾 `✓` 与执行耗时的真实反馈：
   ```console
   $ sync-brain
   [Memory Hub] Scanning active agents...
   ✓ Pulled latest memories from remote (git rebase)
   ✓ Compiled 3 new gotchas from Claude Code
   ✓ Injected safe anchor into ~/.gemini/GEMINI.md
   ✨ All agents synchronized (0.38s)
   ```

### 1.3 诚实的边界（Boundaries）
用直接客观的对照建立极客信任：
- **适合**：多 AI 工具重度用户、需要在本地保有隐私与 Git 历史、追求零额外进程依赖。
- **不适合**：仅在单一 IDE 中工作、或愿意付费使用闭源云端 SaaS 托管的用户。

---

## 二、 Agent Launchpad（AI 时代极速接入）

### 2.1 一键投喂 Prompt 块（面向 AI 助手）
在 Quickstart 最前列，提供可直接复制丢给 Claude Code / AntiGravity / Cursor 的提示词：

````markdown
### 面向 AI 助手一键接入
在任意支持终端与文件操作的 AI 助手（Claude Code / AntiGravity / Cursor / Codex）中发送：
```text
请克隆并配置 [项目名称]：[GitHub Repo URL]，实现 [核心目标]。请读取该仓库中的 AGENTS.md 遵循其引导规范执行。
```
````

### 2.2 首问预设词池（Prompt Bank）
消除用户的“首问迷茫”，提供 3~4 个装好后立即可用的场景指令：
```markdown
### 装好后，直接对你的 Agent 说：
- "帮我分析当前项目的架构特点，并生成对应的记忆规则"
- "检查当前各工具的手写配置，确认 Safe Fence 锚点区间是否完整"
- "模拟一次记忆冲突，验证分区分立写入机制"
```

### 2.3 降级兼容说明
> *若当前对话环境无本地终端执行权限，可直接复制本项目根目录的 `AGENTS.md`（或规则文件）内容贴入对话中作为系统规则使用，效果完全一致。*

---

## 三、 价值锚点与降维横向对比（Vs Alternatives）

### 3.1 核心竞品对比表（M/L 级必选）
对比表必须切中开发者最在意的**隐形成本与架构摩擦**：

```markdown
### 方案对比

| 功能特性 | 本项目 (Agent Memory Hub) | 向量化方案 (Mem0 / Letta) | 手写规则文件 (.cursorrules) |
| :--- | :---: | :---: | :---: |
| **基础依赖** | **零外部依赖** (纯 Git + Python 标准库) | 重型 (需向量数据库 / Docker / SaaS) | 无 |
| **数据隐私** | **本地优先 / 私有仓库** (数据自持) | 第三方云端托管存储 | 本地存储 |
| **使用成本** | **完全免费且开源** | 需支付 Embedding API / 订阅费 | 免费 |
| **多 Agent 互通** | **双向自动同步** (已打通 5+ 款主流工具) | 需自行接入各工具 SDK | 无法跨工具同步 |
| **敏感密钥过滤** | **提交前正则自动脱敏** | 需人工识别过滤 | 需人工识别过滤 |
| **非破坏性注入** | **锚点安全隔离** (保留原手写配置) | 覆盖文件或需自定义 Hook | 无机制 |
```

### 3.2 决策断言（Decision Axiom）
在对比表下方，给出 1 句极度克制有力的决策判断：
> *追求免运维且预算充裕？选 Mem0；仅用单个 IDE？选手写规则；**跨多款 AI 编程工具且注重隐私与零维护成本？选 Agent Memory Hub。***

---

## 四、 零摩擦上手与验证闭环（The 3-Beat Loop）

### 4.1 三步极速闭环标准
任何安装指南必须包含“验证步骤”与“预期成功输出片段”：

```markdown
## 极速上手

### 1. 执行环境预检 (Execute)
```bash
python3 scripts/installer.py --check-only
```

### 2. 预期成功反馈 (Check)
若环境正常，你将看到如下带有就绪状态的输出：
```console
=== Environment Pre-flight Check ===
  os: Darwin (macOS)
  git_installed: True
  python3_installed: True
  github_ssh_authenticated: True
  can_silent_sync: True
```

### 3. 向导安装与即时测试 (Verify)
```bash
./skills/agent-memory-sync/scripts/setup_wizard.sh
sync-brain
```
```

---

## 五、 排版收敛与 Bento 卡片美学

### 5.1 折叠收敛规则（Collapsing Policy）
主页面垂直高度尽量控制在 3~4 屏以内。以下内容必须强制使用 `<details>` 折叠：
1. **多操作系统差异命令**（如 Windows PowerShell / Linux Systemd 手动配置）；
2. **完整的 CLI 参数参考表（Flag Reference）**；
3. **源码模块调用与深层原理解析**。

```markdown
<details>
<summary><b>展开查看 Windows (PowerShell) 安装与命令行参数直装方式...</b></summary>

```powershell
.\scripts\daemon_manager.ps1 -Action install -Interval 900
```
</details>
```

### 5.2 任务驱动型文档导航（Goal-oriented Table）
替代传统的扁平文件列表，以用户要达成的目标为引导：

```markdown
## 文档指引与支持

| 你想实现的目标 (Goal) | 推荐入口 (Start Here) |
| :--- | :--- |
| 为新 Agent 编写适配器规则 | [Agent 适配规范手册](./references/agent_adapters.md) |
| 后台守护进程未运行排查 | [故障排查与诊断手册](./references/troubleshooting.md) |
| 参与核心引擎功能贡献 | [CONTRIBUTING.md](./CONTRIBUTING.md) |
```

---

## 六、 行动级质检矩阵 (Audit Matrix)

| # | 检查项 | 满分标准 (Pass Criteria) | 扣分项 (Fail Reason) |
|---|--------|--------------------------|---------------------|
| 1 | **无 Emoji 纯净标题** | 各级标题严禁出现 Unicode Emoji，如需图标必须使用标准单色 SVG | 标题包含 🚀, ⚡, 🤖, 🏗️ 等装饰符号 |
| 2 | **动宾一句话定位** | 说明具体机制与业务价值，≤ 25 字 | 出现“功能强大”、“现代化”、“简单好用”等空词 |
| 3 | **视觉产物证据** | 有真实截图/动图，或带状态对勾与耗时的 `console` 终端模拟 | 纯文字排版，无任何视觉反馈或终端输出 |
| 4 | **Agent Launchpad** | 面向 AI 助手有显式的一键 Prompt 块与首问预设词池 | 仅有隐藏的 HTML 注释，或未给出 Agent 引导词 |
| 5 | **降维横向对比** | M/L 级项目包含与 2 个以上替代方案的客观对比表 | 仅自夸自身功能，没有竞品差异化分析 |
| 6 | **上手验证闭环** | Quickstart 包含验证命令及预期的成功输出片段 | 只有 install 命令，没有验证是否跑通的说明 |
| 7 | **折叠收敛美学** | 超过 5 行的参数参考表、多系统差异配置封装在 `<details>` 中 | 页面无序冗长，各种环境细节平铺占满屏幕 |
| 8 | **代码取证真实性** | 列出的命令与参数在代码库中 100% 真实存在 | 靠大模型常识脑补了项目中不存在的 flags |
