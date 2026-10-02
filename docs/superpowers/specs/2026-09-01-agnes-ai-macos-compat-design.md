# Agnes AI macOS Compatibility Design

## Goal

Make the `agnes-ai` image and video entrypoints work on macOS while preserving
their existing Linux and Windows Git Bash behavior and leaving the Agnes API
payloads unchanged.

## Root Cause

The Windows compatibility layer treats every absolute POSIX path beginning
with a letter as a Windows drive path. On macOS this converts paths such as
`/Users/...` and `/var/...` into invalid paths such as `U:\\sers/...` and
`V:\\ar/...`. The shell helper also uses Bash 4 uppercase expansion even though
macOS ships Bash 3.2. The offline test suite additionally uses GNU-only
`mktemp --suffix` syntax.

## Design

Path conversion will be platform-aware:

- Shell entrypoints will leave paths unchanged on POSIX systems. In Windows
  POSIX shells they will use `cygpath -w`, the native path conversion utility
  supplied by Git Bash, MSYS2, and Cygwin.
- Python will only convert `/c/...`-style paths when `os.name == "nt"`; macOS
  and Linux paths will pass through unchanged.
- Image and video API payloads, models, output naming, and command-line
  interfaces will not change.

## Error Handling

If a Windows POSIX environment requires path conversion but `cygpath` is not
available, the shell helper will retain a portable fallback that avoids Bash 4
syntax. Existing command and API error handling remains unchanged.

## Testing

The offline suite will use portable `mktemp` syntax and add regressions that:

- preserve `/Users/...`, `/var/...`, and `/tmp/...` paths on POSIX systems;
- keep URLs and data URIs unchanged;
- retain Windows `/c/...` conversion behavior through a simulated Windows
  environment;
- exercise the real image and video entrypoint path setup without contacting
  the Agnes API;
- pass all existing payload and response parsing tests.

No live or paid API request is required for this compatibility fix.

## Delivery

The implementation, regression tests, and this design document will be
committed on `fix/agnes-ai-macos-compat` and proposed to `master` in one pull
request. After verification, the corrected skill files will also be copied to
the local installed skill directory and its offline suite rerun there.
