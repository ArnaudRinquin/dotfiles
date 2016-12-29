DIR=~/projects/dotfiles

.PHONY: link
link:
	@ln -s $(DIR)/.gitconfig ~
	@ln -s $(DIR)/.gitignore_global ~
	@ln -s $(DIR)/.hushlogin ~
	ATOM_FILES="config.cson snippets.cson styles.less"
	@mkdir -p ~/.atom
	@ln -s $(DIR)/.atom/config.cson ~/.atom
	@ln -s $(DIR)/.atom/snippets.cson ~/.atom
	@ln -s $(DIR)/.atom/styles.less ~/.atom


.PHONY: brew
brew:
	@echo "Installing brew"
	@/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	@brew tap Homebrew/bundle
	@brew tap caskroom/versions
	@brew bundle

.PHONY: fish
fish:
	@echo /usr/local/bin/fish >> /etc/shells
	@chsh -s /usr/local/bin/fish
	@curl -L http://get.oh-my.fish | fish
	@ln -s $(DIR)/fish/init.fish ~/.config/omf
	@fish -c 'omf install nvm'
	@fish -c 'omf install ocean'

.PHONY: nvm
nvm:
	@fish -c "nvm install stable"

.PHONY: osx
osx:
	defaults write -g InitialKeyRepeat -int 10
	defaults write -g KeyRepeat -int 2
