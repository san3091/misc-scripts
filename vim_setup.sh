#!/bin/sh

link_vimrc() {
  ln -s ~/.vim/vimrc ~/.vimrc
}

clone_dotvim() {
  git clone https://github.com/san3091/dotvim.git ~/.vim
}

init_and_update_submodules() {
  cd ~/.vim
  git submodule init
  git submodule update
}

if [ -d "~/.vim" ]; then
  echo "you already have vim set up"
  exit 1
fi

if git --version; then
  clone_dotvim
  link_vimrc
  init_and_update_submodules
else
  echo "\nGit isn't installed. Run the new_laptop script first (or install git)\n"
fi

