---
name: deal
description: Deal my top-N cards (default 3) from Linear or Sentry into parallel worktree sessions via /wtc, one batch confirmation
disable-model-invocation: true
---

# /deal [N] [source]

Deal the top N cards off a deck into parallel worktree+tmux+claude sessions. `N` = first numeric argument, default 3. `source` = `linear` (default) | `sentry`.

## Steps

1. **Draw the deck** — done when the raw candidate list is in hand.
   - **linear**: Linear MCP, my issues in unstarted states (Todo/Backlog). Filter assignee by my user UUID resolved from my email — slug/name filters silently return empty.
   - **sentry**: Sentry MCP — org `teetsh-2` (region `https://us.sentry.io`), projects `teetshapi`, `teetsh-front`, `website`, unresolved, recent window. Skip known noise per the monorepo firefighter skill's `references/sources.md` skip patterns.

2. **Rank & discard**
   - **linear**: order by priority (Urgent → Low), then due date, then oldest. Discard cards that are:
     - blocked / on hold (label, or blocking relation to an open issue)
     - already dealt: branch/worktree exists (`wt list --branches | grep -i <branch>`) or an open PR references the ID (`gh pr list --search "<TSH-XXXX>"`)
   - **sentry**: order by users affected desc, then event count, then recency. Discard issues that are:
     - already dealt: open PR mentions the short ID (`gh pr list --search "<SHORT-ID>"`) or a `sentry-<shortid>*` branch/worktree exists
     - already tracked by an open Linear ticket (mentioned in the Sentry issue or found via a quick Linear search on the error title)

3. **Table the hand** — show top N as a table: identifier linked to the issue (`[TSH-XXXX](linear url)` / `[SHORT-ID](sentry url)`) so details are one click away, title, priority/users-affected, one-line why-now. Confirm via `AskUserQuestion` (multiSelect, all preselected); the picked set is final. Fewer than N candidates → deal what's there; zero → say so and stop.

4. **Deal** — for each confirmed card, spawn per the `/wtc` skill; the step-3 batch confirm replaces wtc's per-ticket confirm, everything else in wtc still applies. Sequential — verify each `g wtc` starts cleanly (log shows worktree creation) before dealing the next.
   - **linear**: wtc existing-ticket mode: fetch the issue's `branchName` → `g wtc <branchName> '/go linear'` backgrounded to `/tmp/wtc-<TSH-XXXX>.log`.
   - **sentry**: wtc `--no-linear` mode — **no ticket** (an unshipped fix would leave it dangling). Branch `sentry-<shortid>-<slug>` (~40 chars). Prompt = `Fix this Sentry issue: <url> — <title>. Diagnose the root cause first (rule out non-code causes: flag, config, data, external service), then fix and open a PR.` Run `g wtc <branch> '<prompt>'` backgrounded to `/tmp/wtc-<shortid>.log`.

5. **Report** — table: card, branch, log path, status. Done when every confirmed card has a spawned session or a stated failure + its log tail.
