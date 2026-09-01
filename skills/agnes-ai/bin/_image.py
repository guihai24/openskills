#!/usr/bin/env python3
"""Agnes image generation: build payload, call API, download result.

All user input arrives via environment variables and is serialized with
json.dump, so prompts containing quotes, braces, backslashes, or newlines
cannot break out of the JSON value.

Subcommands:
  run    - end-to-end: build payload, call API, download image to
           AGNES_OUTPUT_FILE. Prints the output file path on success.
  build  - read AGNES_PROMPT / AGNES_SIZE / AGNES_INPUT_IMAGE from the
           environment and print a request payload (JSON) to stdout.
  parse  - read the API response from AGNES_RESP_FILE and print one of:
             URL:<url>        image is available at <url>
             B64:<path>       image decoded and written to AGNES_OUTPUT_FILE
             ERR:<message>    server/parse error
"""
import sys
import os
import json
import base64
import re
import urllib.request
import urllib.error
import mimetypes

MODEL = "agnes-image-2.1-flash"


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


def _build_payload():
    prompt = os.environ["AGNES_PROMPT"]
    size = os.environ.get("AGNES_SIZE") or "1024x1024"
    input_image = os.environ.get("AGNES_INPUT_IMAGE", "").strip()

    payload = {
        "model": MODEL,
        "prompt": prompt,
        "size": size,
        "extra_body": {"response_format": "url"},
    }

    if input_image:
        if input_image.startswith(("http://", "https://", "data:")):
            img = input_image
        else:
            native_input = _to_native_path(input_image)
            mime = mimetypes.guess_type(native_input)[0] or "image/png"
            with open(native_input, "rb") as f:
                b64 = base64.b64encode(f.read()).decode("ascii")
            img = "data:%s;base64,%s" % (mime, b64)
        payload["extra_body"]["image"] = [img]

    return payload


def _http_post_json(url, payload, api_key, timeout=360):
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


def _http_download(url, out_path, timeout=120):
    """Download a file from URL to out_path."""
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        data = resp.read()
    with open(out_path, "wb") as f:
        f.write(data)
    return out_path


def run():
    """End-to-end: build payload, call API, download image."""
    payload = _build_payload()
    base_url = os.environ.get("AGNES_BASE_URL", "https://apihub.agnes-ai.com")
    api_key = os.environ["AGNES_API_KEY"]
    out_path = os.environ["AGNES_OUTPUT_FILE"]

    resp_data = _http_post_json(
        base_url + "/v1/images/generations", payload, api_key
    )

    items = resp_data.get("data") or []
    if not items:
        err = resp_data.get("error", resp_data)
        msg = err.get("message") if isinstance(err, dict) else str(err)
        print("ERROR: empty response — %s" % msg[:300], file=sys.stderr)
        sys.exit(1)

    item = items[0]
    if item.get("url"):
        _http_download(item["url"], out_path)
        print(out_path)
    elif item.get("b64_json"):
        with open(out_path, "wb") as f:
            f.write(base64.b64decode(item["b64_json"]))
        print(out_path)
    else:
        print("ERROR: no url or b64_json in response", file=sys.stderr)
        sys.exit(1)


def build():
    payload = _build_payload()
    json.dump(payload, sys.stdout)


def parse():
    resp_path = os.environ["AGNES_RESP_FILE"]
    out_path = os.environ.get("AGNES_OUTPUT_FILE", "")
    with open(resp_path) as f:
        data = json.load(f)

    items = data.get("data") or []
    if items and items[0].get("url"):
        sys.stdout.write("URL:" + items[0]["url"])
        return
    if items and items[0].get("b64_json"):
        native_out = _to_native_path(out_path)
        with open(native_out, "wb") as out:
            out.write(base64.b64decode(items[0]["b64_json"]))
        sys.stdout.write("B64:" + native_out)
        return

    err = data.get("error", data)
    if isinstance(err, dict):
        msg = err.get("message") or json.dumps(err)
    else:
        msg = str(err)
    sys.stdout.write("ERR:" + msg[:300])


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "run":
        run()
    elif cmd == "build":
        build()
    elif cmd == "parse":
        parse()
    else:
        sys.stderr.write("usage: _image.py {run|build|parse}\n")
        sys.exit(2)


if __name__ == "__main__":
    main()
