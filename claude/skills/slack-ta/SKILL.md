---
name: slack-ta
description: Worktree job launched from a Slack @mention via slack-to-laptop. Use when the prompt starts with /slack-ta. Streams progress back to the Slack thread through the slack-stream MCP (thinking_step / append_text / finish), then runs the actual task via /go.
---

# slack-ta — Slack-driven worktree job

You were spawned by a Slack mention. Args: `[threadTs:<token>] <task description>`.

Extract `<token>` — it identifies your Slack stream. Pass it as `threadTs` to EVERY slack-stream MCP tool call. The MCP is `slack-stream` (http://127.0.0.1:8365/mcp).

## Protocol

0. Rename tmux window (same convention as /go Phase 0): if `$TMUX` is set, `tmux rename-window -t "$TMUX_PANE" "slack: <short task slug>"` (≤30 chars, e.g. `slack: filter prog templates`). Use the ticket ID instead if the task names one. Skip silently if not in tmux.
1. Immediately: `thinking_step({threadTs, title: "Understanding the task", status: "in_progress"})`.
2. Run the task: treat `<task description>` as `/go <task description>` (full pipeline). Skip `/grill-me` and user-approval gates — nobody is watching the terminal; make sensible calls and note them in the final summary.
3. At each real milestone (plan done, implementation, tests, PR), update the checklist: mark the previous step `complete`, add the next as `in_progress`. Short titles ("Planning", "Implementing", "Running tests", "Opening PR"). Use `set_status` for the grey "is …" line during long stretches.
4. On completion: `append_text` with a concise summary — what changed, test results, PR link.
5. ALWAYS `finish({threadTs})` as your very last act — also on failure (mark the failing step `status: "error"`, append what went wrong, then finish). A stream left open sticks in Slack until swept.

## Rules

- Never guess `threadTs` — if the token is missing from your prompt, do the work but skip all streaming calls.
- If a streaming call errors with "no live stream", the stream was swept (job took too long) — continue the work, stop streaming.
- Keep Slack output tight: the checklist tells the story; `append_text` only for the final summary and genuinely important mid-course findings.
