# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Prezto theme
autoload -Uz promptinit
promptinit
DEFAULT_USER=`whoami`
prompt agnoster
unsetopt correct

# Oh-my-ZSH settings

# ZSH=$HOME/.oh-my-zsh
# ZSH_THEME="agnoster"
# plugins=(git github rails bundler brew zsh-syntax-highlighting rake-fast)
# COMPLETION_WAITING_DOTS="true"
# source $ZSH/oh-my-zsh.sh

## / Oh-my-ZSH settings
CASE_SENSITIVE="true"
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

export HOMEBREW_CASK_OPTS="--appdir=/Applications"
export DOCKER_HOST="tcp://$(boot2docker ip 2>/dev/null):2375";

# Path, aliases
source $HOME/.path
source $HOME/.aliases

# rbenv
export RBENV_ROOT=/usr/local/var/rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh

bindkey -M viins '^r' history-incremental-search-backward
bindkey -M vicmd '^r' history-incremental-search-backward

test -e ${HOME}/.iterm2_shell_integration.zsh && source ${HOME}/.iterm2_shell_integration.zsh

eval "$(docker-machine env default)"
