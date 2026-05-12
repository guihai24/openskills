# Step 1 — 启动会诊

> 目标：解析素材，给出"AI 初印象"（受众/核心矛盾/痛点），让用户纠偏，敲定 slug。
> **失败要点**：素材太短 / 质量低 → 立即终止，不允许脑补内容凑数。

## 0. 读规范

每次都重新读这两个文件，不要凭记忆：
1. `/root/xhs-shop/memory/CURATOR_STYLE.md` — 全文
2. `/root/xhs-shop/memory/AUDIENCE_PROFILES.md` — 查已沉淀的 profile

## 1. 解析输入

输入有 3 种来源：
- **URL（YouTube/文章）**：调用 smart-fetch / web-access 抓取
- **粘贴文本**：直接用
- **混合**：URL + 粘贴文本（用户补充）

**抓取失败处理**：单次失败立即报错+给"手动粘文本"指引，不重试。

**素材质量检查**：
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

## 4. 与用户确认

明确问："这份初印象是否符合你的预期？需要纠偏哪一项？"

**记录用户纠偏**：把"AI 初印象" vs "用户纠偏后" 的差异写入 `meta.json.audience_ai_first_impression` 和 `meta.json.audience`，并在 Step 8 沉淀到 `memory/AUDIENCE_PROFILES.md`。

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
