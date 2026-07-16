---
name: go
description: End-to-end feature execution. Pipeline = /squad plan → /grill-me alignment → user approval → /squad implement → mandatory dogfood → /create-pr-new for the PR lifecycle. Use when the user says "/go <description>", "/go linear" (infer Linear ticket from branch/worktree), or wants you to take a feature from spec to merged PR.
category: automation
---

# /go

Take a feature from request → plan → approval → implementation → dogfood → PR.

## Usage

```
/go <feature description>
/go TSH-2500 Add bulk student import
/go fix the trial banner z-index issue
/go linear                          # infer Linear ticket from branch/worktree
```

No-arg → use the immediately preceding user request as the description.

## Linear mode (`/go linear`)

Resolve the description from the current Linear ticket:

1. Infer ticket ID — try in order: current branch, worktree basename (`monorepo.TSH-XXXX`), recent commits (`git log main..HEAD --pretty=%s | head -10`). Match `(?i)(TSH-\d+)`.
2. No ID found → `AskUserQuestion`. Don't guess.
3. Fetch via `mcp__linear__get_issue`. Description = `<TICKET-ID> <title>\n\n<body>`.
4. Linear MCP unavailable → pass just the ticket ID; Phase 2 catches it.

Never update Linear status manually (project automations handle it).

## Pipeline

### Phase 0 — Rename tmux window

If `$TMUX` is set and a ticket ID is known, rename via `$TMUX_PANE` (not bare `rename-window` — drifts off-by-one when the user switched windows):

```
tmux rename-window -t "$TMUX_PANE" "TSH-2648 golden evals"
```

Title ≤30 chars. Skip silently if not in tmux or no ticket ID.

### Phase 1 — Plan via /squad

`/squad <description>` in plan-only mode: Architect first → Backend/Frontend describe (no code yet) → Tester/Reviewer/Dogfooder deferred. Capture scope, files, endpoints/components, test strategy, risks.

### Phase 2 — Grill via /grill-me

Hand the plan to `/grill-me`. One question at a time with a recommended answer; explore the codebase rather than ask when possible. Surface UX gaps, data-model choices, backwards-compat, scope boundaries. Loop until **zero open questions**.

### Phase 3 — Approval gate

Present the final plan (answers folded in). Ask: "Approved to implement? (yes / changes needed)". Any "changes needed" → revise, re-confirm.

### Phase 4 — Implement

Resume `/squad`: Backend → Frontend → Tester → Reviewer → Dogfooder. Stop before commit.

### Phase 5 — Dogfood (MANDATORY)

**Do not skip.** Static checks verify code, not the feature. Until you've exercised the change end-to-end with fresh evidence, you don't know it works.

- **UI changes** → `/dogfood` against the local dev server. Golden path + edge cases (empty, errors, slow network, mobile widths).
- **Other changes** → exercise the surface: curl for APIs, run the script/job for CLI, drive the SDK for libraries. Capture concrete artifacts (response bodies, DB state, logs, screenshots).
- **Squad's Dogfooder ran** → only counts with concrete evidence. Bare "no issues found" → re-run.

Fix P0/P1 findings before Phase 6.

### Phase 6 — PR via /create-pr-new

`/create-pr-new` handles: risk assessment, commit split, push, PR open, CI loop, @claude review loop, merge queue.

## Rules

- **Never skip Phase 2** (grill), **Phase 3** (approval), or **Phase 5** (dogfood — most-skipped step).
- Pass the Phase 3 plan verbatim into `/create-pr-new` Phase 0.
- Mid-pipeline user context → fold in and re-confirm.
- Umbrella skill — delegate to `/squad`, `/grill-me`, `/dogfood`, `/create-pr-new`. Don't duplicate their logic.
