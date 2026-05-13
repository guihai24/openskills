# Step 6 — HTML PPT 三层质检

> 目标：内容 diff（机械层）+ AI 味（抽样层）+ 付费视角（最终层）。
> **失败要点**：只做机械 diff 就放过；忽视配图/排版问题。

## 1. 机械层 — 字数 + 核心概念覆盖率（2026-05-13 更新）

### 1.1 字数硬卡

```bash
python3 /root/xhs-shop/scripts/count-cjk.py \
  /root/xhs-shop/products/<slug>/ppt/index.html
```

- `pass: true`（CJK ≥ 10,000）→ 继续 1.2
- `pass: false` → 不能交付，回 Step 5 重生 / 回 Step 3 补内容（取决于 curation.md 自身够不够）

教训：youtube-xhs-curation deck.html 只有 1,989 CJK，远低于红线 → 必须回 Step 3 把章节做深做透。

### 1.2 核心概念覆盖率（取代 html-diff 机械短语对比）

让 Claude 自己列 Step 2 蓝图里的"核心概念清单"（一般 8-15 个，覆盖 ★ 增值点 + 卖点切片关键词），逐条核对 deck.html 是否呈现。

```
核心概念覆盖检查表
─────────────────────
| # | 概念 | 在 deck 哪一页呈现 | 状态 |
|---|------|-------------------|------|
| 1 | 4 维筛选决策表 | P5/P6/P7 | ✅ |
| 2 | 7 种整理切面菜单 | P10/P11/P12 | ✅ |
| 3 | 卢曼卡片盒法 | (未呈现) | ❌ 缺核心 |
| ...  |
```

- 全 ✅ → 通过此层
- 任一 ❌ → 报告给用户，决定回 Step 5 补 / 砍此概念 / 接受不呈现（写入 meta.json 备注）

**`html-diff.py` 改为参考使用**：它对策展产品（取精华+重组）会一律报 expected_drift，状态用 `expected_drift` 而非打回 Step 5（见 CURATOR_STYLE.md 警示条款 #7）。如果用户想看 diff 报告作辅助参考，可以跑；但不作为放行/打回依据。

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

## 3. 付费视角层（2026-05-13 强化）

**不要再问抽象的"觉得值吗"。改用"刚花钱模拟"**：

```
💰 付费视角自检（强制具体）
你刚花了 <price> 元（来自 meta.json.pricing_target，3.9-19.9 区间）下单这份 PPT。
现在打开手机看到第 1 页，请回答：
1. 第 1 页的标题是否让你立刻明白"这就是我要的东西"？还是要翻 2-3 页才懂？
2. 翻完前 5 页后，你心里的反应是"赚到了"还是"就这？"
3. 整份 22 页里，最让你想截图/转发/收藏的是哪一页？为什么？
4. 整份里，最让你想要求退款的是哪一页？为什么？
5. 你会推荐给闺蜜/同事吗？理由是什么？
```

每个问题必须具体到页码 + 短理由。

结果分类：
- ✅ `passed` — 4/5 个问题答案积极、能指出"最想转发"的页
- ⚠️ `borderline` — 答得出问题但找不到真正的高光页
- ❌ `failed` — 一半以上问题答"不知道 / 内容太空 / 凑数"

教训：youtube-xhs-curation 这一层标了 passed 但用户实际感受空——是因为问题太抽象。现在改成"必须指页 + 短理由"，逼 AI 真正模拟买家视角。

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
