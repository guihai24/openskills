# Step 1 — 启动会诊

> 目标：解析素材，给出"AI 初印象"（受众/核心矛盾/痛点），让用户纠偏，敲定 slug。
> **失败要点**：素材太短 / 质量低 → 立即终止，不允许脑补内容凑数。

## 0. 读规范

每次都重新读这两个文件，不要凭记忆：
1. `/root/xhs-shop/memory/CURATOR_STYLE.md` — 全文
2. `/root/xhs-shop/memory/AUDIENCE_PROFILES.md` — 查已沉淀的 profile

## 1. 解析输入

输入有 3 种来源：
- **YouTube URL**（含 `youtube.com/watch`、`youtu.be/`、`/embed/`、`/shorts/`）→ 调 `scripts/fetch-youtube-transcript.py`
- **文章 / 博客 URL**（Medium / 知乎 / SubStack / 公众号等）→ 调 smart-fetch（走 Jina 路径）
- **粘贴文本**：直接用
- **混合**：URL + 粘贴文本（用户补充）

### 1.1 YouTube URL 抓取（2026-05-13 新增，三源 fallback 链）

```bash
# Load API keys from .env (if present)
set -a
source /root/xhs-shop/.env 2>/dev/null
set +a

python3 /root/xhs-shop/scripts/fetch-youtube-transcript.py "<youtube_url>" \
  > /root/xhs-shop/products/<slug>/source/raw.md
```

**抓取顺序**（首个成功即用）：
1. SearchAPI.io（`SEARCHAPI_API_KEY` env）— 主源
2. Supadata.ai（`SUPADATA_API_KEY` env）— 备源
3. youtube-transcript-api 直连 — 云 IP 通常被 YouTube 封

配置见 `/root/xhs-shop/docs/notes/youtube-fetcher-setup.md`。

**失败处理**：
- exit 1（所有源失败 / 视频无字幕）→ stderr 会给手动 fallback 指引（https://youtubetotranscript.com），让用户复制后保存到 raw.md，**不要**自动重试不同 URL
- exit 2（URL 格式错）→ 让用户确认 URL
- exit 3（脚本/环境故障）→ 看具体 error message

**记录抓取来源**：把 stdout 顶部的 `<!-- source: xxx -->` 注释 + meta.json `transcript_source` 字段都记下（用于配额追踪）。

### 1.2 文章 URL 抓取

调 smart-fetch（Claude Code skill），把抓到的 markdown 存到 `products/<slug>/source/raw.md`。

### 1.3 粘贴文本

直接保存到 `products/<slug>/source/raw.md`。

### 1.4 素材质量检查

- 字数 < 1500 → 触发警示
- 营销话术密度过高（无具体案例、无数据、无步骤） → 触发警示
- 触发警示后 STOP，不进入 Step 2。让用户决定换素材或补料。

## 2. 模式识别（strict / fast）

用户在启动语里说了"快速通道"、"fast"或类似词 → `mode = "fast"`。
否则 `mode = "strict"`。

## 3. AI 初印象（必产出）

读完素材后**必须**显式写出以下 4 项（不是空洞概括，要具体）：

```
📌 AI 初印象
─────────────────────
受众画像（具体到场景/人群，不是"职场人"这种泛词）:
   例: "刚拿下韩国签证、第一次去韩国自由行、有做攻略习惯的 J 人"
核心矛盾（这内容在试图解决什么问题）:
   例: "想自己玩好但小红书攻略碎片化、软广多，缺一个系统抄作业的来源"
痛点（受众此刻最焦虑的事）:
   例: "怕踩坑（景点、餐厅、酒店选错）+ 时间不够做攻略"
切入角度（如何让这份产品与同类产品差异化）:
   例: "按 J 人出行节奏（4-5 天）做模块化攻略，每模块带可复制清单"
```

## 3.5 AI 自挑刺（2026-05-13 新增 — 必产出）

读完素材 + 给完初印象后，AI **必须主动列出 3 个"我最可能读偏的角度"**，给自己挑刺：

```
🪞 AI 自挑刺（防止零纠偏陷阱）
─────────────────────
可能偏 1（受众层面）: "我假设受众是 X，但其实可能是 Y"
   例: "我假设是 J 人攻略派，但她也可能是 I 人临时起意派——需要更轻量的指南"
可能偏 2（痛点层面）: "我抓的核心痛点是 X，但其实可能是 Z"
   例: "我抓'怕踩坑'，但更深层可能是'怕被同伴觉得没准备好'"
可能偏 3（切入角度层面）: "我建议的切入角度是 X，但其实可能 Y 更好"
   例: "我建议'模块化攻略'，但'反矫情吐槽'风格在小红书更易爆"
```

教训：youtube-xhs-curation 跑产时 AI 命中率 100%、用户零纠偏——但这不是 AI 真的对了，而是用户没被"被动确认"模式逼出真实意见。强制 AI 先给自己挑刺，用户至少能在挑刺基础上找方向。

## 4. 与用户确认

明确问："这份初印象 + 3 个自挑刺，是否符合你的预期？纠偏哪一项？或者你看到的偏离是别的？"

**记录用户回应**到 meta.json：

```json
{
  "ai_first_impression": {
    "audience": "<v0 原文>",
    "core_conflict": "...",
    "pain_points": [...],
    "angle": "..."
  },
  "ai_self_critique": [
    "<可能偏 1 原文>",
    "<可能偏 2 原文>",
    "<可能偏 3 原文>"
  ],
  "audience_correction_log": [
    { "field": "audience", "from": "...", "to": "...", "reason": "..." }
  ],
  "audience": "<final 用户敲定版本>",
  "audience_corrected_by_user": true | false
}
```

`audience_corrected_by_user = true` **当且仅当** `audience_correction_log` 非空。仅"用户回了一个嗯"不算纠偏。Step 8 会把这套字段沉淀到 `memory/AUDIENCE_PROFILES.md`。

## 5. 敲定 slug

3-5 个英文词，kebab-case，≤30 字符。

冲突检查：
```bash
ls /root/xhs-shop/products/ 2>/dev/null | grep -F "<slug>"
# 如果已存在，让用户改 slug
```

## 6. 创建产品目录 + 初始化 meta.json

```bash
SLUG="<slug>"
mkdir -p /root/xhs-shop/products/$SLUG/source
```

写入初始 `meta.json`（schema 见 spec §6）：
- `slug`, `audience`, `audience_ai_first_impression`, `audience_corrected_by_user`
- `source_type`, `source_refs`
- `mode`, `status="curating"`, `step_progress={"current_step":1,"completed_steps":[1]}`
- `created_at`

把原始素材写入 `products/<slug>/source/raw.md`（如果是 URL，把抓取的 markdown 保存）。

## 7. 确认门 ✅

请用户确认："slug=`<slug>`，受众 + 切入角度已锁定。可进入 Step 2 构建蓝图吗？"

得到确认后，将 `meta.json.step_progress.completed_steps` 加入 1，`current_step=2`。
