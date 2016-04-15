#!/bin/sh
FILES=".atom .gitconfig .gitignore_global .hushlogin"

for FILE in $FILES
do
  ln -s ~/projects/dotfiles/$FILE ~
done

ln -s ~/projects/dotfiles/fish/init.fish ~/.config/omf
