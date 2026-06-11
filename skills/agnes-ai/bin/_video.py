#!/usr/bin/env python3
"""Payload builder and response parsers for Agnes video generation (async).

All user input arrives via environment variables and is serialized with
json.dump, so it cannot break out of the JSON value (injection-safe).

Subcommands:
  build         - build the create-task payload from AGNES_* env vars (JSON -> stdout)
  parse-create  - read AGNES_RESP_FILE (create response) -> "ID:<video_id>" | "ERR:.."
  parse-result  - read AGNES_RESP_FILE (poll response) -> one of:
                    DONE:<url>            completed, final video URL
                    FAIL:<message>        generation failed
                    WAIT:<status>:<pct>   still queued / in_progress

Env vars read by `build`:
  AGNES_PROMPT (required), AGNES_VIDEO_IMAGE (comma-separated urls/paths),
  AGNES_VIDEO_DURATION (seconds, default 5), AGNES_VIDEO_FPS (24),
  AGNES_VIDEO_WIDTH (1152), AGNES_VIDEO_HEIGHT (768), AGNES_VIDEO_MODE,
  AGNES_VIDEO_NEGATIVE, AGNES_VIDEO_SEED, AGNES_VIDEO_NUM_FRAMES (override).
"""
import sys
import os
import json
import base64
import mimetypes

MODEL = "agnes-video-v2.0"
MAX_FRAMES = 441


def snap_num_frames(duration_s, fps):
    """num_frames must satisfy 8n+1 and be <= 441. Snap to nearest valid value."""
    raw = max(1, int(round(duration_s * fps)))
    n = max(1, int(round((raw - 1) / 8.0)))
    frames = 8 * n + 1
    if frames > MAX_FRAMES:
        frames = MAX_FRAMES
    if frames < 9:
        frames = 9
    return frames


def _resolve_image(ref):
    ref = ref.strip()
    if not ref:
        return None
    if ref.startswith(("http://", "https://", "data:")):
        return ref
    mime = mimetypes.guess_type(ref)[0] or "image/png"
    with open(ref, "rb") as f:
        b64 = base64.b64encode(f.read()).decode("ascii")
    return "data:%s;base64,%s" % (mime, b64)


def build():
    prompt = os.environ["AGNES_PROMPT"]
    fps = float(os.environ.get("AGNES_VIDEO_FPS") or 24)
    duration = float(os.environ.get("AGNES_VIDEO_DURATION") or 5)
    width = int(os.environ.get("AGNES_VIDEO_WIDTH") or 1152)
    height = int(os.environ.get("AGNES_VIDEO_HEIGHT") or 768)
    mode = (os.environ.get("AGNES_VIDEO_MODE") or "").strip()
    negative = (os.environ.get("AGNES_VIDEO_NEGATIVE") or "").strip()
    seed = (os.environ.get("AGNES_VIDEO_SEED") or "").strip()
    image_arg = os.environ.get("AGNES_VIDEO_IMAGE", "")

    nf_env = (os.environ.get("AGNES_VIDEO_NUM_FRAMES") or "").strip()
    if nf_env:
        num_frames = snap_num_frames(int(nf_env) / fps, fps)
    else:
        num_frames = snap_num_frames(duration, fps)

    payload = {
        "model": MODEL,
        "prompt": prompt,
        "width": width,
        "height": height,
        "num_frames": num_frames,
        "frame_rate": int(fps) if fps == int(fps) else fps,
    }
    if negative:
        payload["negative_prompt"] = negative
    if seed:
        payload["seed"] = int(seed)

    images = [r for r in (_resolve_image(x) for x in image_arg.split(",")) if r]
    if not images:
        pass  # text-to-video
    elif len(images) == 1 and mode != "keyframes":
        payload["image"] = images[0]                              # Example 2
    else:
        payload.setdefault("extra_body", {})["image"] = images    # Example 3/4
    if mode:
        payload.setdefault("extra_body", {})["mode"] = mode

    json.dump(payload, sys.stdout)


def _load_resp():
    with open(os.environ["AGNES_RESP_FILE"]) as f:
        return json.load(f)


def parse_create():
    data = _load_resp()
    vid = data.get("video_id") or data.get("task_id") or data.get("id")
    if vid:
        sys.stdout.write("ID:" + str(vid))
    else:
        err = data.get("error", data)
        msg = err.get("message") if isinstance(err, dict) else str(err)
        sys.stdout.write("ERR:" + (msg or json.dumps(err))[:300])


def parse_result():
    data = _load_resp()
    status = data.get("status", "")
    if status == "completed":
        # The final video URL is returned under "remixed_from_video_id"
        # (counter-intuitive field name, per the API docs).
        url = data.get("remixed_from_video_id") or data.get("video_url") or ""
        sys.stdout.write("DONE:" + url)
    elif status == "failed":
        err = data.get("error")
        if isinstance(err, dict):
            msg = err.get("message") or json.dumps(err)
        else:
            msg = str(err) if err else "unknown error"
        sys.stdout.write("FAIL:" + msg[:300])
    else:
        pct = data.get("progress", 0)
        sys.stdout.write("WAIT:%s:%s" % (status or "unknown", pct))


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "build":
        build()
    elif cmd == "parse-create":
        parse_create()
    elif cmd == "parse-result":
        parse_result()
    else:
        sys.stderr.write("usage: _video.py {build|parse-create|parse-result}\n")
        sys.exit(2)


if __name__ == "__main__":
    main()
