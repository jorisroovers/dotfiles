#!/bin/bash
set -ux

# Install homebrew if not already installed
brew --version || NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

install_brew_package(){
    brew info $1 || brew install $1
}

install_brew_package bat
install_brew_package git
install_brew_package git-delta
install_brew_package jq
install_brew_package gh
install_brew_package ripgrep
install_brew_package oh-my-posh

# TODO: do install of `cat brew.sh  | grep -v '#'`

ln -fs $PWD/{.vimrc,.vimhelp} ~
ln -fs $PWD/{.utils.py,.aliases_functions.sh} ~
ln -fs $PWD/.joris.omp.json ~
ln -fs $PWD/{.bash_profile,.env.sh} ~
ln -fs $PWD/{.gitconfig,.gitignore_global} ~
ln -fs $PWD/.ssh/assh.yml ~/.ssh
ln -fs $PWD/.config/gh/config.yml ~/.config/gh/config.yml
