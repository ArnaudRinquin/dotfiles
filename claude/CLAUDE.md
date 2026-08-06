- In all interactions and commit messages, be extremely concise and sacrifice grammar for the sake of concision.

## GitHub

- Your primary method for interacting with Github should be the Github CLI `gh`
- When working on a Linear issue, prefix the pull request titles with the issue ID

## Git

- When working on a Linear issue, use the Linear issue branch
- When starting a new branch, make sure to start from a fresh pull of the `main` branch
- Never ever push directly to `main` branch unless I tell you to
- Only ever push the current branch

## Linear

- Never update Linear issues status manually, we have automations for this

## Plans

- Add the end of each plan, give me a list of unresolved questions if any. Make these questions extremely concise. Sacrifice grammar in sake of concision.

## Memory extraction gate

Before saving any auto-memory entry, ALL three must be true:

- "Could someone Google this in 5 minutes?" → NO
- "Is this specific to THIS codebase / this user / this workflow?" → YES
- "Did this take real debugging effort, a correction, or surprise to discover?" → YES

If any answer fails, do not save. Tighter than (and additive to) the harness's default auto-memory exclusions.
