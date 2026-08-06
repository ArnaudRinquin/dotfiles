---
name: deal
description: Deal my top-N cards (default 3) from Linear, Sentry, or Datadog alerts into parallel worktree sessions via /spawn, one batch confirmation
disable-model-invocation: true
---

# /deal [N] [source]

Deal the top N cards off a deck into parallel worktree+tmux+claude sessions. `N` = first numeric argument, default 3. `source` = `linear` (default) | `sentry` | `datadog`.

## Steps

1. **Draw the deck** — done when the raw candidate list is in hand.
   - **linear**: Linear MCP, my issues in unstarted states (Todo/Backlog). Filter assignee by my user UUID resolved from my email — slug/name filters silently return empty.
   - **sentry**: Sentry MCP — org `teetsh-2` (region `https://us.sentry.io`), projects `teetshapi`, `teetsh-front`, `website`, unresolved, recent window. Skip known noise per the monorepo firefighter skill's `references/sources.md` skip patterns.
   - **datadog**: Datadog MCP — `get_monitors` with `groupStates: ["alert", "warn"]`. Cross off muted ones via `list_downtimes` (active downtime = not a card). Also glance at `list_incidents` — an active incident outranks any monitor.

2. **Rank & discard**
   - **linear**: order by priority (Urgent → Low), then due date, then oldest. Discard cards that are:
     - blocked / on hold (label, or blocking relation to an open issue)
     - already dealt: branch/worktree exists (`wt list --branches | grep -i <branch>`) or an open PR references the ID (`gh pr list --search "<TSH-XXXX>"`)
   - **sentry**: order by users affected desc, then event count, then recency. Discard issues that are:
     - already dealt: open PR mentions the short ID (`gh pr list --search "<SHORT-ID>"`) or a `sentry-<shortid>*` branch/worktree exists
     - already tracked by an open Linear ticket (mentioned in the Sentry issue or found via a quick Linear search on the error title)
   - **datadog**: order by state (alert → warn), then duration in state (longest-firing first). Discard monitors that are:
     - already dealt: a `dd-<monitor-id>*` branch/worktree exists or an open PR mentions the monitor ID/name
     - already tracked by an open Linear ticket (quick Linear search on the monitor name)
     - not actionable from the repo (pure infra/host alerts with no code path — note them in the report instead of dealing)

3. **Table the hand** — show top N as a table: identifier linked to the issue (`[TSH-XXXX](linear url)` / `[SHORT-ID](sentry url)` / `[monitor-id](datadog monitor url)`) so details are one click away, title, priority/users-affected/alert-state, one-line why-now. Confirm via `AskUserQuestion` (multiSelect, all preselected); the picked set is final. Fewer than N candidates → deal what's there; zero → say so and stop.

4. **Deal** — for each confirmed card, spawn per the `/spawn` skill; the step-3 batch confirm replaces spawn's per-ticket confirm, everything else in spawn still applies. Sequential — verify each `g wtc` starts cleanly (log shows worktree creation) before dealing the next.
   - **linear**: spawn existing-ticket mode: fetch the issue's `branchName` → `g wtc <branchName> '/go linear'` backgrounded to `/tmp/wtc-<TSH-XXXX>.log`.
   - **sentry**: spawn `--no-linear` mode — **no ticket** (an unshipped fix would leave it dangling). Branch `sentry-<shortid>-<slug>` (~40 chars). Prompt = `Fix this Sentry issue: <url> — <title>. Diagnose the root cause first (rule out non-code causes: flag, config, data, external service), then fix and open a PR.` Run `g wtc <branch> '<prompt>'` backgrounded to `/tmp/wtc-<shortid>.log`.
   - **datadog**: spawn `--no-linear` mode — **no ticket**. Branch `dd-<monitor-id>-<slug>` (~40 chars). Prompt = `Investigate this firing Datadog monitor: <monitor url> — <name>. Use the Datadog MCP (logs, metrics, traces) to diagnose the root cause first. If it's a code bug, fix it and open a PR; if it's infra/config/threshold noise, report findings and the recommended action instead of forcing a code change.` Run `g wtc <branch> '<prompt>'` backgrounded to `/tmp/wtc-dd-<monitor-id>.log`.

5. **Report** — table: card, branch, log path, status. Done when every confirmed card has a spawned session or a stated failure + its log tail.
