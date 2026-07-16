---
name: squad
description: Spawn specialized sub-agent pipeline for feature implementation. Orchestrates Architect, Frontend, Backend, Tester, Reviewer, and Dogfooder agents in sequence based on feature type.
category: automation
---

# /squad

Orchestrate a team of specialized sub-agents to implement a feature end-to-end.

## Usage

```
/squad <feature description>
/squad TSH-2500 Add bulk student import
```

## Pipeline

Detect feature type from the description keywords, then run agents in sequence:

```
Full-stack:    Architect → Backend → Frontend → Tester → Reviewer → Dogfooder → STOP
Frontend-only: Architect → Frontend → Tester → Reviewer → Dogfooder → STOP
Backend-only:  Architect → Backend → Tester → Reviewer → STOP
```

### Detection logic

Determined from the feature description only (no files exist yet at invocation time). The Architect agent may override the initial detection after reading the codebase.

- API endpoints, Go, database, migrations → includes Backend
- Components, pages, UI, React, styling → includes Frontend
- Unclear → default Full-stack

Pipeline stops before commit. User decides when to `/create-pr`.

## Agents

### 1. Architect (always first)

Spawn an Explore sub-agent to read all relevant docs and produce a **context brief**.

**Reads by scope**:
- Always: `docs/guidelines/local-dev.md`
- Frontend: `app/CLAUDE.md`, `docs/guidelines/app-patterns.md`, `docs/guidelines/app-testing.md`, `docs/guidelines/app-i18n.md`
- Backend: `services/api/CLAUDE.md`, `docs/guidelines/workers.md`
- E2E: `app/e2e/CLAUDE.md`
- Admin: `admin/CLAUDE.md`
- Domain-specific: any CLAUDE.md in affected containers (e.g., `app/src/containers/CarnetsDeNotes/CLAUDE.md`)

**Output**: Structured brief with relevant patterns, existing components/functions to reuse, naming conventions, test patterns, domain constraints. Pass this brief to all subsequent agents.

### 2. Backend

Spawn a general-purpose sub-agent when feature touches `services/api/`.

**Prompt must include**: Architect's context brief + specific backend changes to implement.

**Key behaviors**:
- Follow domain/repo/service/handler structure per `services/api/CLAUDE.md`
- Vanilla Go testing, no assertion libraries
- Run `./starttestenv.sh` then `go test ./...` for affected packages
- Verify endpoints with curl
- Restart API if running

### 3. Frontend

Spawn a general-purpose sub-agent when feature touches `app/` or `admin/`.

**Prompt must include**: Architect's context brief + specific frontend changes + backend endpoint shapes (if full-stack).

**Key behaviors**:
- Follow twin.macro styling, React Query hooks, Jotai state, Final Form patterns
- For **new UI** (new pages/components): use `/impeccable:frontend-design` or `/impeccable:polish`
- For forms/error states on new UI: use `/impeccable:harden`
- After implementation: verify with `agent-browser` (navigate feature, take screenshots)

### 4. Tester (vigilant, zero tolerance)

Spawn a general-purpose sub-agent after implementation agents complete.

**Purpose**: Guarantee test coverage. No untested code paths.

**Key behaviors**:
- **Backend**: Write Go tests for every new/modified function. Run tests. Coverage gaps → write more tests.
- **Frontend**: Write Vitest unit tests (table-driven `it.each` style). Write/update Playwright e2e tests for user flows.
- **E2E**: Follow `app/e2e/CLAUDE.md` patterns (page objects, `test.step()`, no `waitForTimeout`). Run locally first.
- **Rule**: Feature has no e2e test → create one. Tests break → fix or use `/e2e-fixer`.
- Cover: happy path, error states, edge cases, empty states.

### 5. Reviewer (automatic)

After Tester completes, self-review all changes.

**Do not spawn a sub-agent** — invoke skills directly from the main context:
- If `app/` or `admin/` changed: `/frontend-code-review`
- If `services/api/` changed: `/golang-code-review`
- Fix all Critical and Important issues
- Re-review after fixes (max 2 iterations)
- If Critical issues remain after 2 iterations → **halt pipeline**, escalate to user via AskUserQuestion. Do not proceed to Dogfooder.

### 6. Dogfooder (UI changes only)

After Reviewer, only if UI changes exist.

**Purpose**: Use the feature as a real user.

**Behaviors**:
- Use `agent-browser` to open the app, navigate to feature, complete full user flow
- Test: create, edit, delete, error states, empty states
- Take screenshots at each step
- If UX issues found → fix via Frontend agent (max 2 iterations)
- If `/dogfood` skill is installed, use it instead

## Hand-off Protocol

Each agent must structure its output with these section headers so the next agent can parse it reliably:

1. **Architect** →
   - `## Patterns` — relevant conventions, naming, test style
   - `## Reusable Code` — existing components/functions/hooks to use
   - `## Constraints` — domain rules, edge cases, gotchas
2. **Backend** →
   - `## Endpoints` — new/modified routes, method, path, request/response shapes
   - `## Tests` — test commands run and results
3. **Frontend** →
   - `## Components` — new/modified components, file paths
   - `## Verification` — agent-browser screenshots or observations
4. **Tester** →
   - `## Test Results` — commands run, pass/fail, coverage gaps filled
   - `## New Tests` — list of test files created/modified
5. **Reviewer** →
   - `## Status` — CLEAN or ISSUES_REMAINING
   - `## Fixes` — what was fixed, what was disputed
6. **Dogfooder** →
   - `## UX Validation` — screenshots, flow summary, issues found

## Failure Handling

- **Tester** finds gaps → writes tests itself, no bounce back
- **Reviewer** finds issues → fixes directly, re-reviews (max 2 iterations). If Critical issues remain → **halt pipeline**, escalate to user
- **Dogfooder** finds UX issues → spawns Frontend fix, re-dogfoods (max 2 iterations). Then escalate remaining issues to user

## Ralph-TUI Integration

For large features using Ralph (`/write-spec` → `/write-plan` → `/plan-to-tasks` → `ralph-tui`):
- `/squad` pipeline applies **within each task/story**
- Ralph handles task sequencing; `/squad` handles implementation quality per task
- Architect runs once at start of each task to refresh context
- Tester + Reviewer run at end of each task before Ralph commits
