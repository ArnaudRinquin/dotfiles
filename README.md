dotfiles
========

Ain't anything like home.

## Link dotfiles


```sh
cd projects
git clone git@github.com:ArnaudRinquin/dotfiles.git
cd dotfiles
./link.sh

```

## Install tools

Install [homebrew](http://brew.sh/) manually, then: 


```sh
brew install curl git nvm fish hub postgresql tree
brew tap caskroom/cask
brew cask install 1password atom dropbox iterm2 slack alfred docker gitify keepingyouawake
```

Setup fish shell:

```sh
sudo echo /usr/local/bin/fish >> /etc/shells
chsh -s /usr/local/bin/fish

# in another tab

curl -L http://get.oh-my.fish | fish
omf install ocean
omf install nvm
```

Install latest node and fuck-you:


```sh
mkdir ~/.nvm
nvm install stable
npm i -g fuck-you
```

## Extra commands


```sh
# Fast keyboard repeat
defaults write -g InitialKeyRepeat -int 10
defaults write -g KeyRepeat -int 2

```

