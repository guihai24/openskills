# Step 4 — 终审 & fact-check & 策展人说明

> 目标：对所有章节做关键数据/人名/链接核验；生成《策展人说明》；输出终稿。
> **失败要点**：fact-check 不通过的项被悄悄保留；策展人说明套话空洞。

## 1. Fact-check 清单

扫描 `curation.md` 全文，列出所有需要核验的项：
- 具体数字（销量、价格、播放量、字数等）
- 人名 + 头衔（创始人 / 作者 / 教授）
- 概念定义（特别是 Step 3 补充的）
- 引用链接（验证活性，HEAD 请求看 200）

对每项独立核验一次（最多 1 次搜索）。结果分类：
- ✅ 通过
- ⚠️ 疑点（来源孤证 / 链接失活 / 信息过时）
- ❌ 失败（找不到任何来源支持）

## 2. 处理疑点 / 失败项

列出所有 ⚠️/❌ 项给用户，每项逐一决定：
- 删除（最稳）
- 修正（找到新来源替换）
- 接受风险（在 references.md 标"未充分验证"）

**禁止**：用户没看到的情况下自己悄悄放过 ⚠️/❌ 项。

## 3. 逻辑连贯检查

回到全文级别，问 3 个问题：
1. 章节之间是否有逻辑断层（前章前提没在后章兑现）？
2. 是否有重复（多章都讲同一论点）？
3. 总-分-总结构是否完整（如有引言 / 总结章）？

发现问题 → 修订，写入 curation.md。

## 4. 生成《策展人说明》

读 `/root/xhs-shop/templates/curator-note.md`，按模板填充：
- 受众 + 痛点（来自 Step 1）
- 解决的 3 个具体问题（来自 Step 2 卖点切片）
- 如何高效使用（来自章节结构动线）
- 微创新点（来自 Step 2.1.2）
- 免责声明（按需选 `/root/xhs-shop/templates/disclaimer.md` 中的版本）

写入 `products/<slug>/curator-note.md`。

## 5. 写入 meta.json

```json
{
  "step_progress": { "current_step": 5, "completed_steps": [1,2,3,4] },
  "quality_check": {
    "fact_check_status": "passed | partial | failed",
    "fact_check_open_items": [<list of accepted-risk items>]
  }
}
```

## 6. 确认门 ✅（核心，无论何种模式都不能跳）

"终稿已出。fact-check：✅ N 项 / ⚠️ N 项已处理 / ❌ N 项已删除。策展人说明已生成。可进入 Step 5 生成 PPT 吗？"
