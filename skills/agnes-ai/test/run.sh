#!/usr/bin/env bash
# Mock/unit tests for the agnes-ai skill.
# These run WITHOUT a real API key or network access — they exercise key
# resolution, payload construction, parameter validation, and response parsing.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="$SCRIPT_DIR/../bin"
PASS=0
FAIL=0

ok() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
no() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

# check <desc> <expected> <actual>
check() {
  if [[ "$2" == "$3" ]]; then ok "$1"; else no "$1 -- expected[$2] got[$3]"; fi
}

# ---------------------------------------------------------------------------
echo "== syntax check (bash -n) =="
for f in "$BIN"/*.sh; do
  [[ -e "$f" ]] || continue
  if bash -n "$f" 2>/dev/null; then ok "syntax: $(basename "$f")"; else no "syntax: $(basename "$f")"; fi
done

# ---------------------------------------------------------------------------
echo "== lib.sh: key resolution =="

out=$(AGNES_API_KEY=envkey bash -c "source '$BIN/lib.sh'; agnes_resolve_key")
check "env var wins" "envkey" "$out"

tmpcfg=$(mktemp)
printf 'AGNES_API_KEY=cfgkey\n' > "$tmpcfg"
out=$(env -u AGNES_API_KEY AGNES_CONFIG_FILE="$tmpcfg" bash -c "source '$BIN/lib.sh'; agnes_resolve_key")
check "config file fallback" "cfgkey" "$out"

printf 'AGNES_API_KEY="quoted-key"\n' > "$tmpcfg"
out=$(env -u AGNES_API_KEY AGNES_CONFIG_FILE="$tmpcfg" bash -c "source '$BIN/lib.sh'; agnes_resolve_key")
check "strips double quotes" "quoted-key" "$out"

printf '  AGNES_API_KEY =  spaced-key \n' > "$tmpcfg"
out=$(env -u AGNES_API_KEY AGNES_CONFIG_FILE="$tmpcfg" bash -c "source '$BIN/lib.sh'; agnes_resolve_key")
check "tolerates surrounding whitespace" "spaced-key" "$out"

if env -u AGNES_API_KEY AGNES_CONFIG_FILE=/nonexistent/x bash -c "source '$BIN/lib.sh'; agnes_resolve_key" >/dev/null 2>&1; then
  no "missing key should exit non-zero"
else
  ok "missing key exits non-zero"
fi
rm -f "$tmpcfg"

# ---------------------------------------------------------------------------
echo "== lib.sh: base url & hints =="

check "base_url default" "https://apihub.agnes-ai.com" \
  "$(bash -c "source '$BIN/lib.sh'; agnes_base_url")"
check "base_url override" "http://localhost:9" \
  "$(AGNES_BASE_URL=http://localhost:9 bash -c "source '$BIN/lib.sh'; agnes_base_url")"
check "http_hint 401" "unauthorized — check your AGNES_API_KEY" \
  "$(bash -c "source '$BIN/lib.sh'; agnes_http_hint 401")"
check "http_hint 000" "network error or timeout — check connectivity" \
  "$(bash -c "source '$BIN/lib.sh'; agnes_http_hint 000")"

echo "== lib.sh: native path portability =="
check "native path preserves POSIX absolute path" "/Users/test/input.png" \
  "$(bash -c "source '$BIN/lib.sh'; agnes_native_path '/Users/test/input.png'")"

out=$(MSYSTEM=MINGW64 bash -c '
  cygpath() { printf "%s" "C:\\Users\\test\\input.png"; }
  source "$1"
  agnes_native_path "/c/Users/test/input.png"
' _ "$BIN/lib.sh")
check "native path uses Windows converter under Git Bash" \
  'C:\Users\test\input.png' "$out"

echo "== Python native path portability =="
if python3 "$SCRIPT_DIR/test_native_paths.py"; then
  ok "Python native path portability"
else
  no "Python native path portability"
fi

echo "== _image.py: payload build =="
pj=$(AGNES_PROMPT='a cat' AGNES_SIZE='800x600' python3 "$BIN/_image.py" build)
check "img model" "agnes-image-2.1-flash" \
  "$(printf '%s' "$pj" | python3 -c 'import json,sys;print(json.load(sys.stdin)["model"])')"
check "img size" "800x600" \
  "$(printf '%s' "$pj" | python3 -c 'import json,sys;print(json.load(sys.stdin)["size"])')"
check "img response_format under extra_body" "url" \
  "$(printf '%s' "$pj" | python3 -c 'import json,sys;print(json.load(sys.stdin)["extra_body"]["response_format"])')"
check "img no top-level response_format" "no" \
  "$(printf '%s' "$pj" | python3 -c 'import json,sys;print("yes" if "response_format" in json.load(sys.stdin) else "no")')"
check "img t2i has no image" "no" \
  "$(printf '%s' "$pj" | python3 -c 'import json,sys;print("yes" if "image" in json.load(sys.stdin)["extra_body"] else "no")')"
check "img default size" "1024x1024" \
  "$(AGNES_PROMPT='x' python3 "$BIN/_image.py" build | python3 -c 'import json,sys;print(json.load(sys.stdin)["size"])')"

# Injection safety: a prompt full of JSON metacharacters must survive intact.
inj='evil "}{ \ end
second line'
pj=$(AGNES_PROMPT="$inj" python3 "$BIN/_image.py" build)
check "img injection-safe prompt" "$inj" \
  "$(printf '%s' "$pj" | python3 -c 'import json,sys;print(json.load(sys.stdin)["prompt"])')"

pj=$(AGNES_PROMPT='x' AGNES_INPUT_IMAGE='https://e.com/a.png' python3 "$BIN/_image.py" build)
check "img i2i url under extra_body.image" "https://e.com/a.png" \
  "$(printf '%s' "$pj" | python3 -c 'import json,sys;print(json.load(sys.stdin)["extra_body"]["image"][0])')"

tmpimg=$(mktemp); printf 'PNGDATA' > "$tmpimg"
pj=$(AGNES_PROMPT='x' AGNES_INPUT_IMAGE="$tmpimg" python3 "$BIN/_image.py" build)
check "img i2i local file -> data uri" "data:image/png;base64," \
  "$(printf '%s' "$pj" | python3 -c 'import json,sys;print(json.load(sys.stdin)["extra_body"]["image"][0][:22])')"
rm -f "$tmpimg"

echo "== _image.py: response parse =="
rf=$(mktemp)
printf '{"data":[{"url":"https://z/x.png","b64_json":null}]}' > "$rf"
check "img parse url" "URL:https://z/x.png" "$(AGNES_RESP_FILE="$rf" python3 "$BIN/_image.py" parse)"

of=$(mktemp)
printf '{"data":[{"b64_json":"aGk="}]}' > "$rf"   # base64 of 'hi'
check "img parse b64 marker" "B64:$of" \
  "$(AGNES_RESP_FILE="$rf" AGNES_OUTPUT_FILE="$of" python3 "$BIN/_image.py" parse)"
check "img parse b64 content" "hi" "$(cat "$of")"

printf '{"error":{"message":"bad size"}}' > "$rf"
check "img parse error" "ERR:bad size" "$(AGNES_RESP_FILE="$rf" python3 "$BIN/_image.py" parse)"
rm -f "$rf" "$of"

echo "== _video.py: num_frames snapping (8n+1, <=441) =="
nf() { AGNES_PROMPT=x AGNES_VIDEO_DURATION="$1" AGNES_VIDEO_FPS="${2:-24}" python3 "$BIN/_video.py" build \
  | python3 -c 'import json,sys;print(json.load(sys.stdin)["num_frames"])'; }
check "frames 5s@24 -> 121" "121" "$(nf 5 24)"
check "frames 10s@24 -> 241" "241" "$(nf 10 24)"
check "frames clamp <=441" "441" "$(nf 100 24)"
bad=0
for d in 1 2 3 5 7 10 18 30 60; do
  v=$(nf "$d" 24); (( (v - 1) % 8 == 0 )) || bad=1
done
check "frames always satisfy 8n+1" "0" "$bad"

echo "== _video.py: payload build =="
out=$(AGNES_PROMPT='a cat' python3 "$BIN/_video.py" build)
check "vid model" "agnes-video-v2.0" \
  "$(printf '%s' "$out" | python3 -c 'import json,sys;print(json.load(sys.stdin)["model"])')"
check "vid default width" "1152" \
  "$(printf '%s' "$out" | python3 -c 'import json,sys;print(json.load(sys.stdin)["width"])')"
check "vid t2v has no image" "no" \
  "$(printf '%s' "$out" | python3 -c 'import json,sys;d=json.load(sys.stdin);print("yes" if ("image" in d or "extra_body" in d) else "no")')"

out=$(AGNES_PROMPT='x' AGNES_VIDEO_IMAGE='https://e.com/a.png' python3 "$BIN/_video.py" build)
check "vid i2v -> top-level image string" "https://e.com/a.png" \
  "$(printf '%s' "$out" | python3 -c 'import json,sys;print(json.load(sys.stdin)["image"])')"

out=$(AGNES_PROMPT='x' AGNES_VIDEO_IMAGE='https://e.com/a.png,https://e.com/b.png' python3 "$BIN/_video.py" build)
check "vid multi -> extra_body.image count=2" "2" \
  "$(printf '%s' "$out" | python3 -c 'import json,sys;print(len(json.load(sys.stdin)["extra_body"]["image"]))')"

out=$(AGNES_PROMPT='x' AGNES_VIDEO_IMAGE='https://e.com/a.png,https://e.com/b.png' AGNES_VIDEO_MODE='keyframes' python3 "$BIN/_video.py" build)
check "vid keyframes mode" "keyframes" \
  "$(printf '%s' "$out" | python3 -c 'import json,sys;print(json.load(sys.stdin)["extra_body"]["mode"])')"

out=$(AGNES_PROMPT='x' AGNES_VIDEO_NEGATIVE='blurry' AGNES_VIDEO_SEED='42' python3 "$BIN/_video.py" build)
check "vid negative_prompt" "blurry" \
  "$(printf '%s' "$out" | python3 -c 'import json,sys;print(json.load(sys.stdin)["negative_prompt"])')"
check "vid seed (int)" "42" \
  "$(printf '%s' "$out" | python3 -c 'import json,sys;print(json.load(sys.stdin)["seed"])')"

vinj='boom "}{ \ x
y'
out=$(AGNES_PROMPT="$vinj" python3 "$BIN/_video.py" build)
check "vid injection-safe prompt" "$vinj" \
  "$(printf '%s' "$out" | python3 -c 'import json,sys;print(json.load(sys.stdin)["prompt"])')"

echo "== _video.py: response parse =="
rf=$(mktemp)
printf '{"video_id":"video_abc","task_id":"task_xyz","status":"queued"}' > "$rf"
check "vid parse-create prefers video_id" "ID:video_abc" \
  "$(AGNES_RESP_FILE="$rf" python3 "$BIN/_video.py" parse-create)"
printf '{"task_id":"task_only","status":"queued"}' > "$rf"
check "vid parse-create task_id fallback" "ID:task_only" \
  "$(AGNES_RESP_FILE="$rf" python3 "$BIN/_video.py" parse-create)"
printf '{"status":"completed","progress":100,"remixed_from_video_id":"https://s/x.mp4"}' > "$rf"
check "vid parse-result completed -> url" "DONE:https://s/x.mp4" \
  "$(AGNES_RESP_FILE="$rf" python3 "$BIN/_video.py" parse-result)"
printf '{"status":"in_progress","progress":42}' > "$rf"
check "vid parse-result wait" "WAIT:in_progress:42" \
  "$(AGNES_RESP_FILE="$rf" python3 "$BIN/_video.py" parse-result)"
printf '{"status":"failed","error":{"message":"oops"}}' > "$rf"
check "vid parse-result failed" "FAIL:oops" \
  "$(AGNES_RESP_FILE="$rf" python3 "$BIN/_video.py" parse-result)"
rm -f "$rf"

echo
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
