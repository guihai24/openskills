# Step 8 — IMA 同步 + memory 反哺

> 目标：把交付物同步到 IMA 知识库；把这次的"AI 初印象 vs 用户纠偏"沉淀到 memory。
> **失败要点**：IMA 同步失败时阻塞交付；忘记反哺 memory。

## ⚠️ 重要：ima-skill 是路径引用型 skill

**ima-skill 已安装** 在 `/root/openskills/skills/ima-skill/`。凭证在 `~/.config/ima/{client_id,api_key}`。

**不要重新安装**。**不要去 Claude Code 的 `Available skills` 索引里找它**——它不在那个列表里是正常的。

**调用方式**：通过 Bash 执行 `node /root/openskills/skills/ima-skill/ima_api.cjs <apiPath> <body_json> <options_json>`。详细 API 见 `/root/openskills/skills/ima-skill/knowledge-base/SKILL.md`。

如果 Step 0 `verify-deps.sh` 这一项是 ❌，先告诉用户具体什么文件 / 凭证缺失；**绝不要自己重装**。

---

## 1. IMA 同步

### 1.1 选目标知识库（2026-05-13 更正）

**默认目标**：`小红书-虚拟产品作品库`
- KB ID: `lNswTIkQ8SHZCsNg9S2MlYCIBay65kNg9yoHGJCufUE=`

**不是** `小红书-虚拟产品`（id `oi-ggVQz...`）——那是资料库（输入素材），作品库才是输出归档。教训：youtube-xhs-curation 跑错了 KB。

让用户确认或换库。

### 1.2 定位 / 创建 slug 文件夹（2026-05-13 新增）

IMA API **不支持创建文件夹**，文件夹必须在 IMA UI/客户端手动建好。

执行：

```bash
SKILL_DIR=/root/openskills/skills/ima-skill
KB_ID="lNswTIkQ8SHZCsNg9S2MlYCIBay65kNg9yoHGJCufUE="

# 列根目录
node "$SKILL_DIR/ima_api.cjs" "openapi/wiki/v1/get_knowledge_list" \
  "{\"knowledge_base_id\":\"$KB_ID\",\"limit\":50,\"cursor\":\"\"}" '{}'
```

在返回的 `knowledge_list` + `current_path` 里查找 `name == "<slug>"` 的 folder。

- **找到**：拿到 `folder_id`，进入 1.3
- **没找到**：暂停 skill，告诉用户：
  ```
  ⚠️ IMA 知识库「小红书-虚拟产品作品库」内没有名为 <slug> 的文件夹。
  请你打开 IMA App，在该库根目录手动创建文件夹「<slug>」，建好后回复"已建"继续。
  原因：IMA OpenAPI 不支持创建文件夹（仅支持引用已存在文件夹）。
  ```
  用户回复后再次列文件夹，找到则继续。

### 1.3 上传 Markdown 三件套（不传 HTML）

按以下顺序上传，每个 add_knowledge 都传 `folder_id`：

| 文件 | media_type | 流程 |
|------|------------|------|
| `curator-note.md` | 7 (Markdown) | create_media → COS upload → add_knowledge |
| `references.md` | 7 (Markdown) | 同上 |
| `xhs-post.md` | 7 (Markdown) | 同上 |

具体 API 调用见 `/root/openskills/skills/ima-skill/knowledge-base/SKILL.md`。

### 1.4 HTML 走 GitHub repo（不传 IMA）

deck.html **不上传 IMA**——IMA OpenAPI 只接受 PDF/Word/PPT/Excel/Markdown/Image/TXT/Xmind/录音，HTML 不在列。

改走 GitHub repo：

```bash
DELIVERIES_REPO=/root/xhs-shop-deliveries
SLUG="<slug>"

# 确认 repo 已存在（一次性手动建过，见 docs/notes/github-deliveries-repo.md）
test -d "$DELIVERIES_REPO/.git" || {
  echo "❌ $DELIVERIES_REPO 不存在 / 不是 git repo。请先按 docs/notes/github-deliveries-repo.md 初始化"
  exit 1
}

# 复制 HTML + cover 进 repo
mkdir -p "$DELIVERIES_REPO/products/$SLUG"
cp products/$SLUG/ppt/index.html "$DELIVERIES_REPO/products/$SLUG/deck.html"
cp products/$SLUG/cover.* "$DELIVERIES_REPO/products/$SLUG/" 2>/dev/null
cp products/$SLUG/meta.json "$DELIVERIES_REPO/products/$SLUG/"

cd "$DELIVERIES_REPO"
git add "products/$SLUG/"
git commit -m "deliver: $SLUG"
git push origin main
```

发货时卖家从 `xhs-shop-deliveries` repo 取 HTML 发给买家（邮件附件 / 网盘）。

### 1.5 记录 ima_doc_id

每个 .md 上传成功后拿到 `media_id`，写入 meta.json：

```json
{
  "ima_doc_ids": {
    "curator_note": "markdown_xxx",
    "references": "markdown_xxx",
    "xhs_post": "markdown_xxx"
  },
  "ima_folder_id": "<slug folder id>",
  "ima_kb_id": "lNswTIkQ8SHZCsNg9S2MlYCIBay65kNg9yoHGJCufUE=",
  "deliveries_repo_path": "/root/xhs-shop-deliveries/products/<slug>/"
}
```

### 1.6 失败处理

任一 .md 上传失败：
- **不阻塞交付**
- meta.json 写 `ima_sync_status: "partial"` + `ima_sync_errors: [...]`
- 给一行重试命令

GitHub repo push 失败（远端冲突 / 凭证）：
- meta.json 写 `github_sync_status: "failed"`
- 提示用户手动 `cd /root/xhs-shop-deliveries && git pull --rebase && git push`

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
📁 主目录: /root/xhs-shop/products/<slug>/
📦 产物：ppt/index.html (<cjk_count> CJK), curator-note.md, references.md, xhs-post.md, cover.*, meta.json
📚 IMA: <slug> 文件夹 / 已传 3 份 .md / 库 = 小红书-虚拟产品作品库
💾 GitHub: /root/xhs-shop-deliveries/products/<slug>/ (含 deck.html + cover + meta.json)
📈 沉淀: AUDIENCE_PROFILES.md +1 · TITLE_LESSONS.md +1
下一步: 
  1. 去小红书上架，把 marketplace_status 改成 listed
  2. 商品详情写"交付格式：单文件 HTML（电脑/手机/平板均可打开）"
  3. 买家下单后从 xhs-shop-deliveries repo 取 HTML 发邮件/网盘
```
