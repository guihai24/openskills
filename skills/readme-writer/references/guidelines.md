# README 编写规范与心智推演手册 (v3.2)

**制定时间**：2026-09-06  
**版本**：v3.2（开源全景八大模态与 SVG 矢量排版标准版）  
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

## 🧭 开源全景八大模态专属骨架 (The 8 Archetypes)

### 模态 1：CLI 命令行工具 (CLI Tools)
- **判定指纹**：`package.json` 含 `bin`；`Cargo.toml` 有 `[[bin]]`；使用 `clap`/`click`/`argparse`。
- **专属结构**：
  1. **首屏**：纯净标题 + 动宾定位 + 统一规格 Badges + **`console` 真实终端执行高亮模拟（带耗时与状态）**；
  2. **The Pitch**：痛点故事 + 一个工具取代 N 个工具的清单 + 核心竞品对比表；
  3. **Quickstart**：一行安装（macOS/Win/Linux） + `my-tool --version` 验证输出片段；
  4. **Features**：常用子命令表格（命令 / 功能说明 / 示例）；
  5. **Deep Dive**：`<details>` 折叠完整参数字典（Flag Reference）与管道协作高级示例。

### 模态 2：SDK 与基础代码库 (Libraries & SDKs)
- **判定指纹**：导出纯函数或类（`exports` / `lib.rs`）；无前端 UI 依赖；测试集中在输入输出。
- **专属结构**：
  1. **首屏**：项目名 + 动宾定位 + Badges（npm版本/构建状态/覆盖率/Python版本）；
  2. **The Pitch**：Benchmark 吞吐量与内存开销对比图表；
  3. **Quickstart**：`npm install` / `pip install` + **严格 3~5 行开箱即用代码块（Quick Snippet）** + 预期打印结果；
  4. **Core Concepts**：核心类/方法的输入输出类型定义；
  5. **Deep Dive**：`<details>` 折叠完整 API 签名表格与生命周期钩子说明。

### 模态 3：Web UI 组件库与设计系统 (UI Components & Design Systems)
- **判定指纹**：包含 `components/ui/`、`tailwind.config`、依赖 `react`/`vue`/`radix`，或有 `storybook`。
- **专属结构**：
  1. **首屏**：项目名 + 动宾定位 + **Live Playground 在线交互预览直达按钮** + 组件视觉 Showcase 矩阵图；
  2. **The Pitch**：为什么用它（相比于其他组件库的体积优势、无依赖度、定制自由度）；
  3. **Quickstart**：原子化添加命令（如 `npx my-ui add dialog`）或包安装；
  4. **Component Showcase**：常用基础组件（Button, Dialog, Sheet, Form）的代码调用片段；
  5. **Design Tokens**：Tailwind 变量配置、暗黑模式切换支持、无障碍 (A11y/WCAG) 声明。

### 模态 4：后台守护服务与基础设施 (Infra & Backend Daemons)
- **判定指纹**：有 `docker-compose.yml`、`Dockerfile`、监听网络端口、有 `.env.example`。
- **专属结构**：
  1. **首屏**：项目名 + 动宾定位 + 架构拓扑简图；
  2. **The Pitch**：高并发场景下的资源占用与稳定性指标；
  3. **Quickstart**：`docker compose up -d` 一键拉起 + `curl http://localhost:8080/health` 验证探针输出；
  4. **Environment Variables**：**环境变量配置字典表**（变量名 / 类型 / 默认值 / 是否必填）；
  5. **Deep Dive**：系统服务守护配置（systemd / launchd）与数据持久化挂载卷说明。

### 模态 5：完整 Web / 桌面应用 (Fullstack & Desktop Apps)
- **判定指纹**：包含前端页面路由（Pages/App）+ 后端 API，有数据库迁移脚本。
- **专属结构**：
  1. **首屏**：项目名 + 动宾定位 + **全景产品 UI 截图/GIF 录屏（明暗主题自适应）**；
  2. **The Pitch**：业务痛点与核心功能看板（Card Layout）；
  3. **One-Click Deploy**：**一键云端部署徽章**（Deploy to Vercel / Railway / Docker）；
  4. **Local Development**：`pnpm install` -> `pnpm dev` -> 数据库迁移初始化步骤；
  5. **Deep Dive**：账号权限体系、三方 OAuth 配置指引。

