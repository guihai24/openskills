# Step 6 — HTML PPT 三层质检

> 目标：内容 diff（机械层）+ AI 味（抽样层）+ 付费视角（最终层）。
> **失败要点**：只做机械 diff 就放过；忽视配图/排版问题。

## 1. 机械层 — 内容 diff

```bash
python3 /root/xhs-shop/scripts/html-diff.py \
  /root/xhs-shop/products/<slug>/deck.html \
  /root/xhs-shop/products/<slug>/curation.md \
  > /root/xhs-shop/products/<slug>/source/diff-report.json
```

读 `diff-report.json`：
- `status: clean` → 通过此层
- `status: minor_drift` → 列出 missing 项给用户决定
- `status: major_drift` → 默认要求回 Step 5 重生成

注意：HTML 经 guizang 改写后必有少量改写（标题精炼、列表点重组），minor_drift 是正常的；major_drift（≥5 短语漂移）才是预警。

## 2. AI 味层 — 抽样 3-5 页

让 Claude 抽样 3-5 张 slide 的文字（从 deck.html 里截取 `<section class="slide">` 的内容），对每页问：

```
🔍 AI 味自检
- 这页看起来像 AI 一键直出吗？
- 有套话密度过高的痕迹吗（"在当今...的背景下""综上所述""可以说"等）？
- 标题是否平庸（"什么是 X"/"X 的重要性"）？
- 如果有，最严重的一页是哪页？
```

发现 AI 味重 → 标记 `quality_check.ai_taste_check = "needs_polish"`，让用户决定回 Step 5 重生成 / 手动改 HTML / 接受。

## 3. 付费视角层

对整份 deck 做一次"买家视角"自问：

```
💰 付费视角自检
- 我是花 9.9 / 39.9 / 69.9 的买家，看完这份 PPT 觉得"花得值"吗？
- 哪几页最值（卖点切片）？
- 哪几页让我觉得"凑数"？
- 同类竞品的 PPT 比这份更好吗？为什么？
```

结果分类：
- ✅ `passed` — 通过
- ⚠️ `borderline` — 让用户决定是否打回
- ❌ `failed` — 强烈建议打回 Step 5

## 4. 写入 meta.json

```json
{
  "step_progress": { "current_step": 7, "completed_steps": [1,2,3,4,5,6] },
  "quality_check": {
    "deck_diff_status": "<from diff-report.json>",
    "ai_taste_check": "passed | needs_polish",
    "buyer_perspective": "passed | borderline | failed"
  }
}
```

## 5. 确认门 ✅（严格模式）/ 自动通过（fast 模式且全为 passed/clean）

严格模式：列出三层结果，等用户验收。
Fast 模式：三层全通过自动放行；任一层非通过仍触发用户确认。
