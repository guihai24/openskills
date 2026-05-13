# Step 5 — 生成 HTML PPT（调 guizang-ppt-skill）

> 目标：把 Step 4 通过的策展终稿，交给 guizang-ppt-skill 风格生成单文件 HTML PPT。
> **失败要点**：把它当外部进程调；忘了 guizang 是 prompt skill（Claude 自己按指令写 HTML）。

## ⚠️ 重要：guizang-ppt-skill 是路径引用型 skill

**guizang-ppt-skill 已安装** 在 `/root/openskills/skills/guizang-ppt-skill/`。

**不要重新安装**。**不要去 Claude Code 的 `Available skills` 索引里找它**——它不在那个列表里是正常的（它是路径引用型 skill，不是 Claude Code 注册型 skill）。

**调用方式**：用 `Read` 工具读 `/root/openskills/skills/guizang-ppt-skill/SKILL.md`，按里面的 7 问澄清表 + layouts + themes 自己写 HTML。

如果 Step 0 `verify-deps.sh` 这一项是 ❌，先告诉用户具体什么文件缺失，再让用户决定是否重装；**绝不要自己 git clone 或 cp**。

---

## 1. 准备 brief

读 `products/<slug>/curation.md`（终稿）+ Step 2 蓝图信息。

### 1.1 字数预检（2026-05-13 新增红线）

deck.html 必须 ≥ 10,000 CJK 字符（见 CURATOR_STYLE.md 红线）。

**先量 curation.md 的 CJK 数**：
```bash
python3 -c "import re,sys; print(len(re.findall(r'[一-鿿]', open(sys.argv[1]).read())))" /root/xhs-shop/products/<slug>/curation.md
```

- 如果 curation.md CJK < 13,000 → 不要硬上 Step 5，回 Step 3 把章节做深做透（deck 通常呈现 curation 的 70-80%）
- 如果 ≥ 13,000 → 继续生成 brief

**禁止**：为达字数硬塞废话。判别废话的简易测试见 CURATOR_STYLE.md "💰 定价哲学"。

### 1.2 写 brief

生成 guizang 的 brief：

```
风格: B (瑞士国际主义)  # 默认；知识库/技术/数据类必选 B；人文/经验类可选 A
主题色: <从 references/themes-swiss.md 选 1 套>
受众: <meta.json.audience>
分享时长 / 期望页数: <根据 curation CJK 推算；10k CJK ≈ 25-30 页；15k ≈ 35-40 页>
大纲: <markdown 列出每页标题与要点，由 curation.md 转换>
图片: <如果 Step 7 已经出图可填路径；否则用 image_hint>
硬约束:
  - 必须包含主关键词 <kw_primary>
  - 不能出现 emoji
  - **不能出现 "references/"、"themes/"、"layouts/"、"brief"、"图片约定" 等元信息字样**（封面 lint）
  - **每页字数下限**：内容页 ≥ 350 CJK 字符；封面/章节幕封 ≥ 150 CJK；总和 ≥ 10,000 CJK
```

让用户确认风格 A/B 和主题色。

## 2. 调用 guizang-ppt-skill 生成 HTML

guizang 是一个 **prompt skill**（不是外部进程），即由 Claude 读 `/root/openskills/skills/guizang-ppt-skill/SKILL.md` 后**自己写出 HTML**。

执行方式：
- 显式声明"使用 guizang-ppt-skill 风格生成 HTML"
- Claude 按 guizang 的 7 问澄清清单跑（如果信息已齐，直接进 Step 2）
- 按风格 A/B 选择对应 template（`assets/template.html` 或 `assets/template-swiss.html`）+ layouts + themes
- 把 brief 转成完整 HTML 写到 `products/<slug>/ppt/index.html`

注意 guizang SKILL.md 里的 **swiss-layout-lock.md** 约束（如果选 B）—— 只能用 S01-S22 / SWISS-COVER-ASCII / SWISS-CLOSING-ASCII 这几个 layout。

## 3. 生成后强制自检（2026-05-13 新增）

### 3.1 字数硬卡

```bash
python3 /root/xhs-shop/scripts/count-cjk.py /root/xhs-shop/products/<slug>/ppt/index.html
```

- `pass: true`（CJK ≥ 10,000）→ 继续 3.2
- `pass: false` → **回 Step 1.2 重写 brief，把更多 curation 内容上墙；不要直接进 Step 6**

### 3.2 封面 lint（如果选 B 瑞士风）

```bash
node /root/openskills/skills/guizang-ppt-skill/scripts/validate-swiss-deck.mjs \
  /root/xhs-shop/products/<slug>/ppt/index.html
```

预期输出：`Swiss deck validation passed: N slide(s).`

如果校验失败：列出错误 → 让 Claude 修正 HTML → 再校验。**禁止用 `--allow-experimental` 绕过红线**。

### 3.3 元信息残留 lint

```bash
grep -nE "references/(layouts|themes|swiss-layout-lock)|参考 references/|主题色配置参考|图片约定|brief|主题色继承" \
  /root/xhs-shop/products/<slug>/ppt/index.html
```

任何命中 → 那一行是 placeholder 残留，必须修掉再继续。教训：youtube-xhs-curation Slide 1 翻车。

## 4. 失败处理

- HTML 生成报错 → 保存错误日志到 `products/<slug>/source/guizang-error.log`
- 让用户选：重试 / 换风格 A / 简化大纲后重试 / 跳过 PPT 仅交付 Markdown
- CJK 不达标 → 不允许"接受风险继续"；必须回 Step 1.2 或 Step 3 补内容

## 5. 写入 meta.json

```json
{
  "step_progress": { "current_step": 6, "completed_steps": [1,2,3,4,5] },
  "deliverables": {
    "deck_html": "ppt/index.html",
    "deck_pptx": null
  },
  "deck_metrics": {
    "cjk_count": <from count-cjk.py>,
    "slide_count": <from validate-swiss-deck.mjs>
  }
}
```

注意：**`deck_pptx` 一律标 null**。guizang 只产 HTML（参见 `docs/notes/guizang-interface.md`）。

## 6. 无独立确认门

HTML 生成成功（含三层 lint 通过）后直接进入 Step 6 质检；质检才是真正的验收点。
