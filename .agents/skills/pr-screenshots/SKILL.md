---
name: pr-screenshots
description: Capture BEFORE/AFTER screenshots of the screens a PR changes and post them as one side-by-side PR comment (images hosted in a secret gist). Use when the user says "/pr-screenshots [PR#]", asks for before/after visuals on a PR, or a PR touches app/, admin/ or website/ UI and is about to get a human reviewer.
category: version-control-git
allowed-tools: Bash(gh *), Bash(git *), Bash(agent-browser *), Bash(curl *), Bash(mkdir *), Bash(cp *), Bash(lsof *), Read, Write
---

# /pr-screenshots

A reviewer should see what changed without running the branch. One comment, one row per screen, BEFORE | AFTER.

## Input

`/pr-screenshots [PR#]` — no arg → current branch's PR: `gh pr view --json number --jq .number`.

Captures live in `~/.cache/pr-screenshots/<branch>/{before,after}/`, named `NN-<screen-slug>.png` — same name on both sides = same row.

## Steps

1. **Pick screens** (≤5) — from `gh pr diff <N> --name-only`: which routes/components render the change. Include the state that shows it (dialog open, empty list, error). No UI in the diff → stop, say so.
2. **Setup** — app + API running for this worktree (`.ports`; see `docs/guidelines/local-dev.md`), logged in with a seed account (`t@t.com` / `p`). Local seed data only — never prod, never real users: the gist is unlisted, not private.
3. **BEFORE** — first source that works:
   - a. Existing `before/` captures (e.g. taken by `/go` before implementing) → reuse.
   - b. Frontend-only diff: require a clean tree (`git status --short` empty), then swap the UI files back to base in place and let HMR reload:
     `git restore --source=$(git merge-base origin/main HEAD) --worktree -- <changed app/admin/website files>`
     → capture → **always** `git restore --source=HEAD --worktree -- <same files>` and confirm `git status --short` is empty again.
   - c. Neither possible → no BEFORE; the row shows "n/a (new screen)" or "n/a (not reproducible locally)".
4. **AFTER** — reuse fresh `/go` QA/dogfood captures if they show the same screens, else capture on the branch.
5. **Capture** — same viewport both sides (`agent-browser set viewport 1440 900`), same data, same scroll. `agent-browser screenshot <path>`. Read each PNG back to check it shows the change, not a spinner or login page.
6. **Host in a secret gist** — one gist per PR, reused on re-runs (`gh gist list --limit 100` → description `pr-screenshots <owner>/<repo>#<N>`). `gh gist create` rejects binaries, so:
   - create: `gh gist create --desc "pr-screenshots <owner>/<repo>#<N>" <README.md>` (a one-line text file)
   - clone over https (ssh host-key check fails in the sandbox): `git -c "credential.helper=!gh auth git-credential" clone https://gist.github.com/<id>.git <scratch>/gist`
   - copy PNGs as `NN-<slug>-before.png` / `NN-<slug>-after.png`, `git add`, `git commit`, then push with the same `-c credential.helper=…` flag.
   - URL: `https://gist.githubusercontent.com/<gh-user>/<id>/raw/<file>` — check one with `curl -sI` → `content-type: image/png`.
7. **Comment** — one comment, marker first line so re-runs edit instead of stacking:

   ```markdown
   <!-- pr-screenshots -->
   ## Before / After

   | Screen | Before | After |
   | --- | --- | --- |
   | Registre — group by classe | <img src="…-before.png" width="420"> | <img src="…-after.png" width="420"> |
   ```

   Existing marker comment (`gh api repos/{owner}/{repo}/issues/<N>/comments --jq '.[] | select(.body | startswith("<!-- pr-screenshots -->")) | .id'`) → `gh api -X PATCH repos/{owner}/{repo}/issues/comments/<id> -F body=@<file>`; else `gh pr comment <N> --body-file <file>`.
8. **Report** — comment URL + one line per screen (and which BEFORE source was used).

## Rules

- Never leave the worktree on base files: step 3b's restore runs even if the capture failed.
- Never push anything to the monorepo for images — gist only.
- Tell the user the gist link in the report: it's unlisted, anyone with the URL sees it.
