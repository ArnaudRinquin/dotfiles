---
name: get-to-clean-pr
description: Full PR lifecycle — risk assess, commit/push, open PR, iterate on CI + @claude review until clean, auto-merge if low risk. Reached by /go Phase 9.
category: version-control-git
allowed-tools: Bash(git *), Bash(gh *), Bash(pnpm *), Bash(sleep *), Bash(date *), Bash(go *), Read, Write, Edit, Glob, Grep, Task, AskUserQuestion, Monitor
---

# Get to clean PR (full lifecycle)

One skill, whole lifecycle: risk assessment → branch/commits → self-review → push/PR → CI + review loop → merge queue (if safe).

Personal fork of the monorepo's `create-pr-new` (left untouched there for the team) — this copy is canonical for Arnaud's flows.

## Configuration

- **CI fix attempts before asking**: 2
- **Review iterations before asking**: 2
- **Review poll interval**: `sleep 20` (max 40 polls ≈ 13min)
- **Review bot authors**: `claude` AND `brutus-teetsh` — this repo runs both. Match `test("claude|brutus"; "i")`, never an equality check: the REST API reports `brutus-teetsh[bot]` while `gh pr view` reports `brutus-teetsh`.
- **E2e test cap**: ~5 most relevant files

## Phase 0 — Risk assessment + plan (agreed with user)

Before touching git, analyze the working tree and produce a short plan. Read `git status`, `git diff`, and look at scope/files touched.

Output a concise assessment:

```
## Plan
- Scope: <services affected>
- Summary: <what changes do>
- Commits: <N commits split as …>
- PR title: <type>[<scope>]: <desc> [<LINEAR-ID>]
- Risk: LOW | MEDIUM | HIGH
- Rationale: <1-2 lines — blast radius, reversibility, test coverage>
- Auto-merge on clean: YES | NO
- E2e to trigger: <files or "none">
```

**Risk heuristics**:
- LOW → docs, copy, styles, isolated component, tests only, infra no-op. Auto-merge OK.
- MEDIUM → feature work with tests, touches one service. No auto-merge (dev decides).
- HIGH → migrations, auth, billing, cross-service, infra orchestrator, large diff, no tests. No auto-merge.

Then `AskUserQuestion` to confirm the plan (risk, auto-merge, commit split). Do not proceed without confirmation. Apply any user tweaks.

## Phase 1 — Branch, format, commits

