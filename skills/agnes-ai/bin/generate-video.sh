#!/usr/bin/env bash
# Agnes AI video generation (async): text / image / multi-image / keyframe.
#
# Usage: generate-video.sh "<prompt>" [image] [duration_seconds]
#   prompt            required  text description of the video
#   image             optional  URL / data URI / local file for image-to-video;
#                               comma-separate 2+ for multi-image / keyframe.
#   duration_seconds  optional  target length in seconds (default 5)
#
# Advanced options via environment variables:
#   AGNES_VIDEO_FPS (24)   AGNES_VIDEO_WIDTH (1152)   AGNES_VIDEO_HEIGHT (768)
#   AGNES_VIDEO_MODE (e.g. keyframes)   AGNES_VIDEO_NEGATIVE   AGNES_VIDEO_SEED
#   AGNES_VIDEO_NUM_FRAMES (override duration; snapped to 8n+1, <=441)
#   AGNES_VIDEO_POLL_INTERVAL (5)   AGNES_VIDEO_POLL_MAX (120 polls)
#
# The API is asynchronous: this creates a task, polls until completion, then
# downloads the .mp4. Prints the local file path to stdout on success;
# progress/errors go to stderr; exits 1 on failure.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

PROMPT="${1:?Usage: generate-video.sh \"<prompt>\" [image] [duration_seconds]}"
IMAGE_ARG="${2:-}"
DURATION="${3:-5}"

agnes_require_cmds || exit 1
API_KEY=$(agnes_resolve_key) || exit 1
BASE_URL=$(agnes_base_url)
OUT_DIR=$(agnes_output_dir)
TS=$(date +%s)
OUTPUT_FILE="$OUT_DIR/agnes_video_${TS}.mp4"

PYTHON_SCRIPT=$(agnes_native_path "$SCRIPT_DIR/_video.py")

if [[ -z "$IMAGE_ARG" ]]; then
  MODE_DESC="text-to-video"
elif [[ "$IMAGE_ARG" == *,* ]]; then
  MODE_DESC="multi-image / keyframe"
else
  MODE_DESC="image-to-video"
fi
echo "Mode: $MODE_DESC | target ~${DURATION}s" >&2

# Do everything in Python: build payload, create task, poll, download.
export AGNES_PROMPT="$PROMPT"
export AGNES_VIDEO_IMAGE="$IMAGE_ARG"
export AGNES_VIDEO_DURATION="$DURATION"
export AGNES_API_KEY="$API_KEY"
export AGNES_BASE_URL="$BASE_URL"
export AGNES_OUTPUT_FILE="$(agnes_native_path "$OUTPUT_FILE")"

RESULT=$(python3 "$PYTHON_SCRIPT" run 2>&1)
RC=$?

if [[ $RC -ne 0 ]]; then
  echo "ERROR: video generation failed — $RESULT" >&2
  exit 1
fi

echo "Saved: $RESULT" >&2
echo "$OUTPUT_FILE"
