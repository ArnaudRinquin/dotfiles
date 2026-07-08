# dotfiles

Ain't anything like home.

## First step

_getting the projet in the right place_

```sh
cd projects
git clone git@github.com:ArnaudRinquin/dotfiles.git
cd dotfiles
```

## Run the make tasks

```sh
make brew
make link    # symlinks: git, zsh, tmux, ghostty, claude (settings + CLAUDE.md + skill-lock)
make zsh
make osx
make claude  # restores global Claude Code skills via the vercel `skills` CLI
```

## What's linked

- **git** — `.gitconfig`, `.gitignore_global`
- **zsh** — `.zshenv` (+ `.init` sourced from `.zshrc`)
- **tmux** — `tmux/tmux.conf` → `~/.tmux.conf`
- **ghostty** — `ghostty/` → `~/.config/ghostty` (config + `shaders/cursor.glsl` mauve cursor trail)
- **claude** — `claude/settings.json` → `~/.claude/`, `claude/CLAUDE.md` → `~/.claude/`, `claude/skill-lock.json` → `~/.agents/.skill-lock.json`

### Claude skills & plugins

`make claude` reinstalls the skills pinned in `claude/skill-lock.json` (impeccable, react-doctor, mattpocock, etc.) into `~/.agents/skills`.
Plugin-provided skills (figma, code-simplifier, …) come back from the marketplaces enabled in `settings.json` (`enabledPlugins`) — re-add those marketplaces in Claude Code with `/plugin`.