### 模态 6：宿主扩展与插件 (Extensions & Plugins)
- **判定指纹**：存在 `manifest.json`（浏览器扩展）；`package.json` 含 `contributes`（IDE 插件）；`raycast` 元数据。
- **专属结构**：
  1. **首屏**：项目名 + 动宾定位 + **官方应用市场一键安装徽章**（Chrome Web Store / VS Code Marketplace / Raycast Store）；
  2. **The Pitch**：工作流提效痛点动图对比（Before vs After）；
  3. **Keybindings**：**快捷键绑定表**（默认快捷键 / 作用 / 自定义修改指引）；
  4. **Permissions Transparency**：**权限透明度声明**（向用户详细解释申请各项权限的原因）；
  5. **Local Debugging**：开发者“加载已解压的扩展程序”本地调试步骤。

### 模态 7：AI Agent 资产与规则中枢 (AI Agents, Skills & MCP)
- **判定指纹**：根目录或子目录存在 `SKILL.md`、`mcp.json`、`AGENTS.md`、`CLAUDE.md` 等。
- **专属结构**：
  1. **首屏**：项目名 + 动宾定位 + 终端执行状态模拟或最终产物截图；
  2. **The Pitch**：开发者的真实抓狂场景 + 核心方案降维对比表；
  3. **Agent Launchpad**：**显式一键 Prompt 块** + **首问预设词池（Prompt Bank）**；
  4. **Quickstart**：人类向导安装 + 3 步验证闭环（Verify It Works）；
  5. **Deep Dive**：多 Agent 兼容矩阵 + 安全脱敏声明 + 目标导向文档表。

### 模态 8：知识库、学习教程与精选清单 (Knowledge Bases, Courses & Awesome-Lists)
- **判定指纹**：仓库全为 `.md` / `.pdf` / 静态图片，无代码构建脚本与包管理配置。
- **专属结构**：
  1. **首屏**：知识库/课程名称 + 定位标语 + 涵盖模块统计；
  2. **Learning Paths**：**按基础分级选路（30 秒自测）**：
     - *零基础入门*：推荐先读哪几章；
     - *实战进阶*：直接从哪一节开始；
     - *资深架构师*：核心设计参考目录；
  3. **Curriculum Matrix**：全景知识架构看板表格（章节 / 核心知识点 / 预估用时 / 练习材料）；
  4. **Inclusion Criteria**：收录与评选标准（为什么收录这些内容，如何保证质量）；
  5. **Contribution Guide**：如何提交新资源、纠错 PR 规范与免责声明。
  *(注：本模态自动豁免代码安装与运行闭环要求)*

---

## 三、 首屏黄金律（3 秒定生死）

### 1. 动宾结构一句话定位
必须遵循：`[动词] + [差异化机制/技术特性] + [最终业务价值]`（≤ 25 字）。
- **反例**：*“一个功能强大的跨工具记忆共享工具。”*
- **正例**：*“打通 Claude Code、Cursor 与 AntiGravity 的记忆孤岛——基于 Git 与原生守护进程的跨 Agent 自动化同步中枢。”*

### 2. 首屏视觉锤（Visual Hammer）
首屏必须包含视觉证据：
1. **真实产物图 / 界面截图**：使用 `<picture>` 标签自适应明暗模式：
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
     -> Pulled latest memories from remote (git rebase)
     -> Extracted 3 technical gotchas from Claude Code
     -> Injected safe-fence into ~/.gemini/GEMINI.md
   [OK] All agents synchronized successfully (0.38s)
   ```

### 3. 诚实的边界（Boundaries）
用直接客观的对照建立极客信任：
- **适合**：多 AI 工具重度用户、注重本地隐私与 Git 历史、追求零额外后台进程负载。
- **不适合**：仅在单一 IDE 中工作、或愿意付费使用云端闭源 SaaS 向量托管的用户。

---

## 四、 核心方案横向对比（Vs Alternatives）

除纯知识类项目外，中大型项目必须包含客观的竞品降维对比表，切中**隐形成本与架构摩擦**：

```markdown
### 方案横向对比

