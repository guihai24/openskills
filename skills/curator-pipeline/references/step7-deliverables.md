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

### 1.2 调用 writer

显式调用 marker-writer 或 khazix-writer（让用户选偏好的写手）。

期待输出：
- 5 个标题变体 + 推荐 + 4U 评分理由
- 1 篇正文（按 brief 要求的 7 段结构）

写入 `products/<slug>/xhs-post.md`。

### 1.3 在 TITLE_LESSONS.md 记录

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
