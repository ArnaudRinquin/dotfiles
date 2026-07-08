DIR=~/projects/dotfiles

.PHONY: link
link:
	@ln -s $(DIR)/.gitconfig ~
	@ln -s $(DIR)/.gitignore_global ~
	@ln -s $(DIR)/.hushlogin ~
	@ln -s $(DIR)/zsh/.zshenv ~/.zshenv
	@ln -s $(DIR)/tmux/tmux.conf ~/.tmux.conf
	@mkdir -p ~/.config
	@ln -s $(DIR)/ghostty ~/.config/ghostty
	@mkdir -p ~/.claude ~/.agents
	@ln -s $(DIR)/claude/settings.json ~/.claude/settings.json
	@ln -s $(DIR)/claude/CLAUDE.md ~/.claude/CLAUDE.md
	@ln -s $(DIR)/claude/skill-lock.json ~/.agents/.skill-lock.json

.PHONY: claude
claude:
	@echo "Restoring global Claude Code skills (vercel skills CLI)"
	npx --yes skills add squirrelscan/skills --global --skill "audit-website" -y
	npx --yes skills add millionco/react-doctor --global --skill "react-doctor" -y
	npx --yes skills add pbakaus/impeccable --global --skill "adapt,animate,arrange,audit,bolder,clarify,colorize,critique,delight,distill,extract,frontend-design,harden,normalize,onboard,optimize,overdrive,polish,quieter,teach-impeccable,typeset" -y
	npx --yes skills add mattpocock/skills --global --skill "grill-me,grill-with-docs,tdd,write-a-skill,writing-great-skills" -y
	npx --yes skills add vercel-labs/agent-skills --global --skill "vercel-composition-patterns" -y

.PHONY: zsh
zsh:
	@echo "Installing zsh and oh-my-zsh"
	@sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	@echo "source ~/projects/dotfiles/zsh/.init" >> ~/.zshrc

.PHONY: brew
brew:
	@echo "Installing brew"
	@/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	@brew bundle

.PHONY: osx
osx:
	defaults write -g InitialKeyRepeat -int 10
	defaults write -g KeyRepeat -int 2
	defaults write com.apple.dock "mru-spaces" -bool "false" && killall Dock
