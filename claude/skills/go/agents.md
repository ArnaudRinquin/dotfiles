# /go — sub-agent briefs

Every agent's prompt includes: the Architect's context brief + the approved plan + its section of this file. Each agent structures its output with the listed headers so the next phase can parse it.

## Architect (Explore agent, Phase 1)

Reads by scope, produces the context brief.

| Scope | Reads |
|---|---|
| Always | `docs/guidelines/local-dev.md` |
| Frontend | `app/CLAUDE.md`, `docs/guidelines/app-patterns.md`, `docs/guidelines/app-testing.md`, `docs/guidelines/app-i18n.md` |
| Backend | `services/api/CLAUDE.md`, `docs/guidelines/workers.md` |
| E2E | `app/e2e/CLAUDE.md` |
| Admin | `admin/CLAUDE.md` |
| Domain | any CLAUDE.md in affected containers (e.g. `app/src/containers/CarnetsDeNotes/CLAUDE.md`) |

Output: `## Patterns` (conventions, naming, test style) / `## Reusable Code` (existing components/functions/hooks) / `## Constraints` (domain rules, edge cases, gotchas).

## Backend (general-purpose, Phase 4)

- Domain/repo/service/handler structure per `services/api/CLAUDE.md`.
- Vanilla Go testing, no assertion libraries. `./starttestenv.sh` then `go test ./...` for affected packages.
- Verify endpoints with curl. Restart the API if running.

Output: `## Endpoints` (routes, method, path, request/response shapes) / `## Tests` (commands run + results).

## Frontend (general-purpose, Phase 4)

- twin.macro styling, React Query hooks, Jotai state, Final Form patterns.
- New UI → `/impeccable:frontend-design` or `/impeccable:polish`; forms/error states on new UI → `/impeccable:harden`.
- Verify with `agent-browser` (navigate the feature, screenshots).

Output: `## Components` (new/modified, file paths) / `## Verification` (screenshots or observations).

## Tester (general-purpose, Phase 5)

- Backend: Go tests for every new/modified function.
- Frontend: Vitest unit tests (table-driven `it.each`); Playwright e2e per `app/e2e/CLAUDE.md` (page objects, `test.step()`, no `waitForTimeout`), run locally first.
- Feature has no e2e test → create one. Tests break → fix, or hand to the project's e2e-triage skill if one exists.
- Cover: happy path, error states, edge cases, empty states.

Output: `## Test Results` (commands, pass/fail, gaps filled) / `## New Tests` (files created/modified).

## Dogfooder (general-purpose + agent-browser, Phase 8)

A real user, not a tester — fresh context so it can't rubber-stamp its own work.

- UI changes → the project's dogfood skill if one exists, else drive the golden path in a real browser: create, edit, delete, the flow a real user would actually run.
- Non-UI → exercise the surface: curl for APIs, run the script/job for CLI.
- Evidence is the deliverable: screenshots per step, response bodies, DB state. A bare "no issues found" is a failed run — re-run.
- UX issues found → report; the main session fixes via the Frontend agent (max 2 iterations).

Output: `## UX Validation` — flow summary, evidence paths, issues found / `## Blind Spots` — what this run couldn't reach: data it lacked, paths it didn't mutate.

## QA (general-purpose + agent-browser, Phase 7)

Edge-case hunter, not a user. Probe the changed screens in a real browser, **one screenshot per probe** as evidence:

- **Viewports**: 375 (mobile), 768 (tablet), 1440 (desktop) — layout breaks, overflow, unreachable controls.
- **Content extremes**: very long strings (French labels + elision), empty state, zero/one/many items, missing optional data.
- **Failure modes**: API error responses, slow network, double-submit.
- **Interaction**: keyboard focus order, hover/disabled states, scroll positions in long lists.

Output: `## QA Findings` — one line per finding, ranked P0 (broken) → P3 (nit), each with its screenshot path and repro viewport/state.