1. If on `main`, create a new branch. If Linear ID in context, use the Linear branch name.
2. Frontend changes → `pnpm --filter <pkg> lint:fix` on modified files. For `app/` only, also run `pnpm --filter app prettify` (oxfmt — admin/website/extension don't have a formatter, oxlint --fix is the only step). **Don't run `prettier` directly — the repo no longer uses it; running it reformats whole files against the wrong style.** Stage any files modified by lint/format before committing. Then run `pnpm --filter app check:fast` for a fast local feedback loop (oxlint + `tsgo --noEmit --incremental`). The full `check` (i18n + tsc + oxlint with JS plugins) runs in CI.
3. Split into logical commits per the agreed plan:
   - By feature/component/concern
   - Refactor separate from feature
   - Each commit self-contained and understandable
4. Commit messages: concise, no co-author, no "claude" mention.

## Phase 2 — Self-review (pre-push)

Before pushing, spawn specialized sub-agent reviewers via `Task` to catch obvious issues locally. This avoids round-tripping through CI and external review for things we can fix now.

**Which reviewers to spawn** — one per tech stack touched, in parallel; add cross-cutting reviewers when triggered (architecture: cross-service / new packages / schema-migration changes; security: auth, payments, user input, external API calls). Prime each with the project's own review context: a project-defined review skill for that stack if one exists, else the relevant CLAUDE.md / guidelines docs.

**Skip self-review** for LOW risk changes (docs, copy, styles, tests only).

**Sub-agent instructions**:
- Each reviewer gets: the diff (`git diff main...HEAD`), list of changed files, and the PR plan from Phase 0.
- Reviewers report: list of issues as CRITICAL / IMPORTANT / SUGGESTION with file:line references.
- Reviewers must NOT make edits — only report findings.

**Acting on findings** — use judgment on each item:
- **Straightforward fix** (obvious bug, missing nil check, typo, off-by-one, unused import) → fix it, create a new commit. No need to ask.
- **Non-trivial fix** (architectural change, new abstraction, behavior change, touches multiple files, debatable correctness) → do NOT fix. Instead, `AskUserQuestion` presenting the finding and your assessment. Let the author decide.
- **Suggestions** → fix only if cheap and clearly right. Skip stylistic nits.

This distinction matters: a wrong "critical" remark auto-fixed could silently introduce a large blast-radius change the author never reviewed. When in doubt, ask.

After fixes (if any) are committed, proceed to push.

## Phase 3 — Push + Open PR

Push current branch only (`git push -u origin HEAD`). Never push to main.

**Title**: `<type>[<scope>]: <description> [<LINEAR-ID>]`
- type: `chore|docs|feat|fix|refactor`
- scope: `app|api|admin|website|extension|infra|strapi` (omit if repo-wide)
- LINEAR-ID from branch name if present (e.g. `tsh-123-…` → `[TSH-123]`)

Examples: `feat(app): Bulk student import [TSH-2500]`, `fix(api): Prevent duplicate webhook [TSH-2481]`, `chore: Update CI caching`.

First check if a PR already exists for this branch: `gh pr view --json number --jq .number 2>/dev/null`. If found, reuse it and skip creation. Otherwise `gh pr create` — always ready for review (gets @claude review immediately). Draft only if Arnaud explicitly asked for one this run.

## Phase 4 — Trigger impacted e2e tests

Use the e2e list from the Phase 0 plan as the source of truth. If the plan says "none", skip. Otherwise re-verify against `gh pr diff <PR> --name-only` only if the working tree changed since the plan was agreed.

- **Modified e2e specs** (`e2e-app/**/*.spec.ts` in diff) → trigger with `x3`
- **Impacted e2e specs** → map changed source files to feature areas, cross-ref test names in `e2e-app/` + page objects in `e2e-app/pageobjects/`. Cap ~5.

**Prefer `/e2e-workspace`** (runs PR app + API on a per-branch VM) over `/e2e app` (PR app vs recette API, flaky Netlify preview). See `e2e-app/CLAUDE.md`.

**CRITICAL: batch into ≤2 comments.** Multiple separate comments cause concurrency conflicts (runs cancel → "0/0 passed").

```
gh pr comment <PR> --body "/e2e-workspace <modified files> x3"
gh pr comment <PR> --body "/e2e-workspace <impacted files>"
```

Skip if no related tests.

**Confirm the run actually started.** `gh run list --branch <b>` omits `issue_comment`-triggered runs, so an e2e-workspace run is invisible there — use `gh run list --workflow=e2e-workspace-on-demand.yml`. Every unrelated PR comment also spawns its own run of that workflow which correctly no-ops, so a `skipped` conclusion in the history is not evidence your e2e comment failed. Check for a run whose conclusion is not `skipped`; if there's none a minute after commenting, re-post the comment.

## Phase 5 — CI loop

If Phase 4 posted `/e2e` comments, `sleep 30` first so the runner has time to queue the e2e jobs — otherwise `--watch` may declare CI clean before e2e runs exist.

Then watch CI via `Monitor` (Bash's 10-min cap is too short for e2e runs):

```
Monitor(
  description: "CI checks for PR <PR>",
  timeout_ms: 3600000,
  command: "gh pr checks <PR> --watch --fail-fast > /tmp/ci-<PR>.log 2>&1; echo \"DONE exit=$?\""
)
```

`gh --watch` does the polling; the monitor just unblocks Claude during the wait and extends the timeout to 60 min. The single `DONE exit=N` event tells you success (0) or failure (non-zero) — then read `/tmp/ci-<PR>.log` for details.

On failure:
1. `gh pr checks <PR> --json name,state,bucket,workflow,link`
2. `gh run view <RUN_ID> --log-failed`
3. Fix → commit → push
4. Re-trigger relevant e2e if needed (batched); if re-triggered, `sleep 30` before re-watching
5. Re-arm the Monitor

After **2** failed fix attempts → `AskUserQuestion` continue or stop.

## Phase 6 — @claude review loop

1. Record timestamp: `date -u +%Y-%m-%dT%H:%M:%SZ`
2. If no review auto-triggered on PR open → `gh pr comment <PR> --body "@claude review this PR"`

**Brutus does not behave like the claude reviewer — read this before waiting on it:**
- `brutus-code-review.yml` is `on: pull_request: types: [opened, ready_for_review]`. **No `synchronize`**, so pushing fixes leaves the old verdict standing and nothing is queued.
- An `@brutus-teetsh` comment does **nothing** — there is no `issue_comment` trigger. Waiting on one is waiting forever.
- Re-review is `gh workflow run brutus-code-review.yml -f pr_number=<N>`, the only re-trigger.
- Its workflow going green means *the webhook was accepted*, not that a review was posted. Brutus runs async and flips a `brutus-review` commit status later. Green workflow + no comment + status still `pending` = silent finish → dispatch again. Watch `repos/:o/:r/commits/:sha/statuses` (context `brutus-review`), not the workflow conclusion.
3. Poll for a `claude`-authored comment created after the timestamp:

```bash
gh pr view <PR> --json comments --jq '[.comments[] | select((.author.login | test("claude|brutus"; "i")) and .createdAt > "<TS>") | {createdAt, body}] | last'
```

Initial reply is a "working" message. Keep polling until:
- Body starts with `**Claude finished`, OR
- Body contains `## 🔴 Critical` / `## 🟡 Important` / `### Code Review Complete`

Timeout 40 × 20s. On timeout, warn user and abort.

Parse defensively (h2/h3, emoji optional).

**What to address** — use judgment, don't be dogmatic:

For each Critical / Important item, classify the fix:
- **Straightforward** (clear bug, missing check, wrong return type, simple logic error) → fix it, new commit. Continue autonomously.
- **Non-trivial** (refactor, behavior change, multi-file change, debatable correctness) → do NOT fix. Flag it to the author via `AskUserQuestion` with the finding, your assessment, and why you think it needs human judgment. Let them decide.
- **Clearly wrong** (reviewer hallucinated, misread the code) → skip, note in PR reply.

**Suggestions / Nits** → address only the sensible ones: cheap, clearly-right improvements. Skip anything stylistic, speculative, or expensive.

After fixes: commit, push, reply comment summarizing fixed/skipped/flagged, loop back to Phase 5.

**Comment hygiene**: never reference review items with `#N` syntax (e.g. "#4") in PR comments — GitHub auto-links those as PR/issue references and ruins readability. Use "item 4", "point 4", or quote the section title instead.

After **2** review iterations → `AskUserQuestion` continue or stop.

If review says "no critical", "no important" → CLEAN, continue to Phase 7.

## Phase 7 — Merge queue or handoff

If plan said **auto-merge: YES** and status is CLEAN:
- `gh pr merge <PR> --auto --squash --delete-branch`
- This enqueues in the merge queue once required checks pass.

Otherwise: leave for human merge. Print final summary.

## Final summary (post on PR + show locally)

```markdown
## PR Lifecycle Summary

### Plan
- Risk: <LOW|MEDIUM|HIGH>
- Auto-merge: <YES|NO>

### Self-Review
- [reviewers spawned + issues found/fixed, or "skipped (LOW risk)"]

### CI Fixes
- [failures + fixes, or "clean first run"]

### Review Iterations
- Round N: X critical, Y important → Fixed/Disputed
- [or "clean first pass"]

### E2E
- [files triggered + results, or "none"]

### Files Modified During Loop
- [...]

### Status: CLEAN | STOPPED_BY_USER | TIMEOUT | ENQUEUED
```

## Rules

- **One Bash command per call** (project CRITICAL). No `&&`, `;`, pipes in Bash calls.
- Never push to `main`. Only push current branch.
- Always open ready-for-review; draft only on explicit request.
- Never auto-merge HIGH risk.
- Never self-approve: if running inside same session that authored code, the review loop still delegates review work to @claude bot (external).
- `AskUserQuestion` is the stop valve — never loop indefinitely.
- No co-author, no "claude" mentions in commits/PR body.
