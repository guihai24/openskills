# Agnes AI macOS Compatibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Agnes AI image and video generation work on macOS without regressing Linux or Windows Git Bash support.

**Architecture:** Keep the existing shell and Python entrypoints. Gate shell path conversion on Windows POSIX environments and prefer `cygpath`; gate Python path conversion on `os.name == "nt"`. Add behavior-level regressions and run the existing local mock API integration suite.

**Tech Stack:** Bash 3.2+, Python 3 standard library, `unittest`, local HTTP mock integration tests.

## Global Constraints

- Support macOS Bash 3.2, Linux Bash, and Windows Git Bash/MSYS/Cygwin.
- Preserve existing image/video CLI arguments, Agnes models, payload fields, output naming, and API endpoints.
- Add no third-party runtime dependency; `cygpath` is optional and only used when already supplied by a Windows POSIX environment.
- Make no live or paid Agnes API request during verification.
- Keep the change limited to `skills/agnes-ai` plus design/plan documentation.

---

### Task 1: Add Cross-Platform Path Regression Tests

**Files:**
- Create: `skills/agnes-ai/test/test_native_paths.py`
- Modify: `skills/agnes-ai/test/run.sh:17-110`

**Interfaces:**
- Consumes: `agnes_native_path PATH`, `_image._to_native_path(path)`, and `_video._to_native_path(path)`.
- Produces: portable offline checks for POSIX preservation, Windows drive conversion, and local image encoding.

- [ ] **Step 1: Make the existing local-file fixture portable**

Replace GNU-only temporary-file creation with the already-used portable form:

```bash
tmpimg=$(mktemp); printf 'PNGDATA' > "$tmpimg"
```

- [ ] **Step 2: Add shell behavior tests**

Add checks after the base URL tests. The POSIX check exercises the real host; the Windows check simulates Git Bash at the OS-command boundary and verifies the returned native path:

```bash
check "native path preserves POSIX absolute path" "/Users/test/input.png" \
  "$(bash -c "source '$BIN/lib.sh'; agnes_native_path '/Users/test/input.png'")"

out=$(MSYSTEM=MINGW64 bash -c '
  cygpath() { printf "C:\\\\Users\\\\test\\\\input.png"; }
  export -f cygpath
  source "'"$BIN"'/lib.sh"
  agnes_native_path "/c/Users/test/input.png"
')
check "native path uses Windows converter under Git Bash" \
  'C:\Users\test\input.png' "$out"
```

- [ ] **Step 3: Add Python behavior tests**

Create `skills/agnes-ai/test/test_native_paths.py` using standard-library imports and literal expectations:

```python
import importlib.util
import os
from pathlib import Path
import unittest
from unittest import mock


BIN = Path(__file__).resolve().parents[1] / "bin"


def load(name):
    spec = importlib.util.spec_from_file_location(name, BIN / (name + ".py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class NativePathTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.modules = [load("_image"), load("_video")]

    def test_posix_absolute_paths_are_preserved(self):
        for module in self.modules:
            with self.subTest(module=module.__name__), mock.patch.object(os, "name", "posix"):
                self.assertEqual(module._to_native_path("/Users/test/input.png"), "/Users/test/input.png")
                self.assertEqual(module._to_native_path("/var/tmp/output.png"), "/var/tmp/output.png")

    def test_msys_drive_paths_are_converted_by_windows_python(self):
        for module in self.modules:
            with self.subTest(module=module.__name__), mock.patch.object(os, "name", "nt"):
                self.assertEqual(module._to_native_path("/c/Users/test/input.png"), r"C:\Users\test\input.png")

    def test_urls_and_data_uris_are_preserved(self):
        refs = ["https://example.test/a.png", "data:image/png;base64,AAAA"]
        for module in self.modules:
            for ref in refs:
                with self.subTest(module=module.__name__, ref=ref):
                    self.assertEqual(module._to_native_path(ref), ref)


if __name__ == "__main__":
    unittest.main()
```

Invoke it from `test/run.sh` and feed its exit status into the existing pass/fail counters:

```bash
echo "== Python native path portability =="
if python3 "$SCRIPT_DIR/test_native_paths.py"; then
  ok "Python native path portability"
else
  no "Python native path portability"
fi
```

- [ ] **Step 4: Run the offline suite and verify RED**

Run:

```bash
bash skills/agnes-ai/test/run.sh
```

Expected: non-zero exit. The new POSIX shell test fails because `/Users/...` is converted or Bash 3.2 rejects `${drive^^}`; Python POSIX-path tests fail because both modules convert `/Users/...` and `/var/...` to Windows-shaped paths.

---

### Task 2: Implement Platform-Aware Path Conversion

**Files:**
- Modify: `skills/agnes-ai/bin/lib.sh:86-116`
- Modify: `skills/agnes-ai/bin/_image.py:30-39`
- Modify: `skills/agnes-ai/bin/_video.py:35-44`
- Test: `skills/agnes-ai/test/run.sh`
- Test: `skills/agnes-ai/test/test_native_paths.py`
- Test: `skills/agnes-ai/test/integration.sh`

**Interfaces:**
- Consumes: unchanged path strings passed by image/video shell entrypoints.
- Produces: unchanged paths on macOS/Linux and native Windows paths under Git Bash/MSYS/Cygwin.

