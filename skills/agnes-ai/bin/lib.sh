#!/usr/bin/env bash
# Shared helpers for the agnes-ai skill (image + video generation).
#
# This file is meant to be sourced, not executed directly. It defines
# functions only and intentionally does NOT set shell options, so the
# sourcing script controls `set -euo pipefail`.
#
# Public functions:
#   agnes_require_cmds        - verify curl + python3 are available
#   agnes_resolve_key         - print the API key (env > config file) or fail
#   agnes_base_url            - print the API base URL (override with AGNES_BASE_URL)
#   agnes_output_dir          - print (and create) the output directory
#   agnes_http_hint <code>    - print a human-readable hint for an HTTP status

# Verify required external commands exist. Returns 1 (with a message) if not.
agnes_require_cmds() {
  local missing=0 c
  for c in curl python3; do
    if ! command -v "$c" >/dev/null 2>&1; then
      echo "ERROR: required command '$c' not found in PATH" >&2
      missing=1
    fi
  done
  return "$missing"
}

# Resolve the Agnes AI API key.
# Order: $AGNES_API_KEY env var, then ~/.config/agnes-ai/config (KEY=value).
# Prints the key to stdout on success; prints guidance to stderr and returns 1
# when no key is found.
agnes_resolve_key() {
  if [[ -n "${AGNES_API_KEY:-}" ]]; then
    printf '%s' "$AGNES_API_KEY"
    return 0
  fi

  local cfg="${AGNES_CONFIG_FILE:-$HOME/.config/agnes-ai/config}"
  if [[ -f "$cfg" ]]; then
    # Extract KEY=value without sourcing the file (avoids executing its content).
    # Strips surrounding whitespace and matching single/double quotes.
    local key
    key=$(grep -E '^[[:space:]]*AGNES_API_KEY[[:space:]]*=' "$cfg" 2>/dev/null \
      | head -1 \
      | sed -E 's/^[^=]*=[[:space:]]*//; s/[[:space:]]*$//; s/^"(.*)"$/\1/; s/^'\''(.*)'\''$/\1/')
    if [[ -n "$key" ]]; then
      printf '%s' "$key"
      return 0
    fi
  fi

  cat >&2 <<'EOF'
ERROR: Agnes AI API key not found.

Configure it in one of two ways:
  1) Environment variable (recommended):
       export AGNES_API_KEY="your-key"
  2) Config file ~/.config/agnes-ai/config (chmod 600):
       AGNES_API_KEY=your-key

Get an API key from https://agnes-ai.com (API Platform).
EOF
  return 1
}

# Base URL for the Agnes AI API. Override with AGNES_BASE_URL (useful for tests).
agnes_base_url() {
  printf '%s' "${AGNES_BASE_URL:-https://apihub.agnes-ai.com}"
}

# Output directory for generated files. Override with AGNES_OUTPUT_DIR.
# Creates the directory if it does not exist, then prints its path.
agnes_output_dir() {
  local d="${AGNES_OUTPUT_DIR:-$HOME/agnes-output}"
  mkdir -p "$d"
  printf '%s' "$d"
}

# Map an HTTP status code (or curl's 000) to a short human-readable hint.
agnes_http_hint() {
  case "$1" in
    400) echo "invalid request — check parameters" ;;
    401) echo "unauthorized — check your AGNES_API_KEY" ;;
    403) echo "forbidden — key lacks access" ;;
    404) echo "not found — task/video/endpoint missing" ;;
    429) echo "rate limited — try again later" ;;
    500) echo "server error — try again later" ;;
    503) echo "service busy — try again later" ;;
    000) echo "network error or timeout — check connectivity" ;;
    *)   echo "unexpected HTTP status $1" ;;
  esac
}
