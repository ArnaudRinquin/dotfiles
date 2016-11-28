#!/bin/sh
FILES=".gitconfig .gitignore_global .hushlogin"

for FILE in $FILES
do
  ln -s ~/projects/dotfiles/$FILE ~
done

ATOM_FILES="config.cson snippets.cson styles.less"
mkdir -p ~/.atom

for ATOM_FILE in $ATOM_FILES
do
  ln -s ~/projects/dotfiles/.atom/$ATOM_FILE ~/.atom
done


ln -s ~/projects/dotfiles/fish/init.fish ~/.config/omf