- [ ] **Step 1: Gate shell conversion on Windows POSIX environments**

Replace the unconditional drive conversion in `agnes_native_path` with:

```bash
case "${MSYSTEM:-}:${OSTYPE:-}" in
  MINGW*:*|MSYS*:*|CYGWIN*:*|*:msys*|*:cygwin*)
    if command -v cygpath >/dev/null 2>&1; then
      cygpath -w "$p"
      return
    fi
    if [[ "$p" =~ ^/([a-zA-Z])(/.*)?$ ]]; then
      local drive rest
      drive=$(printf '%s' "${BASH_REMATCH[1]}" | tr '[:lower:]' '[:upper:]')
      rest="${BASH_REMATCH[2]:-/}"
      rest="${rest//\//\\}"
      printf '%s:%s' "$drive" "$rest"
      return
    fi
    ;;
esac
printf '%s' "$p"
```

Keep the existing empty, URL/data URI, and already-native Windows path early returns.

- [ ] **Step 2: Gate Python conversion on the native OS**

Apply the same implementation to `_image.py` and `_video.py`:

```python
def _to_native_path(p):
    """Convert Git Bash /c/... paths only when running under Windows Python."""
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
```

- [ ] **Step 3: Run the offline suite and verify GREEN**

Run:

```bash
bash skills/agnes-ai/test/run.sh
```

Expected: exit 0, all existing and new tests pass with zero failures.

- [ ] **Step 4: Run the local mock API integration suite**

Run:

```bash
bash skills/agnes-ai/test/integration.sh
```

Expected: exit 0; text-to-image, local image-to-image, text-to-video, and video polling checks all pass without external network access.

- [ ] **Step 5: Run static and diff checks**

Run:

```bash
bash -n skills/agnes-ai/bin/lib.sh
bash -n skills/agnes-ai/bin/generate-image.sh
bash -n skills/agnes-ai/bin/generate-video.sh
python3 -m py_compile skills/agnes-ai/bin/_image.py skills/agnes-ai/bin/_video.py skills/agnes-ai/test/test_native_paths.py
git diff --check
```

Expected: every command exits 0 with no diagnostics.

- [ ] **Step 6: Commit the compatibility fix**

```bash
git add skills/agnes-ai/bin/lib.sh skills/agnes-ai/bin/_image.py skills/agnes-ai/bin/_video.py skills/agnes-ai/test/run.sh skills/agnes-ai/test/test_native_paths.py docs/superpowers/plans/2026-09-01-agnes-ai-macos-compat.md
git commit -m "fix(agnes-ai): support macOS and Linux paths"
```

---

### Task 3: Review, Install Locally, and Open the Pull Request

**Files:**
- Source: `skills/agnes-ai/**`
- Local install: `/Users/guihaihua/.codex/skills/agnes-ai/**`

**Interfaces:**
- Consumes: verified source-tree skill files and branch `fix/agnes-ai-macos-compat`.
- Produces: a verified local installation and a GitHub pull request targeting `master`.

- [ ] **Step 1: Review the complete branch diff**

```bash
git diff --check master...HEAD
git diff --stat master...HEAD
git status --short --branch
```

Expected: only the scoped Agnes files and design/plan documents appear; the worktree is clean.

- [ ] **Step 2: Copy the verified skill into the local Codex installation**

```bash
install -m 755 skills/agnes-ai/bin/lib.sh /Users/guihaihua/.codex/skills/agnes-ai/bin/lib.sh
install -m 755 skills/agnes-ai/bin/_image.py /Users/guihaihua/.codex/skills/agnes-ai/bin/_image.py
install -m 755 skills/agnes-ai/bin/_video.py /Users/guihaihua/.codex/skills/agnes-ai/bin/_video.py
install -m 755 skills/agnes-ai/test/run.sh /Users/guihaihua/.codex/skills/agnes-ai/test/run.sh
install -m 644 skills/agnes-ai/test/test_native_paths.py /Users/guihaihua/.codex/skills/agnes-ai/test/test_native_paths.py
```

- [ ] **Step 3: Verify the installed copy**

```bash
env CLAUDE_SKILL_DIR=/Users/guihaihua/.codex/skills/agnes-ai bash /Users/guihaihua/.codex/skills/agnes-ai/test/run.sh
bash /Users/guihaihua/.codex/skills/agnes-ai/test/integration.sh
```

Expected: both commands exit 0 with zero failures and no external Agnes API request.

- [ ] **Step 4: Push the branch**

```bash
git push -u origin fix/agnes-ai-macos-compat
```

- [ ] **Step 5: Create the pull request**

```bash
gh pr create --repo guihai24/openskills \
  --base master \
  --head fix/agnes-ai-macos-compat \
  --title "fix(agnes-ai): support macOS and Linux paths" \
  --body "## Summary
- preserve native POSIX paths on macOS and Linux
- retain Windows Git Bash/MSYS/Cygwin conversion through cygpath with a Bash 3-compatible fallback
- add cross-platform path regressions and portable temporary-file setup

## Verification
- bash skills/agnes-ai/test/run.sh
- bash skills/agnes-ai/test/integration.sh
- bash -n and python3 -m py_compile checks

No live or paid Agnes API request was made."
```
