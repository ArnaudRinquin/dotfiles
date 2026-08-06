---
name: slack-ta
description: Worktree job launched from a Slack @mention via slack-to-laptop. Use when the prompt starts with /slack-ta. Streams progress back to the Slack thread through the slack-stream MCP (thinking_step / append_text / finish), then runs the actual task via /go.
---

# slack-ta — Slack-driven worktree job

You were spawned by a Slack mention. Args: `[threadTs:<token>] <task description>`.

Extract `<token>` — it identifies your Slack stream. Pass it as `threadTs` to EVERY slack-stream MCP tool call. The MCP is `slack-stream` (http://127.0.0.1:8365/mcp).

## Protocol

0. Rename tmux window (same convention as /go Phase 0): if `$TMUX` is set, `tmux rename-window -t "$TMUX_PANE" "slack: <short task slug>"` (≤30 chars, e.g. `slack: filter prog templates`). Use the ticket ID instead if the task names one. Skip silently if not in tmux.
1. Immediately, in this order:
   - `register_job({threadTs, cwd: <pwd>, tmuxPane: $TMUX_PANE, pid: <your pid>, branch: <git branch>})` — this is how follow-up Slack mentions get routed INTO this session instead of spawning a duplicate job. Never skip it.
   - `thinking_step({threadTs, title: "Understanding the task", status: "in_progress"})`.
2. Run the task: treat `<task description>` as `/go <task description>` (full pipeline). Skip `/grill-me` and user-approval gates — nobody is watching the terminal; make sensible calls and note them in the final summary.
3. At each real milestone (plan done, implementation, tests, PR), update the checklist: mark the previous step `complete`, add the next as `in_progress`. Short titles ("Planning", "Implementing", "Running tests", "Opening PR"). Use `set_status` for the grey "is …" line during long stretches.
4. On completion: put the concise final report — what changed, test results, PR link — in `finish({threadTs, markdown})`. It's posted as its OWN reply (the user's one notification); do NOT `append_text` the summary.
5. ALWAYS `finish` as your very last act — also on failure (mark the failing step `status: "error"`, put what went wrong in the finish markdown). A stream left open sticks in Slack until swept.

## Follow-ups

Messages starting with `[slack follow-up threadTs:<token>]` are the Slack user replying in your thread — the bridge typed it into your session. Treat it as user steering:

- Mid-work: fold it into the current task; acknowledge with a `thinking_step` so the thread shows it landed.
- After you finished: it's a new turn — the bridge already reopened a stream on the same `threadTs`; stream progress as usual and ALWAYS `finish` again at the end.
- The token in the follow-up is the same `threadTs` you already use.

## Rules

- Never guess `threadTs` — if the token is missing from your prompt, do the work but skip all streaming calls.
- If a streaming call errors with "no live stream", the stream was swept (job took too long) — continue the work, stop streaming.
- Keep Slack output tight: the checklist tells the story; `append_text` only for genuinely important mid-course findings — the final summary goes in `finish(markdown)`.
