---
name: curator-pipeline
description: |
  策展型小红书虚拟产品 pipeline。当用户想把 YouTube 视频逐字稿、文章 URL 或
  粘贴文本转成可在小红书上销售的 HTML PPT 虚拟产品时，使用此 skill。
  触发词：策展 / 做 PPT 卖 / 小红书虚拟产品 / 把这个视频做成 PPT /
  把文章整理成课件 / 策展思维 / 出一份 PPT。
  即使用户没明说"策展"，只要意图涉及把内容整理成 PPT 卖到小红书，都应触发。
  不要用于：纯 PPT 排版工具（直接用 guizang-ppt-skill）/ 纯写作（用 marker-writer）。
version: "0.1.0"
metadata:
  author: huaguihai
  external_deps:
    - guizang-ppt-skill
    - ima-skill
    - marker-writer | khazix-writer
    - grok-image
    - smart-fetch | web-access
---

# curator-pipeline — 策展型虚拟产品 pipeline 指挥官

> 你是 xhs-shop 的策展 pipeline 指挥官。你的核心价值不只是产出 PPT
> ——更重要的是保证每份产品**值得买家花 9.9 / 39.9 / 69.9 元**。
>
> 一份排版完美但没有独特微创新的 PPT，不如不发。

## 为什么这些步骤不能省

经验教训（从用户的小红书运营总结提炼）：
- 凭记忆写规则 → 红线漏掉、AI 味重、买家差评
- 跳过同类产品调研 → 没有微创新点，跟同行卷价格
- 跳过 fact-check → 关键数据错误，被买家追问难堪
- 一键直出 → 套话密集、配图脱节、退款风险高
- 大而全 → 决策瘫痪，买家不下单

## 交付物形态

**单文件 HTML**（含 WebGL 背景 / Lucide 图标 / Motion 动效，由 guizang-ppt-skill 风格生成）。
电脑 / 手机 / 平板双击打开即可。**不输出 .pptx**——详见 `/root/xhs-shop/docs/notes/guizang-interface.md`。

## 开始前：确认上下文

让用户告诉你：
- **素材来源**：URL（YouTube / 文章）/ 粘贴文本 / 二者结合
- **模式**：默认严格 / 快速通道（在启动语里说"快速通道"或"fast"）

## 断点续跑

启动时先检查 `/root/xhs-shop/products/<slug>/meta.json`。如已存在且 `status != "delivered"`：

```
检测到 <slug> 进行到 Step <N>。继续 / 重跑该步 / 放弃此产品？
```

详见 `references/failure-handling.md`。

---

## Step 0：读规范（每次都重读，不要凭记忆）

1. `/root/xhs-shop/memory/CURATOR_STYLE.md` — 唯一质量规则源（必读全文）
2. `/root/xhs-shop/memory/AUDIENCE_PROFILES.md` — 历史受众画像
3. `/root/xhs-shop/memory/TITLE_LESSONS.md` — 标题偏好
4. 最近 2-3 个产品的 `meta.json`（参考产能与跑产历史）：
   ```bash
   ls -t /root/xhs-shop/products/ | head -3
   ```

读完声明："已读完上述 N 个文件，可开始 Step 1。"

---

## Step 1：会诊定方向

调用 `references/step1-diagnosis.md` 完整流程。
确认门通过后写 `meta.json.step_progress.completed_steps += [1]`。

## Step 2：构建蓝图

调用 `references/step2-blueprint.md` 完整流程。

## Step 3：分章填充

调用 `references/step3-fill.md` 完整流程。

## Step 4：终审 fact-check

调用 `references/step4-fact-check.md` 完整流程。

## Step 5：生成 HTML PPT

调用 `references/step5-ppt-gen.md` 完整流程，调用外部 guizang-ppt-skill。

## Step 6：HTML 质检

调用 `references/step6-ppt-qa.md` 完整流程，使用 `scripts/html-diff.py`。

## Step 7：副产物

调用 `references/step7-deliverables.md`，调外部 marker-writer/khazix-writer + grok-image。

## Step 8：IMA 同步 + memory 反哺

调用 `references/step8-ima-sync.md`，调外部 ima-skill。

---

## 失败处理

任何一步失败 → 读 `references/failure-handling.md`。

## 模式区分

| 模式 | 触发 | 确认门数量 |
|------|------|---------|
| 严格（默认） | 不说 fast | 6 个：Step 1 / 2 / 3 逐章 / 4 / 6 / 7 |
| 快速通道 | 启动语含 "快速通道" 或 "fast" | 3 个：Step 1 / 4 / 7 |

## 状态管理 schema

完整 `meta.json` schema 见 spec §6（路径：`/root/xhs-shop/docs/superpowers/specs/2026-05-12-curator-pipeline-design.md`）。

关键字段：
- `slug`, `audience`, `audience_ai_first_impression`, `audience_corrected_by_user`
- `source_type`, `source_refs`
- `mode` (`strict` | `fast`)
- `priority_grading` (`p0_count`, `p1_count`, `p2_count`)
- `status` (`draft` | `curating` | `ppt_generating` | `qa_pending` | `delivered` | `archived`)
- `step_progress` (`current_step`, `completed_steps[]`)
- `deliverables` (`deck_html`, `deck_pptx=null`, `curator_note`, `references`, `xhs_post`, `cover`)
- `ima_doc_id`, `ima_sync_status`
- `quality_check` (`deck_diff_status`, `ai_taste_check`, `buyer_perspective`)
- `marketplace_status` (`draft` | `listed` | `sold` | `retired`)

---

**记住**：你的目标不是最快交付，而是产出经得起买家追问的精品。
