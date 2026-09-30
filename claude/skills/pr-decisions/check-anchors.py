#!/usr/bin/env python3
"""Check a review payload's comment anchors against a PR diff.

Usage: python3 check-anchors.py <PR#> <payload.json>
Exit 0 when every comments[].path/line sits on the new side of a hunk; else
prints the bad ones and exits 1 (the reviews API would 422 on them).
"""
import json
import re
import subprocess
import sys

pr, payload_path = sys.argv[1], sys.argv[2]
diff = subprocess.run(
    ["gh", "pr", "diff", pr, "--patch=false"], capture_output=True, text=True, check=True
).stdout

valid = {}
path, line = None, 0
for raw in diff.splitlines():
    if raw.startswith("+++ "):
        path = raw[6:].strip() if raw.startswith("+++ b/") else None
        continue
    m = re.match(r"@@ -\d+(?:,\d+)? \+(\d+)", raw)
    if m:
        line = int(m.group(1))
        continue
    if path and raw[:1] in (" ", "+"):
        valid.setdefault(path, {})[line] = raw[1:]
        line += 1

payload = json.load(open(payload_path))
bad = 0
for c in payload.get("comments", []):
    text = valid.get(c["path"], {}).get(c["line"])
    if text is None:
        bad += 1
        print(f"BAD  {c['path']}:{c['line']} not on the new side of any hunk")
    else:
        print(f"ok   {c['path']}:{c['line']}  {text.strip()[:80]}")
sys.exit(1 if bad else 0)
