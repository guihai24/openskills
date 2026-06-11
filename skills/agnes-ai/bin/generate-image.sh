#!/usr/bin/env bash
# Agnes AI image generation (text-to-image and image-to-image).
#
# Usage: generate-image.sh "<prompt>" [size] [input_image]
#   prompt       required  text instruction (any language; English works best)
#   size         optional  output size, default 1024x1024 (e.g. 1024x768)
#   input_image  optional  public image URL, data URI, or local file path.
#                          When given, runs image-to-image (transform/edit).
#
# On success prints the local output file path to stdout (exit 0).
# Progress and errors go to stderr; exits 1 on failure.
#
# Injection-safe: the prompt and image path are passed to python via
# environment variables and serialized with json.dump — never interpolated.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

PROMPT="${1:?Usage: generate-image.sh \"<prompt>\" [size] [input_image]}"
SIZE="${2:-1024x1024}"
INPUT_IMAGE="${3:-}"

agnes_require_cmds || exit 1
API_KEY=$(agnes_resolve_key) || exit 1
BASE_URL=$(agnes_base_url)
OUT_DIR=$(agnes_output_dir)
TS=$(date +%s)
OUTPUT_FILE="$OUT_DIR/agnes_image_${TS}.png"

PAYLOAD_FILE=$(mktemp)
RESP_FILE=$(mktemp)
trap 'rm -f "$PAYLOAD_FILE" "$RESP_FILE"' EXIT

# Build the request payload (user input via env -> json.dump, injection-safe).
export AGNES_PROMPT="$PROMPT" AGNES_SIZE="$SIZE" AGNES_INPUT_IMAGE="$INPUT_IMAGE"
python3 "$SCRIPT_DIR/_image.py" build > "$PAYLOAD_FILE"

if [[ -n "$INPUT_IMAGE" ]]; then
  echo "Mode: image-to-image | size: $SIZE" >&2
else
  echo "Mode: text-to-image | size: $SIZE" >&2
fi

HTTP_CODE=$(curl -s -o "$RESP_FILE" -w "%{http_code}" --max-time 360 \
  "$BASE_URL/v1/images/generations" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "@${PAYLOAD_FILE}" 2>/dev/null || echo "000")

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "ERROR: image generation failed — HTTP $HTTP_CODE ($(agnes_http_hint "$HTTP_CODE"))" >&2
  head -c 400 "$RESP_FILE" >&2 && echo >&2
  exit 1
fi

# Parse the response: URL to download, inline base64, or an error.
export AGNES_RESP_FILE="$RESP_FILE" AGNES_OUTPUT_FILE="$OUTPUT_FILE"
RESULT=$(python3 "$SCRIPT_DIR/_image.py" parse)

case "$RESULT" in
  URL:*)
    IMG_URL="${RESULT#URL:}"
    echo "Downloading image..." >&2
    DL=$(curl -s -o "$OUTPUT_FILE" -w "%{http_code}" --max-time 120 "$IMG_URL" 2>/dev/null || echo "000")
    if [[ "$DL" == "200" && -s "$OUTPUT_FILE" ]]; then
      echo "Saved: $OUTPUT_FILE ($(wc -c < "$OUTPUT_FILE" | tr -d ' ') bytes)" >&2
      echo "$OUTPUT_FILE"
    else
      echo "ERROR: failed to download generated image (HTTP $DL)" >&2
      exit 1
    fi
    ;;
  B64:*)
    echo "Saved: $OUTPUT_FILE ($(wc -c < "$OUTPUT_FILE" | tr -d ' ') bytes)" >&2
    echo "$OUTPUT_FILE"
    ;;
  ERR:*)
    echo "ERROR: ${RESULT#ERR:}" >&2
    exit 1
    ;;
  *)
    echo "ERROR: unexpected parser output: $RESULT" >&2
    exit 1
    ;;
esac
