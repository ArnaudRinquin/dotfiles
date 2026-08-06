---
name: go
description: End-to-end feature execution — request to merged PR via a sub-agent pipeline with human gates. Use when the user says "/go <description>", "/go linear" (infer the Linear ticket from branch/worktree), or wants a feature taken from spec to PR. Reached by /slack-ta and /deal-spawned sessions.
category: automation
---

# /go

Take a feature from request → plan → approval → implementation → review → QA → dogfood → PR. Sub-agent briefs live in [agents.md](agents.md) — read it when a phase spawns an agent.

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
4. Linear MCP unavailable → pass just the ticket ID; the grill phase catches it.

Never update Linear status manually (project automations handle it).

## Human gates 🧑

Three moments belong to Arnaud, not the agents. Agents do the legwork first; the gate only closes on his input:

- **Phase 2 — Grill**: agents surface the questions, Arnaud answers them.
- **Phase 3 — Approval**: explicit go/no-go on the final plan.
- **Phase 8 — Dogfood**: the agent dogfoods first, then Arnaud is invited to try the feature himself before the PR opens.

## Pipeline

### Phase 0 — Rename tmux window

If `$TMUX` is set and a ticket ID is known, rename via `$TMUX_PANE` (not bare `rename-window` — drifts off-by-one when the user switched windows):

```
tmux rename-window -t "$TMUX_PANE" "TSH-2648 golden evals"
```

Title ≤20 chars. Skip silently if not in tmux or no ticket ID.

### Phase 1 — Plan

1. Detect feature type from the description (the Architect may override after reading code): API/Go/database/migrations → Backend; components/pages/UI/React/styling → Frontend; unclear → full-stack.
2. Spawn the **Architect** ([agents.md](agents.md)) → context brief.
3. Draft the plan: scope, files, endpoints/components, test strategy, risks. No code yet.

### Phase 2 — Grill 🧑

Hand the plan to `/grill-me`. One question at a time with a recommended answer; explore the codebase rather than ask when possible. Surface UX gaps, data-model choices, backwards-compat, scope boundaries. Loop until **zero open questions** — answered by Arnaud, not assumed.

### Phase 3 — Approval gate 🧑

Present the final plan (answers folded in). Ask: "Approved to implement? (yes / changes needed)". Any "changes needed" → revise, re-confirm.

### Phase 4 — Implement

Spawn **Backend** then **Frontend** ([agents.md](agents.md)), each with the Architect brief + the approved plan. Full-stack: pass Backend's endpoint shapes to Frontend.

### Phase 5 — Test

Spawn the **Tester** ([agents.md](agents.md)). No untested code path; user flows get e2e coverage.

### Phase 6 — Review

Fresh sub-agents via Task — never inline in this session (verifier is a separate pass). One reviewer per stack touched, primed with the project's review context: a project-defined review skill for that stack if one exists, else the relevant CLAUDE.md / guidelines docs.

Fix all Critical and Important issues, re-review after fixes (max 2 iterations). Criticals remaining after 2 → **halt pipeline**, escalate via `AskUserQuestion`.

### Phase 7 — QA (UI changes)

Spawn the **QA** agent ([agents.md](agents.md)). Not the golden path — that's dogfood. QA hunts edge cases in a real browser, screenshot per probe: responsive widths, long/empty content, error states, design breakage. Findings ranked P0–P3; fix P0/P1 via the Frontend agent (max 2 iterations), then escalate leftovers.

### Phase 8 — Dogfood 🧑 (MANDATORY)

**Do not skip — the most-skipped phase.** Static checks verify code, not the feature.

Spawn the **Dogfooder** ([agents.md](agents.md)) — golden path as a real user, concrete evidence required. UX issues → fix via the Frontend agent (max 2 iterations).

Then the human half: tell Arnaud where the feature is running, and hand him 3–5 ranked scenarios unprompted — never a bare "go try it". Rank by **blind spot**: what the suite and the agent passes structurally can't reach — mutations tests only assert are *absent*, data shapes the seed lacks, the biggest logic/content block no test touches, real-user-scale vs fixture-scale, anything rendered. Each scenario says what to do and what counts as a failure. Proceed only on his OK (or an explicit "skip").

### Phase 9 — PR

`/get-to-clean-pr` handles risk assessment, commit split, push, PR open, CI loop, @claude review loop, merge queue. Pass the Phase 3 plan verbatim into its Phase 0.

## Failure handling

- Tester finds gaps → writes the tests itself, no bounce-back.
- Reviewer / QA iterations are capped at 2 → escalate the remainder to the user.
- Mid-pipeline user context → fold in and re-confirm.

## Rules

- Never skip a human gate (Phases 2, 3, 8).
- Delegate to `/grill-me`, `/get-to-clean-pr`, and project-defined skills (review, dogfood, e2e triage) — don't duplicate their logic.
