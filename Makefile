DIR=~/projects/dotfiles

.PHONY: link
link:
	@ln -s $(DIR)/.gitconfig ~
	@ln -s $(DIR)/.gitignore_global ~
	@ln -s $(DIR)/.hushlogin ~

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
