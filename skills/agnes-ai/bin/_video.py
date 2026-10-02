#!/usr/bin/env python3
"""Agnes video generation: build payload, create task, poll, download.

All user input arrives via environment variables and is serialized with
json.dump, so prompts containing quotes, braces, backslashes, or newlines
cannot break out of the JSON value.

Subcommands:
  run    - end-to-end: build payload, create async task, poll until done,
           download video to AGNES_OUTPUT_FILE. Prints output path on success.
  build  - read AGNES_* env vars and print a request payload (JSON) to stdout.
  parse-create  - read AGNES_RESP_FILE (create response) -> "ID:<video_id>" | "ERR:.."
  parse-result  - read AGNES_RESP_FILE (poll response) -> one of:
                    DONE:<url>            completed, final video URL
                    FAIL:<message>        generation failed
                    WAIT:<status>:<pct>   still queued / in_progress

Env vars read by `run`/`build`:
  AGNES_PROMPT (required), AGNES_VIDEO_IMAGE (comma-separated urls/paths),
  AGNES_VIDEO_DURATION (seconds, default 5), AGNES_VIDEO_FPS (24),
  AGNES_VIDEO_WIDTH (1152), AGNES_VIDEO_HEIGHT (768), AGNES_VIDEO_MODE,
  AGNES_VIDEO_NEGATIVE, AGNES_VIDEO_SEED, AGNES_VIDEO_NUM_FRAMES (override),
  AGNES_VIDEO_POLL_INTERVAL (5), AGNES_VIDEO_POLL_MAX (120),
  AGNES_API_KEY (required), AGNES_BASE_URL, AGNES_OUTPUT_FILE (required for run).
"""
import sys
import os
import json
import base64
import re
import time
import urllib.request
import urllib.error
import mimetypes

MODEL = "agnes-video-v2.0"
MAX_FRAMES = 441


def _to_native_path(p):
    """Convert Git Bash /c/... paths only under native Windows Python."""
    if not p:
        return p
    if p.startswith(("http://", "https://", "data:")):
        return p
    if os.name != "nt":
        return p
    match = re.match(r"^/([a-zA-Z])(?:/(.*))?$", p)
    if not match:
        return p
    rest = (match.group(2) or "").replace("/", "\\")
    return "{}:\\{}".format(match.group(1).upper(), rest)


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
    native_ref = _to_native_path(ref)
    mime = mimetypes.guess_type(native_ref)[0] or "image/png"
    with open(native_ref, "rb") as f:
        b64 = base64.b64encode(f.read()).decode("ascii")
    return "data:%s;base64,%s" % (mime, b64)


def _build_payload():
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
        payload["image"] = images[0]
    else:
        payload.setdefault("extra_body", {})["image"] = images
    if mode:
        payload.setdefault("extra_body", {})["mode"] = mode

    return payload


def _http_post_json(url, payload, api_key, timeout=120):
    """POST JSON and return parsed response body."""
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Authorization": "Bearer " + api_key,
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")[:400]
        raise RuntimeError("HTTP %d — %s" % (e.code, body))
    except urllib.error.URLError as e:
        raise RuntimeError("network error — %s" % e.reason)


def _http_get_json(url, api_key, timeout=60):
    """GET JSON and return parsed response body."""
    req = urllib.request.Request(
        url,
        headers={"Authorization": "Bearer " + api_key},
        method="GET",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")[:400]
        raise RuntimeError("HTTP %d — %s" % (e.code, body))
    except urllib.error.URLError as e:
        raise RuntimeError("network error — %s" % e.reason)


def _http_download(url, out_path, timeout=300):
    """Download a file from URL to out_path."""
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        data = resp.read()
    with open(out_path, "wb") as f:
        f.write(data)
    return out_path


def run():
    """End-to-end: build payload, create task, poll, download video."""
    payload = _build_payload()
    base_url = os.environ.get("AGNES_BASE_URL", "https://apihub.agnes-ai.com")
    api_key = os.environ["AGNES_API_KEY"]
    out_path = os.environ["AGNES_OUTPUT_FILE"]
    poll_interval = int(os.environ.get("AGNES_VIDEO_POLL_INTERVAL") or 5)
    poll_max = int(os.environ.get("AGNES_VIDEO_POLL_MAX") or 120)

    # 1) Create the async task
    print("Creating video task...", file=sys.stderr)
    create_resp = _http_post_json(base_url + "/v1/videos", payload, api_key)

    video_id = create_resp.get("video_id") or create_resp.get("task_id") or create_resp.get("id")
    if not video_id:
        err = create_resp.get("error", create_resp)
        msg = err.get("message") if isinstance(err, dict) else str(err)
        print("ERROR: failed to create task — %s" % (msg or json.dumps(create_resp))[:300], file=sys.stderr)
        sys.exit(1)

    print("Task created: %s — polling every %ds (up to %ds)..." % (
        video_id, poll_interval, poll_interval * poll_max), file=sys.stderr)

    # 2) Poll until completed / failed / timeout
    video_url = ""
    for i in range(1, poll_max + 1):
        time.sleep(poll_interval)
        try:
            result = _http_get_json(
                base_url + "/agnesapi?video_id=" + str(video_id), api_key
            )
        except RuntimeError as e:
            print("  poll %d: %s, retrying..." % (i, e), file=sys.stderr)
            continue

        status = result.get("status", "")
        if status == "completed":
            # The final video URL is under "url" (also check legacy fields).
            video_url = result.get("url") or result.get("remixed_from_video_id") or result.get("video_url") or ""
            print("  completed.", file=sys.stderr)
            break
        elif status == "failed":
            err = result.get("error")
            msg = err.get("message") if isinstance(err, dict) else str(err or "unknown error")
            print("ERROR: video generation failed — %s" % msg[:300], file=sys.stderr)
            sys.exit(1)
        else:
            pct = result.get("progress", 0)
            print("  poll %d: %s %s%%" % (i, status or "unknown", pct), file=sys.stderr)

    if not video_url:
        print("ERROR: timed out after %ds. The video may still be processing." % (
            poll_interval * poll_max), file=sys.stderr)
        print("  Retry later: GET %s/agnesapi?video_id=%s -H 'Authorization: Bearer YOUR_API_KEY'" % (
            base_url, video_id), file=sys.stderr)
        sys.exit(1)

    # 3) Download the mp4
    print("Downloading video...", file=sys.stderr)
    _http_download(video_url, out_path)
    print(out_path)


def build():
    payload = _build_payload()
    json.dump(payload, sys.stdout)


def parse_create():
    resp_path = os.environ["AGNES_RESP_FILE"]
    with open(resp_path) as f:
        data = json.load(f)
    vid = data.get("video_id") or data.get("task_id") or data.get("id")
    if vid:
        sys.stdout.write("ID:" + str(vid))
    else:
        err = data.get("error", data)
        msg = err.get("message") if isinstance(err, dict) else str(err)
        sys.stdout.write("ERR:" + (msg or json.dumps(err))[:300])


def parse_result():
    resp_path = os.environ["AGNES_RESP_FILE"]
    with open(resp_path) as f:
        data = json.load(f)
    status = data.get("status", "")
    if status == "completed":
        url = data.get("url") or data.get("remixed_from_video_id") or data.get("video_url") or ""
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
    if cmd == "run":
        run()
    elif cmd == "build":
        build()
    elif cmd == "parse-create":
        parse_create()
    elif cmd == "parse-result":
        parse_result()
    else:
        sys.stderr.write("usage: _video.py {run|build|parse-create|parse-result}\n")
        sys.exit(2)


if __name__ == "__main__":
    main()
