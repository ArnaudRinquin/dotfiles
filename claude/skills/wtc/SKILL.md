---
name: wtc
description: Spin off a parallel worktree+tmux+claude session for a new task while staying in the current one. Creates a Linear ticket as a sub-issue of the current ticket (same project/milestone, assigned to user, Todo status), then runs `g wtc <branch> '/go linear'` to spawn the new worktree, tmux window, and a fresh claude pane preloaded with `/go linear`. Use when user says "/wtc <description>", "/wtc this" (refers to something discussed earlier in the conversation), spots an issue to work on in parallel, or wants to track a side-task without losing the current context. Supports `--no-linear <description>` to skip ticket creation and use a slugified branch + the description as direct prompt, and `/wtc TSH-XXXX` to open a worktree on an existing ticket.
---

# /wtc

Spin off a parallel worktree+tmux+claude from the current one for a new task. The current session keeps running; the new one opens in a fresh tmux window with its own claude pane preloaded with `/go linear`.

## Usage

```
/wtc <description>                        # create Linear ticket + worktree
/wtc this                                 # description = recent conversation context
/wtc                                      # same as `/wtc this`
/wtc --no-linear <description>            # no Linear, slugify into branch
/wtc TSH-1234                             # existing ticket → open worktree
```

**Resolving `this` / no-arg / deictic references** ("this", "it", "that"): use the
immediately preceding conversation turns as the source. Summarize the issue/idea
the user just discussed into a one-line description (and a richer body for the
Linear ticket if useful). If the recent context is ambiguous or empty → ask
the user to describe it.

## Default flow (with Linear)

1. **Resolve current ticket** — try in order: current branch name, worktree basename, recent commits (`git log main..HEAD --pretty=%s | head -10`), match `(?i)(TSH-\d+)`. If none → skill still proceeds (new ticket will be top-level in user's default team).

2. **Read current ticket** (if found) via `mcp__linear__get_issue` — capture `team`, `id`, `project`, `projectMilestone`. The new ticket inherits:
   - **Parent**: the current ticket (sub-issue). If no current ticket detected → new is top-level in user's default team.
   - **Project**, **Milestone**, **Team**: same as current.

3. **Resolve assignee** — current user. Use `mcp__linear__list_users` filtered by current user's email if needed.

4. **Resolve Todo status ID** for the team via `mcp__linear__list_issue_statuses`.

5. **Confirm with user** via `AskUserQuestion` showing the full plan:
   ```
   Title:     <derived from description>
   Parent:    <parent ID or "none (top-level)">
   Project:   <inherited>
   Milestone: <inherited or "none">
   Assignee:  me
   Status:    Todo
   Then run: g wtc <expected branchName> '/go linear'
   ```
   Options: Proceed | Edit title | Skip Linear (fall through to `--no-linear`) | Cancel.

6. **Create ticket** with `mcp__linear__save_issue`. Capture `id`, `identifier` (TSH-XXXX), and `branchName` from the response.

7. **Run alias** via Bash, backgrounded (worktree creation takes minutes due to `pnpm install`):
   ```
   g wtc <branchName> '/go linear' > /tmp/wtc-<TSH-XXXX>.log 2>&1
   ```

8. Report: ticket URL, worktree path, "new tmux window appearing — claude pane will load `/go linear` once setup completes".

## `--no-linear` mode

1. Slugify description → lowercase, hyphens, alphanumerics only, cap ~40 chars. Example: `"fix the broken modal"` → `fix-the-broken-modal`.
2. Confirm branch name with user (let them edit). Show the full command that will run.
3. `g wtc <branch> "<description>"` — the description doubles as the claude prompt (verbatim, no `/go linear`).

## Existing ticket mode (`/wtc TSH-1234`)

1. `mcp__linear__get_issue` for the ID → get `branchName`.
2. Confirm.
3. `g wtc <branchName> '/go linear'`.

## Constraints

- The `g wtc` alias hardcodes `-c` (create branch). If the branch already exists, `wt switch` errors. Pre-check via `wt list --branches | grep -i <branch>`; if it exists, ask whether to switch to the existing worktree (manually run `wt switch <branch>`) or pick a new name.
- Must be inside a tmux session (the layout hook checks `$TMUX`). If not, warn and abort.
- This action has visible side effects (new Linear ticket, new worktree, new tmux window). Always confirm via `AskUserQuestion` before firing — even in auto mode.
- After the alias runs, the original tmux pane keeps running. The user can switch to the new window manually (tmux usually selects it automatically per layout).

## Caveats

- The `WT_EXTRA` → claude-prompt forwarding requires the project's `setup-tmux` to pass `$4` to layouts. If the new worktree's base branch predates that change, the prompt won't reach claude — the pane still opens, just without the preloaded prompt. Mention this to the user if you detect that.
- Default parent is the current ticket (sub-issue). Override to sibling (same parent as current) only if the user explicitly says so ("/wtc as a sibling", "parallel to this", etc.).
