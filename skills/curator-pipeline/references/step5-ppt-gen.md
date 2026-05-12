# Step 5 — 生成 HTML PPT（调 guizang-ppt-skill）

> 目标：把 Step 4 通过的策展终稿，交给 guizang-ppt-skill 风格生成单文件 HTML PPT。
> **失败要点**：把它当外部进程调；忘了 guizang 是 prompt skill（Claude 自己按指令写 HTML）。

## 1. 准备 brief

读 `products/<slug>/curation.md`（终稿）+ Step 2 蓝图信息。生成 guizang 的 brief：

```
风格: B (瑞士国际主义)  # 默认；知识库/技术/数据类必选 B；人文/经验类可选 A
主题色: <从 references/themes-swiss.md 选 1 套>
受众: <meta.json.audience>
分享时长 / 期望页数: <根据章节数推算，6-8 章 ≈ 15-20 页>
大纲: <markdown 列出每页标题与要点，由 curation.md 转换>
图片: <如果 Step 7 已经出图可填路径；否则用 image_hint>
硬约束: 必须包含主关键词 <kw_primary>；不能出现 emoji
```

让用户确认风格 A/B 和主题色。

## 2. 调用 guizang-ppt-skill 生成 HTML

guizang 是一个 **prompt skill**（不是外部进程），即由 Claude 读 `/root/openskills/skills/guizang-ppt-skill/SKILL.md` 后**自己写出 HTML**。

执行方式：
- 显式声明"使用 guizang-ppt-skill 风格生成 HTML"
- Claude 按 guizang 的 7 问澄清清单跑（如果信息已齐，直接进 Step 2）
- 按风格 A/B 选择对应 template（`assets/template.html` 或 `assets/template-swiss.html`）+ layouts + themes
- 把 brief 转成完整 HTML 写到 `products/<slug>/deck.html`

注意 guizang SKILL.md 里的 **swiss-layout-lock.md** 约束（如果选 B）—— 只能用 S01-S22 / SWISS-COVER-ASCII / SWISS-CLOSING-ASCII 这几个 layout。

## 3. 校验生成结果（仅风格 B）

```bash
node /root/openskills/skills/guizang-ppt-skill/scripts/validate-swiss-deck.mjs \
  /root/xhs-shop/products/<slug>/deck.html
```

预期输出：`Swiss deck validation passed: N slide(s).`

如果校验失败：列出错误 → 让 Claude 修正 HTML → 再校验。**禁止用 `--allow-experimental` 绕过红线**。

## 4. 失败处理

- HTML 生成报错 → 保存错误日志到 `products/<slug>/source/guizang-error.log`
- 让用户选：重试 / 换风格 A / 简化大纲后重试 / 跳过 PPT 仅交付 Markdown

## 5. 写入 meta.json

```json
{
  "step_progress": { "current_step": 6, "completed_steps": [1,2,3,4,5] },
  "deliverables": {
    "deck_html": "deck.html",
    "deck_pptx": null
  }
}
```

注意：**`deck_pptx` 一律标 null**。guizang 只产 HTML（参见 `docs/notes/guizang-interface.md`）。

## 6. 无独立确认门

HTML 生成成功后直接进入 Step 6 质检；质检才是真正的验收点。
