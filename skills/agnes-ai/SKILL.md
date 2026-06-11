---
name: agnes-ai
description: |
  Generate images AND videos with Agnes AI models (agnes-image-2.1-flash for
  images, agnes-video-v2.0 for video). Use this skill to:
  - Create an image from text, or edit/transform an existing image (image-to-image)
  - Generate a video from text, animate an image, or build multi-image / keyframe videos
  Trigger on requests to create visual media: "生成图片", "画一张", "画个",
  "生成视频", "做个视频", "把这张图变成视频", "图生视频", "文生视频",
  "generate an image", "make a video", "animate this image", "text to video",
  "image to video", "keyframe animation", when the user mentions "Agnes" /
  "agnes-ai", or /agnes-ai. ESPECIALLY use this for ANY video generation request.
  Do NOT trigger for: image compression/resizing/format conversion, OCR/text
  extraction, screenshot capture, analyzing or describing existing media, or
  writing image/video generation API code.
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

# Agnes AI — Image & Video Generation

Generate visual media through the Agnes AI API:

- **Images** — `agnes-image-2.1-flash` (text-to-image, image-to-image)
- **Videos** — `agnes-video-v2.0` (text / image / multi-image / keyframe; asynchronous)

## Setup

Needs an Agnes AI API key (get one at https://agnes-ai.com → API Platform). Provide it either way:

```bash
export AGNES_API_KEY="your-key"                                  # 1) environment variable
mkdir -p ~/.config/agnes-ai && printf 'AGNES_API_KEY=your-key\n' \
  > ~/.config/agnes-ai/config && chmod 600 ~/.config/agnes-ai/config  # 2) config file
```

Optional: `AGNES_OUTPUT_DIR` (where results are saved, default `~/agnes-output`).

## Workflow

1. Decide **image** vs **video** from the request.
2. Craft a vivid **English** prompt (see Prompt Crafting) — translate from any language.
3. Run the matching script below.
4. `Read` the output file to show the user the result.
5. Report the saved local path (for video, also mention the duration).

## Commands

### Image

```bash
bash ${CLAUDE_SKILL_DIR}/bin/generate-image.sh "<english_prompt>" [size] [input_image]
```

| Param | Required | Default | Notes |
|---|---|---|---|
| prompt | yes | — | English works best |
| size | no | `1024x1024` | e.g. `1024x768`, `1024x1792` |
| input_image | no | — | public URL / data URI / **local path** → runs image-to-image |

Prints the saved `.png` path to stdout on success.

### Video (asynchronous)

```bash
bash ${CLAUDE_SKILL_DIR}/bin/generate-video.sh "<english_prompt>" [image] [duration_seconds]
```

| Param | Required | Default | Notes |
|---|---|---|---|
| prompt | yes | — | English works best |
| image | no | — | one URL/path → image-to-video; comma-separate **2+** → multi-image / keyframe |
| duration_seconds | no | `5` | ~3 / 5 / 10 / 18s; mapped to a valid frame count automatically |

Advanced options (environment variables): `AGNES_VIDEO_FPS` (24),
`AGNES_VIDEO_WIDTH` (1152), `AGNES_VIDEO_HEIGHT` (768),
`AGNES_VIDEO_MODE` (`keyframes`), `AGNES_VIDEO_NEGATIVE`, `AGNES_VIDEO_SEED`.

The script creates the task, polls until completion (tens of seconds to a few
minutes), then downloads the `.mp4`. Prints the saved path on success.

## Prompt Crafting

Translate the user's idea into fluent English, then enrich it:

- **Image**: `[Subject] + [Scene/Environment] + [Style] + [Lighting] + [Composition] + [Quality]`
  e.g. *"A luminous floating city above a misty canyon at sunrise, cinematic realism, wide-angle composition, soft golden light, high visual density"*
- **Image-to-image**: state what changes AND what to keep —
  *"Transform into a rain-soaked cyberpunk night with neon reflections, while preserving the original composition and main subject layout"*
- **Video**: `[Subject] + [Action] + [Scene] + [Camera Movement] + [Lighting] + [Style]`
  e.g. *"A young astronaut walking across a red desert planet, dust blowing in the wind, slow cinematic tracking shot, dramatic sunset lighting, realistic sci-fi"*
- **Image-to-video**: describe what should move and what stays stable —
  *"Subtle breathing motion, hair moving gently in the wind, while keeping the face and outfit consistent"*

Keep the user's creative intent intact — enhance, don't override.

## Examples

User: "画一只在沙滩散步的猫，电影感"
```bash
bash ${CLAUDE_SKILL_DIR}/bin/generate-image.sh "A cat walking on the beach at sunset, cinematic photography, warm golden light, soft bokeh, ultra realistic"
```

User: "把这张照片做成 5 秒视频，让她慢慢回头"
```bash
bash ${CLAUDE_SKILL_DIR}/bin/generate-video.sh "The woman slowly turns around and looks back at the camera, natural facial expression, cinematic camera movement" "/path/to/photo.png" 5
```

After either command, `Read` the printed file path to display the result.

## Notes

- **Pricing** (per Agnes docs): images ~`$0.003` each; video ~`$0.005`/second.
- **Timing**: images take seconds; video takes tens of seconds to a few minutes.
- **Frame rule**: video frame count must be `8n+1` and ≤ 441 — the script snaps the requested duration to a valid value automatically.
- **Known doc discrepancy**: for image-to-image the input image goes under `extra_body.image` (per the official call examples); the prose docs also mention a top-level `image` array. This skill uses `extra_body.image`.
- Output is saved to `~/agnes-output` by default (`AGNES_OUTPUT_DIR` to change).
- Run `bash ${CLAUDE_SKILL_DIR}/test/run.sh` for offline mock tests (no key needed).
