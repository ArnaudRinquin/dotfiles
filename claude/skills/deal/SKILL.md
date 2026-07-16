---
name: deal
description: Deal my top-N Linear cards (default 3) into parallel worktree sessions via /wtc, one batch confirmation
disable-model-invocation: true
---

# /deal [N]

Deal the top N cards off my Linear deck into parallel worktree+tmux+claude sessions. `N` = first argument, default 3.

## Steps

1. **Draw the deck** — Linear MCP `list_issues`: assignee = me (resolve my user UUID via `list_users` with my email first — slug/name filters silently return empty), unstarted states (Todo/Backlog). Done when the raw candidate list is in hand.

2. **Rank & discard** — order by priority (Urgent → Low), then due date, then oldest. Discard cards that are:
   - blocked / on hold (label, or blocking relation to an open issue)
   - already dealt: branch/worktree exists (`wt list --branches | grep -i <branch>`) or an open PR references the ID (`gh pr list --search "<TSH-XXXX>"`)

3. **Table the hand** — show top N as a table: identifier, title, priority, one-line why-now. Confirm via `AskUserQuestion` (multiSelect, all preselected); the picked set is final. Fewer than N candidates → deal what's there; zero → say so and stop.

4. **Deal** — for each confirmed card, run `/wtc` existing-ticket mode (`~/.claude/skills/wtc/SKILL.md`): `get_issue` → `branchName` → `g wtc <branchName> '/go linear'` backgrounded to `/tmp/wtc-<TSH-XXXX>.log`. The step-3 batch confirm replaces wtc's per-ticket confirm; everything else in wtc (branch-exists pre-check, must-be-in-tmux, `-c` hardcoded) still applies. Sequential — verify each `g wtc` starts cleanly (log shows worktree creation) before dealing the next.

5. **Report** — table: card, branch, log path, status. Done when every confirmed card has a spawned session or a stated failure + its log tail.
