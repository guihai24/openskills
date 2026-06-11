# agnes-ai

Image **and** video generation skill for Claude Code, powered by Agnes AI
(`agnes-image-2.1-flash` for images, `agnes-video-v2.0` for video).

## Features

- **Images**: text-to-image and image-to-image (transform/edit, composition-preserving)
- **Videos**: text-to-video, image-to-video, multi-image, and keyframe animation (async)
- **Auto-download**: results are fetched and saved locally (`~/agnes-output` by default)
- **Injection-safe**: prompts are passed via environment variables and serialized with `json.dump` — never interpolated into code or JSON
- **Zero third-party deps**: pure `bash` + `python3` standard library + `curl`
- **Bilingual triggers**: Chinese and English requests both work

## Prerequisites

- An Agnes AI API key — https://agnes-ai.com (API Platform)
- `python3` and `curl`

## Configuration

Provide your API key one of two ways (environment variable takes priority):

```bash
export AGNES_API_KEY="your-key"
# or, persistent across shells (file is read at chmod 600):
mkdir -p ~/.config/agnes-ai && printf 'AGNES_API_KEY=your-key\n' > ~/.config/agnes-ai/config
```

Optional environment variables:

| Variable | Default | Purpose |
|---|---|---|
| `AGNES_OUTPUT_DIR` | `~/agnes-output` | where generated files are saved |
| `AGNES_BASE_URL` | `https://apihub.agnes-ai.com` | API base URL |

## Installation

```bash
ln -s /path/to/openskills/skills/agnes-ai ~/.claude/skills/agnes-ai
```

## Usage

Ask Claude to generate an image or video in any language, or use `/agnes-ai`.
You can also run the scripts directly:

```bash
# text-to-image
bash bin/generate-image.sh "A neon cyberpunk alley at night, cinematic, ultra detailed"

# image-to-image (preserve composition)
bash bin/generate-image.sh "Make it a snowy winter scene, preserve the composition" 1024x768 ./photo.png

# text-to-video (~5s)
bash bin/generate-video.sh "A paper boat sailing down a rainy street, cinematic" "" 5

# image-to-video
bash bin/generate-video.sh "The character blinks and smiles, hair moving gently" ./portrait.png 5
```

Each command prints the saved local file path on success.

## Testing

```bash
bash test/run.sh          # offline unit tests (payload build, parsing, validation)
bash test/integration.sh  # offline end-to-end vs a local mock server (curl/poll/download)
```

## Pricing

Per the Agnes AI docs: images ~`$0.003` each, video ~`$0.005`/second.

## License

MIT
