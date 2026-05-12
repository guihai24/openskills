# Failure Handling — 失败路径合集

> 任何一步发生失败时，按此处理。绝不"硬撑过去"。

## 通用原则

1. **不脑补**：素材不够 / 搜索无果 → 报警，不编造
2. **不静默吞错**：失败时显式报告给用户
3. **不阻塞不必要的事**：副产物失败不阻塞交付
4. **状态可断点续跑**：每步成功后写 `meta.json.step_progress`

## 按阶段处理表

| 阶段 | 失败情况 | 处理 |
|------|---------|------|
| Step 1 | URL 抓取失败 | 报错 + "手动粘文本"指引，不重试 |
| Step 1 | 素材 < 1500 字 / 营销话术高密度 | "撑不起付费精品，建议放弃/补料"；STOP |
| Step 2 | 找不到 ≥2 个整理切面 | "原素材不支持策展深度"，建议换素材或扩展信息源 |
| Step 3 | P0 三层某层无果 | 标"未深挖完整"，Step 4 强提醒，让用户决定降级 P1 / 换章 |
| Step 3 | 搜索结果全黑名单 | 报告 + 询问"允许使用还是放弃"；禁止悄悄使用 |
| Step 4 | fact-check 不通过 | 列疑点逐项决定：删除 / 修正 / 接受风险 |
| Step 5 | guizang HTML 生成失败 | 保存错误日志，让用户选：重试 / 换风格 A / 简化大纲后重试 / 跳过仅交付 MD |
| Step 5 | swiss-deck 校验失败（layout 红线） | 列错误让 Claude 修正 HTML，重校验；禁止 `--allow-experimental` 绕过 |
| Step 6 | HTML 内容 major_drift | 列变形清单，让用户决定：重生成 / 接受 / 手动修复 |
| Step 7 | 文案/封面失败 | 不阻塞 HTML 交付，标 status，提示手动补 |
| Step 8 | IMA 同步失败 | 不阻塞交付，meta.json 写 `ima_sync_status: failed`，给重试命令 |
| 任意 | sentinel M2 拦截依赖 | 立即停止，等用户决定 |
| 任意 | 用户两次拒绝同步骤产出 | skill 暂停，提示"是否调整 Step 1 受众/方向？" |

## 断点续跑

启动 skill 时，如果 `meta.json` 存在且 `status != "delivered"`：

```
检测到 <slug> 进行到 Step <N>。继续 / 重跑该步 / 放弃此产品？
```

按用户选择：
- 继续 → 从 `step_progress.current_step` 开始
- 重跑 → 把 `current_step` 已有的产物移到 `products/<slug>/_attempts/<timestamp>/`，重新开始该步
- 放弃 → 把整个 `products/<slug>/` 移到 `archive/<slug>-<timestamp>/`
