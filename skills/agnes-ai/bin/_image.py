#!/usr/bin/env python3
"""Payload builder and response parser for Agnes image generation.

All user input arrives via environment variables (never argv/string
interpolation) and is serialized with json.dump, so prompts containing
quotes, braces, backslashes, or newlines cannot break out of the JSON value.

Subcommands:
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
import mimetypes

MODEL = "agnes-image-2.1-flash"


def build():
    prompt = os.environ["AGNES_PROMPT"]
    size = os.environ.get("AGNES_SIZE") or "1024x1024"
    input_image = os.environ.get("AGNES_INPUT_IMAGE", "").strip()

    payload = {
        "model": MODEL,
        "prompt": prompt,
        "size": size,
        # response_format must live under extra_body, never at the top level.
        "extra_body": {"response_format": "url"},
    }

    if input_image:
        # Image-to-image. Per the official call examples the input image goes
        # under extra_body.image (the prose docs also mention a top-level
        # "image" array — see README "Known doc discrepancy").
        if input_image.startswith(("http://", "https://", "data:")):
            img = input_image
        else:
            mime = mimetypes.guess_type(input_image)[0] or "image/png"
            with open(input_image, "rb") as f:
                b64 = base64.b64encode(f.read()).decode("ascii")
            img = "data:%s;base64,%s" % (mime, b64)
        payload["extra_body"]["image"] = [img]

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
        with open(out_path, "wb") as out:
            out.write(base64.b64decode(items[0]["b64_json"]))
        sys.stdout.write("B64:" + out_path)
        return

    err = data.get("error", data)
    if isinstance(err, dict):
        msg = err.get("message") or json.dumps(err)
    else:
        msg = str(err)
    sys.stdout.write("ERR:" + msg[:300])


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "build":
        build()
    elif cmd == "parse":
        parse()
    else:
        sys.stderr.write("usage: _image.py {build|parse}\n")
        sys.exit(2)


if __name__ == "__main__":
    main()
