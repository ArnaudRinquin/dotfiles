---
name: pr-decisions
description: Post a human-sized review on a PR — 5 to 7 inline comments, one per structuring decision (data model, API shape, where logic lives, deliberate trade-offs), each saying what was decided, why, what was rejected and what the human reviewer should check. Use when the user says "/pr-decisions [PR#]", wants a PR made reviewable by a human, or a MEDIUM/HIGH risk PR is about to get a human reviewer.
category: version-control-git
allowed-tools: Bash(gh *), Bash(git *), Bash(python3 *), Read, Write
---

# /pr-decisions

Bot reviews (claude, brutus) are agent-to-agent chatter: long, flat, unreadable for a human. This skill posts the opposite — a short guided tour of the few choices that shape the PR, anchored on the lines where they live. A human reads 5–7 comments and knows what to challenge.

Not a bug hunt. Correctness findings belong to `/code-review` or the review bots; don't mix them in.

## Input

`/pr-decisions [PR#]` — no arg → current branch's PR: `gh pr view --json number --jq .number`.

## Steps

1. **Read** — `gh pr view <N> --json title,body,headRefOid,files` + `gh pr diff <N>`. If this session authored the PR, the approved plan (e.g. `/go` Phase 3) is the best source for the *why*.
2. **Pick 5–7 decisions** — choices a reviewer could reasonably have made differently:
   - data model / schema / migration shape
   - API contract (endpoint, payload, error shape)
   - where logic lives (backend vs frontend, which package/layer)
   - new abstraction or deliberate non-abstraction
   - trade-offs: perf vs simplicity, scope cut, flag, backwards-compat
   - anything surprising a reader would stop on

   Skip mechanical changes (renames, generated code, i18n keys, test boilerplate). Fewer than 5 real ones → post fewer; never pad.
3. **Anchor** each on the single most representative line — a `+` or context line inside a hunk of `gh pr diff`, on the new-file side. A line outside any hunk makes the API return 422.
4. **Write** each comment in English, ≤6 lines:

   ```
   **Decision:** <what was chosen, one line>
   **Why:** <reason — constraint, data, prior incident>
   **Rejected:** <the alternative and why not>
   **Check:** <the one thing the human should verify or push back on>
   ```

5. **Post as ONE review** (one notification, not 7). Write the payload to the scratchpad, then:

   ```json
   {
     "commit_id": "<headRefOid>",
     "event": "COMMENT",
     "body": "Structuring decisions in this PR, for human review (N comments). Bugs are out of scope here.",
     "comments": [{ "path": "services/api/...", "line": 42, "side": "RIGHT", "body": "..." }]
   }
   ```

   Validate anchors first — `python3 ~/.claude/skills/pr-decisions/check-anchors.py <N> <payload.json>` — each `ok` line echoes the anchored code; confirm it's the line you meant. Then:

   `gh api repos/{owner}/{repo}/pulls/<N>/reviews --method POST --input <payload.json>`

   On 422, the error names the bad comment → re-anchor that one line, retry once.
6. **Report** — review URL + the one-line decision list.

## Rules

- `event: COMMENT` only — never APPROVE / REQUEST_CHANGES.
- Comments English; French domain nouns stay French.
- Never `#N` in comment bodies (GitHub autolinks). Say "decision 3".
- Don't restate the diff — the reader sees the code next to the comment.