| 功能特性 | 本项目 (Agent Memory Hub) | 向量化方案 (Mem0 / Letta) | 手写规则文件 (.cursorrules) |
| :--- | :---: | :---: | :---: |
| **基础依赖** | **零外部依赖** (纯 Git + Python 标准库) | 重型 (需向量数据库 / Docker / SaaS) | 无 |
| **数据隐私** | **本地优先 / 私有仓库** (数据自持) | 第三方云端托管存储 | 本地存储 |
| **使用成本** | **完全免费且开源** | 需支付 Embedding API / 订阅费 | 免费 |
| **多 Agent 互通** | **双向自动同步** (已打通 5+ 款主流工具) | 需自行接入各工具 SDK | 无法跨工具同步 |
| **敏感密钥过滤** | **提交前正则自动脱敏** | 需人工识别过滤 | 需人工识别过滤 |
| **非破坏性注入** | **锚点安全隔离** (保留原手写配置) | 覆盖文件或需自定义 Hook | 无机制 |
```

在对比表下方给出 1 句极简有力的决策判断（Decision Axiom）。

---

## 五、 排版收敛与 Bento 卡片美学

### 1. 折叠收敛规则（Collapsing Policy）
主页面垂直高度尽量控制在 3~4 屏以内。以下内容必须强制使用 `<details>` 折叠：
- 多操作系统差异命令（如 Windows PowerShell / Linux Systemd 手动配置）；
- 完整的 CLI 参数参考表（Flag Reference）；
- 环境变量字典与源码模块调用深层原理解析。

```markdown
<details>
<summary><b>展开查看 Windows (PowerShell) 安装与命令行参数直装方式...</b></summary>

```powershell
.\scripts\daemon_manager.ps1 -Action install -Interval 900
```
</details>
```

### 2. 任务驱动型文档导航（Goal-oriented Table）
替代传统的扁平文件列表，以用户要达成的目标为引导：

```markdown
## 文档指引与支持

| 你想实现的目标 (Goal) | 推荐入口 (Start Here) |
| :--- | :--- |
| 为新 Agent 编写适配器规则 | [Agent 适配规范手册](./skills/agent-memory-sync/references/agent_adapters.md) |
| 后台守护进程未运行排查 | [故障排查与诊断手册](./skills/agent-memory-sync/references/troubleshooting.md) |
| 参与核心引擎功能贡献 | [CONTRIBUTING.md](./CONTRIBUTING.md) |
```

---

## 六、 自适应行动级质检矩阵 (Audit Matrix)

| # | 检查项 | 满分标准 (Pass Criteria) | 扣分项 (Fail Reason) |
|---|--------|--------------------------|---------------------|
| 1 | **无 Emoji 纯净标题** | 各级标题严禁出现 Unicode Emoji，如需图标必须使用标准单色 SVG | 标题包含 🚀, ⚡, 🤖, 🏗️ 等装饰符号 |
| 2 | **模态精准适配** | 准确命中 8 大模态之一，并呈现该模态的专属核心展示（如插件带商店徽章、组件带 Playground、教程带学习分流看板） | 用通用的代码模板生硬套在组件库或纯教程上 |
| 3 | **动宾一句话定位** | 说明具体机制与业务价值，≤ 25 字 | 出现“功能强大”、“现代化”、“简单好用”等空词 |
| 4 | **视觉产物证据** | 有真实截图、Live 链接，或带状态对勾与耗时的 `console` 终端模拟 | 纯文字排版，无任何视觉反馈或终端输出 |
| 5 | **Agent Launchpad** | 代码/工具类项目包含可一键复制给 AI 的显式 Prompt 块与首问预设词池 | 仅有隐藏的 HTML 注释，或未给出 Agent 引导词 |
| 6 | **降维横向对比** | 软件类项目包含与替代方案的客观对比表；教程类交代独家差异 | 仅自夸自身功能，无任何竞品与替代方案分析 |
| 7 | **上手与闭环** | 代码类包含“预期成功输出片段”；知识类包含明确的学习分级路径 | 只有安装命令而没有验证闭环；教程缺乏分流 |
| 8 | **折叠收敛美学** | 超过 5 行的参数参考表、多系统差异配置封装在 `<details>` 中 | 页面无序冗长，各种环境细节平铺占满屏幕 |

**判定**：8 项全过为发布标准。
