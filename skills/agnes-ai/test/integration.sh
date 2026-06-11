#!/usr/bin/env bash
# Integration test: runs the REAL bin/ scripts against a local mock Agnes API.
# Exercises the full bash orchestration (curl, async polling, download) without
# a real API key or external network. Requires python3 (mock server) + curl.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="$SCRIPT_DIR/../bin"
PASS=0
FAIL=0
ok() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
no() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

WORK=$(mktemp -d)
SERVER_PY="$WORK/mock_server.py"
PORT_FILE="$WORK/port"

cat > "$SERVER_PY" <<'PYEOF'
import http.server, json, sys
from urllib.parse import urlparse

poll = {"n": 0}

class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _base(self):
        return "http://" + self.headers.get("Host", "127.0.0.1")

    def _send(self, code, body=b"", ctype="application/json"):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if body:
            self.wfile.write(body)

    def _json(self, code, obj):
        self._send(code, json.dumps(obj).encode())

    def do_POST(self):
        ln = int(self.headers.get("Content-Length", 0) or 0)
        self.rfile.read(ln)
        p = urlparse(self.path).path
        if p == "/v1/images/generations":
            self._json(200, {"created": 1, "data": [
                {"url": self._base() + "/fake.png", "b64_json": None}]})
        elif p == "/v1/videos":
            self._json(200, {"id": "task_t", "task_id": "task_t",
                             "video_id": "video_t", "status": "queued", "progress": 0})
        else:
            self._json(404, {"error": {"message": "not found"}})

    def do_GET(self):
        p = urlparse(self.path).path
        if p == "/agnesapi":
            poll["n"] += 1
            if poll["n"] < 2:
                self._json(200, {"video_id": "video_t", "status": "in_progress", "progress": 50})
            else:
                self._json(200, {"video_id": "video_t", "status": "completed", "progress": 100,
                                 "remixed_from_video_id": self._base() + "/fake.mp4"})
        elif p == "/fake.png":
            self._send(200, b"\x89PNG\r\n\x1a\nFAKE-PNG-BYTES", ctype="image/png")
        elif p == "/fake.mp4":
            self._send(200, b"\x00\x00\x00\x18ftypmp42FAKE-MP4-BYTES", ctype="video/mp4")
        else:
            self._json(404, {"error": {"message": "not found"}})

srv = http.server.HTTPServer(("127.0.0.1", 0), H)
with open(sys.argv[1], "w") as f:
    f.write(str(srv.server_address[1]))
srv.serve_forever()
PYEOF

python3 "$SERVER_PY" "$PORT_FILE" &
SRV=$!
trap 'kill "$SRV" 2>/dev/null; rm -rf "$WORK"' EXIT

for _ in $(seq 1 40); do [[ -s "$PORT_FILE" ]] && break; sleep 0.1; done
PORT=$(cat "$PORT_FILE" 2>/dev/null || echo "")
if [[ -z "$PORT" ]]; then echo "FAIL: mock server did not start"; exit 1; fi
for _ in $(seq 1 30); do curl -s "http://127.0.0.1:$PORT/health" >/dev/null 2>&1 && break; sleep 0.1; done

export AGNES_BASE_URL="http://127.0.0.1:$PORT"
export AGNES_API_KEY="test-key"
export AGNES_OUTPUT_DIR="$WORK/out"
export AGNES_VIDEO_POLL_INTERVAL=1
export AGNES_VIDEO_POLL_MAX=5

echo "== integration: text-to-image (curl -> parse -> download) =="
IMG=$(bash "$BIN/generate-image.sh" "a test prompt" 2>"$WORK/img.err" || true)
if [[ -n "$IMG" && -s "$IMG" ]]; then ok "image saved: $(basename "$IMG") ($(wc -c < "$IMG" | tr -d ' ') bytes)"; else no "image not saved"; sed 's/^/    /' "$WORK/img.err"; fi

echo "== integration: image-to-image (local file -> data URI) =="
printf 'PNG-SEED' > "$WORK/in.png"
IMG2=$(bash "$BIN/generate-image.sh" "edit this" 1024x768 "$WORK/in.png" 2>"$WORK/img2.err" || true)
if [[ -n "$IMG2" && -s "$IMG2" ]]; then ok "image-to-image saved"; else no "image-to-image failed"; sed 's/^/    /' "$WORK/img2.err"; fi

echo "== integration: text-to-video (create -> poll -> download) =="
VID=$(bash "$BIN/generate-video.sh" "a test video" "" 5 2>"$WORK/vid.err" || true)
if [[ -n "$VID" && -s "$VID" ]]; then ok "video saved: $(basename "$VID")"; else no "video not saved"; sed 's/^/    /' "$WORK/vid.err"; fi
if grep -q "in_progress" "$WORK/vid.err"; then ok "polled through in_progress -> completed"; else no "did not observe in_progress poll"; fi

echo
echo "Integration: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
