# Step 7 — 副产物生成（小红书文案 + 封面图）

> 目标：生成可直接发布的小红书文案 + 封面图。
> **失败要点**：文案没用上 Step 2 的关键词布局；封面与 HTML PPT 风格脱节。

## 1. 小红书文案（调 marker-writer 或 khazix-writer）

### 1.1 准备 brief

读 `/root/xhs-shop/templates/xhs-post-brief.md`，按 Step 2 蓝图填充：
- slug, title, audience, pain_point
- kw_primary, kw_secondary_list, kw_long_tail（来自 Step 2.1.6 关键词布局）
- main_hook（来自 Step 2.1.5 卖点切片，选主 hook）

特别：在文案的"价格锚定"部分**必须**写明"**交付格式：单文件 HTML（电脑/手机/平板双击打开即可，含动效）**"，避免买家以为是 .pptx。

### 1.2 标题 lint（2026-05-13 新增，红线级）

调用 writer 之前先列 `meta.json.quality_check.fact_check_open_items`，**禁止把这些项里涉及的案例做 title hook**。

示例错误（youtube-xhs-curation 教训）：
- fact_check_open_items: ["Thewizardliz 销量数据为单一来源"]
- ❌ 标题: "120 天 8000 元，她只做对了选油管博主"（用了 Thewizardliz 这个孤证）
- ✅ 正确做法: 改用已多源验证的天花板案例做 hook（如"参考答案阅览室 149/年 卖 3681 份"）

实操：让 writer 出 5 个候选标题时，明确告知"禁止用 <slug> 的 ⚠️ open_items 涉及的案例做主 hook"。

### 1.3 调用 writer

显式调用 marker-writer 或 khazix-writer（让用户选偏好的写手）。

期待输出：
- 5 个标题变体 + 推荐 + 4U 评分理由（**不允许用孤证案例做主 hook**）
- 1 篇正文（按 brief 要求的 7 段结构）

写入 `products/<slug>/xhs-post.md`。

### 1.4 案例呈现顺序（2026-05-13 新增）

如果产品里有多个真实店铺案例：

- **deck 内排序**：天花板 → 中段 → 入门（强→弱）。让买家先看到上限激起欲望，再看到入口降低门槛。
- **文案 hook**：必须从**最强、且 fact-check 通过**的那个案例取数。
- **教训**：youtube-xhs-curation 反过来排（弱→强）+ 标题用最弱案例 → 综合错误，必须改正。

### 1.5 在 TITLE_LESSONS.md 记录

`/root/xhs-shop/memory/TITLE_LESSONS.md` 追加一行：
| 日期 | slug | AI 推荐 | 候选 1-4 | 用户选 | 选择原因 |

如果用户当下没选，留空待补，但**必须**让用户在交付前选。

## 2. 封面图（调 grok-image）

### 2.1 写 prompt

基于 Step 2 风格基调 + PPT 主标题 + Step 5 选定的主题色，写 grok-image prompt。例：

```
小红书封面图，3:4 竖图，主标题"<title>"放大居中，副标题"<subtitle>"放小，
风格 <swiss-helvetica 极简 / 杂志感衬线>，配色 <从 Step 5 主题色继承>，
留 30% 留白避免文字过密，去掉所有 emoji 字符。
```

### 2.2 调用 grok-image

调 grok-image 生成 1-3 张候选，让用户选 1 张。

输出：`products/<slug>/cover.png`

### 2.3 失败处理

grok-image 失败 → 不阻塞交付。在 meta.json 标 `deliverables.cover = null`，提示"封面待补"。

## 3. 注入免责声明

把 `/root/xhs-shop/templates/disclaimer.md` 的合适版本追加到 `xhs-post.md` 文末。

## 4. 写入 meta.json

```json
{
  "step_progress": { "current_step": 8, "completed_steps": [1,2,3,4,5,6,7] },
  "deliverables": {
    "xhs_post": "xhs-post.md",
    "cover": "cover.png"
  }
}
```

## 5. 确认门 ✅

"副产物已出。小红书文案 N 个标题候选（推荐 #X），封面 N 张候选（推荐 #Y）。选完进入 Step 8 同步 IMA 吗？"
