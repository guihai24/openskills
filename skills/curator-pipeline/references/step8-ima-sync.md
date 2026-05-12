# Step 8 — IMA 同步 + memory 反哺

> 目标：把交付物同步到 IMA 知识库；把这次的"AI 初印象 vs 用户纠偏"沉淀到 memory。
> **失败要点**：IMA 同步失败时阻塞交付；忘记反哺 memory。

## 1. IMA 同步

### 1.1 选目标知识库

读 `meta.json.audience`，匹配最相关的 IMA 知识库。默认目标：
- **小红书-虚拟产品**（id: `oi-ggVQz31pZjnSWBlosAAr6Nj2M0NI8RQdVles3GY8=`）

让用户确认或换库（也可以选`小红书专题`等其他库）。

### 1.2 上传文件

按以下顺序上传到 IMA 知识库目标文件夹：

```bash
SKILL_DIR=/root/openskills/skills/ima-skill
KB_ID="oi-ggVQz31pZjnSWBlosAAr6Nj2M0NI8RQdVles3GY8="

# 三类产物：HTML deck + 策展人说明 + 来源清单
# 每个文件走 create_media → COS upload → add_knowledge 流程
# 详见 /root/openskills/skills/ima-skill/knowledge-base/SKILL.md
```

实际上传按 ima-skill 的 `knowledge-base/SKILL.md` 完整流程：
1. `create_media`（拿 COS 凭证）
2. `cos-upload.cjs`（上传到 COS）
3. `add_knowledge`（关联到知识库）

文件类型映射：
- `deck.html` → media_type=2（网页），需先上传到 COS 再 add_knowledge
- `curator-note.md` → media_type=7（Markdown）
- `references.md` → media_type=7

### 1.3 记录 ima_doc_id

每个文件上传成功后拿到 `media_id`，写入 `meta.json.ima_doc_id`（用 PPT 的 id 作为主标识就够用）。

### 1.4 失败处理

任一文件上传失败：
- **不阻塞交付**
- meta.json 写 `ima_sync_status: "failed"` + `ima_sync_error: <error_msg>`
- 给一行重试命令让用户后续手动跑

## 2. memory 反哺

### 2.1 更新 AUDIENCE_PROFILES.md

追加一行到 `/root/xhs-shop/memory/AUDIENCE_PROFILES.md` 的表格：
| 日期 | slug | 素材 | AI 初印象 | 用户纠偏 | 差异类型 |

差异类型按 `AUDIENCE_PROFILES.md` 末尾定义的分类填（场景偏离 / 专业深度偏离 / 诉求点偏离 / 风格偏离）。

### 2.2 更新 TITLE_LESSONS.md（Step 7 已写一半的话补完）

确认 Step 7 已写入；如未写则补写。

### 2.3 CURATOR_STYLE.md（仅在发现新红线/加分项时）

本次跑产中如果发现新的：
- 红线（"原来 X 也是不能做的事"）
- 加分项（"原来 Y 这种角度卖得好"）

→ 让用户确认后追加到 `/root/xhs-shop/memory/CURATOR_STYLE.md`。否则跳过。

## 3. 完结

```json
{
  "status": "delivered",
  "step_progress": { "current_step": 8, "completed_steps": [1,2,3,4,5,6,7,8] },
  "delivered_at": "<ISO datetime>",
  "marketplace_status": "draft"
}
```

## 4. 终结报告（给用户）

```
✅ 产品已交付：<slug>
📁 位置：/root/xhs-shop/products/<slug>/
📦 产物：deck.html, curator-note.md, references.md, xhs-post.md, cover.png, meta.json
📚 IMA：已同步 / 同步失败（待手动重试）
📈 沉淀：AUDIENCE_PROFILES.md +1, TITLE_LESSONS.md +1
下一步：去小红书上架，把 marketplace_status 改成 listed 即可。
       记得在商品详情写"交付格式：单文件 HTML（电脑/手机/平板均可打开）"
```
