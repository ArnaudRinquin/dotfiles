---
name: spawn
description: Spin off a parallel worktree+terminal+claude session for a new task while staying in the current one. Creates a Linear ticket as a sub-issue of the current ticket (same project/milestone, assigned to user, Todo status), then runs `orca worktree create` to create the new Orca worktree with a fresh claude terminal preloaded with `/go linear`. Use when user says "/spawn <description>", "/spawn this" (refers to something discussed earlier in the conversation), "spawn one for X", spots an issue to work on in parallel, or wants to track a side-task without losing the current context. Supports `--no-linear <description>` to skip ticket creation and use a slugified branch + the description as direct prompt, and `/spawn TSH-XXXX` to open a worktree on an existing ticket. Formerly named `wtc` — treat `/wtc` as an alias.
---

# /spawn

Spin off a parallel worktree+terminal+claude from the current one for a new task. The current session keeps running; the new one appears as an Orca worktree in the sidebar, with claude in its first terminal preloaded with `/go linear`.

## The spawn command

Every mode below ends in the same two calls. `ORCA` is `/Applications/Orca.app/Contents/Resources/bin/orca`: the `/usr/local/bin/orca` symlink is root-owned mode 0700 and the CLI fails to resolve Orca.app through it.

```sh
git -C ~/projects/teetsh/monorepo fetch --quiet origin main
ORCA worktree create --repo path:$HOME/projects/teetsh/monorepo --name '<branch>' \
  --parent-worktree path:"$(git rev-parse --show-toplevel)" --base-branch origin/main --agent claude --prompt '<prompt>' --setup run --json
```

- `--parent-worktree`: the new worktree is a child of the one spawning it, so Orca nests it under its parent. Never pass `--no-parent`. If the current checkout is not Orca-managed (the main checkout, a `.claude/worktrees/` one), drop the flag and let Orca infer the parent.

- `--name` is the branch name. Add `--linear-issue TSH-XXXX` when there is a ticket, so Orca links it.
- `--base-branch origin/main` + the fetch: the local `main` goes stale, which silently starts worktrees N commits behind.
- `--setup run` runs the personal setup script `~/.config/orca/monorepo-setup.sh` (Orca repo setting, policy local-only, setup split under the agent pane): `wt … hook pre-start` (ports, strapi DB, deps, claude settings symlink), then `pnpm tui` in the setup pane. `setupAgentStartupPolicy: wait-for-setup` (orca.yaml) makes claude start only once setup exited 0.
- Read `.ok`, `.result.worktree.path` and `.result.launch.outcome.handle` (the agent terminal) from the JSON. Without `--activate` the new worktree stays in the background; the user switches to it themselves.
- **Check `.result.launch.prompt.outcome`.** With `wait-for-setup`, Orca drops `--prompt` (`"not-delivered"`): claude starts on an empty input once setup ends. Then deliver it yourself once claude is up — `ORCA terminal read --terminal <handle> --json` until the tail shows the `❯` input line (poll; `terminal wait --for tui-idle` is unreliable), then:

  ```sh
  ORCA terminal send --terminal <handle> --text '<prompt>' --enter --wait-submit 15 --json
  ```

  Success = `.result.send.prompt.stages` contains `turn_started`. Never report the spawn done before that.

## Usage

```
/spawn <description>                      # create Linear ticket + worktree
/spawn this                               # description = recent conversation context
/spawn                                    # same as `/spawn this`
/spawn --no-linear <description>          # no Linear, slugify into branch
/spawn TSH-1234                           # existing ticket → open worktree
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

5. **No confirmation** — proceed directly. Ask (`AskUserQuestion`) only when the description is ambiguous (see "Resolving `this`") or the branch precheck hits.

6. **Create ticket** with `mcp__linear__save_issue`. Capture `id`, `identifier` (TSH-XXXX), and `branchName` from the response.

7. **Branch precheck** (see Constraints), then **spawn** with the command above: `--name '<branchName>' --linear-issue <TSH-XXXX> --prompt '/go linear'`. The call returns once the worktree exists; setup keeps running in Orca.

8. Report: ticket URL, worktree path, agent terminal handle, "new worktree in Orca's sidebar — setup runs first, then claude loads `/go linear`".

## `--no-linear` mode

1. Slugify description → lowercase, hyphens, alphanumerics only, cap ~40 chars. Example: `"fix the broken modal"` → `fix-the-broken-modal`.
2. Branch precheck, then run the spawn command with `--prompt '<description>'` — the description doubles as the claude prompt (verbatim, no `/go linear`). No `--linear-issue`.

## Existing ticket mode (`/spawn TSH-1234`)

1. `mcp__linear__get_issue` for the ID → get `branchName`.
2. Branch precheck, then run the spawn command with `--name '<branchName>' --linear-issue TSH-1234 --prompt '/go linear'`.

## Constraints

- **Branch precheck — abort, don't warn.** Orca does not fail on an existing branch: it silently creates `<branch>-2`, which breaks the Linear branch link. Before creating, check both `git -C ~/projects/teetsh/monorepo branch --list '<branch>'` and `git -C ~/projects/teetsh/monorepo ls-remote --heads origin '<branch>'`. If either matches, stop and ask: open the existing worktree in Orca, or pick a new name.
- Orca must be running. If the create fails with Orca not running, run `ORCA open --json` and retry once.
- Don't confirm before firing: invoking /spawn is the go-ahead. Ask only on ambiguity or a branch collision; report what was created afterwards.

## Caveats

- `wait-for-setup` lives in the monorepo's committed `orca.yaml`, read from the new worktree's own checkout. If setup exits non-zero, claude never starts ("Setup failed; skipping agent startup") — check the setup pane.
- CLI-created worktrees run setup WITHOUT `$ORCA_WORKTREE_PATH`; the setup script falls back to `git rev-parse --show-toplevel`.
- Orca prefixes branches with the git username unless Settings → branch prefix is `None`. Check that the created branch equals `<branch>` exactly.
- claude's arguments come from Orca's global Settings → Agents (`--enable-auto-mode`); there is no per-spawn argument, so the session is not named after the branch.
- Default parent is the current ticket (sub-issue). Override to sibling (same parent as current) only if the user explicitly says so ("/spawn as a sibling", "parallel to this", etc.).
