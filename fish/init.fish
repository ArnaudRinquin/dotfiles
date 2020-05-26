set -gx HELM_HOME $HOME/.helm
set -gx NVM_DIR $HOME/.nvm
set -gx GOPATH $HOME/projects/go
set -gx ANDROID_HOME $HOME/Library/Android/sdk
set -gx TRANSPORT_PATH (xcode-select --print-path)/../Applications/Application\ Loader.app/Contents/itms/bin
set -gx LC_ALL en_US.UTF-8
set -gx LANG en_US.UTF-8
source ~/projects/dotfiles/fish/aliases.fish
source ~/projects/dotfiles/fish/path.fish
status --is-interactive; and source (rbenv init -|psub)
