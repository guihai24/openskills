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

PYTHON_SCRIPT=$(agnes_native_path "$SCRIPT_DIR/_image.py")

if [[ -n "$INPUT_IMAGE" ]]; then
  echo "Mode: image-to-image | size: $SIZE" >&2
else
  echo "Mode: text-to-image | size: $SIZE" >&2
fi

# Do everything in Python: build payload, call API, download result.
export AGNES_PROMPT="$PROMPT"
export AGNES_SIZE="$SIZE"
export AGNES_INPUT_IMAGE="$INPUT_IMAGE"
export AGNES_API_KEY="$API_KEY"
export AGNES_BASE_URL="$BASE_URL"
export AGNES_OUTPUT_FILE="$(agnes_native_path "$OUTPUT_FILE")"

RESULT=$(python3 "$PYTHON_SCRIPT" run 2>&1)
RC=$?

if [[ $RC -ne 0 ]]; then
  echo "ERROR: image generation failed — $RESULT" >&2
  exit 1
fi

echo "Saved: $RESULT" >&2
echo "$OUTPUT_FILE"
