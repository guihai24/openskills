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
POLL_INTERVAL="${AGNES_VIDEO_POLL_INTERVAL:-5}"
POLL_MAX="${AGNES_VIDEO_POLL_MAX:-120}"

agnes_require_cmds || exit 1
API_KEY=$(agnes_resolve_key) || exit 1
BASE_URL=$(agnes_base_url)
OUT_DIR=$(agnes_output_dir)
TS=$(date +%s)
OUTPUT_FILE="$OUT_DIR/agnes_video_${TS}.mp4"

PAYLOAD_FILE=$(mktemp)
RESP_FILE=$(mktemp)
trap 'rm -f "$PAYLOAD_FILE" "$RESP_FILE"' EXIT

# Build the create-task payload (user input via env -> json.dump, injection-safe).
export AGNES_PROMPT="$PROMPT" AGNES_VIDEO_IMAGE="$IMAGE_ARG" AGNES_VIDEO_DURATION="$DURATION"
python3 "$SCRIPT_DIR/_video.py" build > "$PAYLOAD_FILE"

if [[ -z "$IMAGE_ARG" ]]; then
  MODE_DESC="text-to-video"
elif [[ "$IMAGE_ARG" == *,* ]]; then
  MODE_DESC="multi-image / keyframe"
else
  MODE_DESC="image-to-video"
fi
echo "Mode: $MODE_DESC | target ~${DURATION}s" >&2

# 1) Create the async task
HTTP_CODE=$(curl -s -o "$RESP_FILE" -w "%{http_code}" --max-time 120 \
  "$BASE_URL/v1/videos" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "@${PAYLOAD_FILE}" 2>/dev/null || echo "000")

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "ERROR: create video task failed — HTTP $HTTP_CODE ($(agnes_http_hint "$HTTP_CODE"))" >&2
  head -c 400 "$RESP_FILE" >&2 && echo >&2
  exit 1
fi

export AGNES_RESP_FILE="$RESP_FILE"
CREATE=$(python3 "$SCRIPT_DIR/_video.py" parse-create)
if [[ "$CREATE" != ID:* ]]; then
  echo "ERROR: ${CREATE#ERR:}" >&2
  exit 1
fi
VIDEO_ID="${CREATE#ID:}"
echo "Task created: $VIDEO_ID — polling every ${POLL_INTERVAL}s (up to $((POLL_INTERVAL * POLL_MAX))s)..." >&2

# 2) Poll until completed / failed / timeout
VIDEO_URL=""
for ((i = 1; i <= POLL_MAX; i++)); do
  sleep "$POLL_INTERVAL"
  PHTTP=$(curl -s -o "$RESP_FILE" -w "%{http_code}" --max-time 60 \
    "$BASE_URL/agnesapi?video_id=${VIDEO_ID}" \
    -H "Authorization: Bearer ${API_KEY}" 2>/dev/null || echo "000")
  if [[ "$PHTTP" != "200" ]]; then
    echo "  poll $i: HTTP $PHTTP ($(agnes_http_hint "$PHTTP")), retrying..." >&2
    continue
  fi
  R=$(python3 "$SCRIPT_DIR/_video.py" parse-result)
  case "$R" in
    DONE:*) VIDEO_URL="${R#DONE:}"; echo "  completed." >&2; break ;;
    FAIL:*) echo "ERROR: video generation failed — ${R#FAIL:}" >&2; exit 1 ;;
    WAIT:*) rest="${R#WAIT:}"; echo "  poll $i: ${rest%%:*} ${rest#*:}%" >&2 ;;
    *)      echo "  poll $i: unexpected parser output: $R" >&2 ;;
  esac
done

if [[ -z "$VIDEO_URL" ]]; then
  echo "ERROR: timed out after $((POLL_INTERVAL * POLL_MAX))s. The video may still be processing." >&2
  echo "  Retry later: curl '$BASE_URL/agnesapi?video_id=${VIDEO_ID}' -H 'Authorization: Bearer YOUR_API_KEY'" >&2
  exit 1
fi

# 3) Download the mp4
echo "Downloading video..." >&2
DL=$(curl -s -o "$OUTPUT_FILE" -w "%{http_code}" --max-time 300 "$VIDEO_URL" 2>/dev/null || echo "000")
if [[ "$DL" == "200" && -s "$OUTPUT_FILE" ]]; then
  echo "Saved: $OUTPUT_FILE ($(wc -c < "$OUTPUT_FILE" | tr -d ' ') bytes)" >&2
  echo "$OUTPUT_FILE"
else
  echo "ERROR: failed to download video (HTTP $DL). URL: $VIDEO_URL" >&2
  exit 1
fi
