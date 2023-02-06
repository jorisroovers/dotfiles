#!/bin/bash
set -ux

# Install homebrew if not already installed
brew --version || NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" # ensure we can use brew below

install_brew_package(){
    brew list $1 || brew install -v $1
}

install_brew_package lsd
install_brew_package bat
install_brew_package git
install_brew_package git-delta
install_brew_package jq
install_brew_package gh
install_brew_package ripgrep
install_brew_package oh-my-posh
install_brew_package fzf
install_brew_package vim

# Nerd-font installation doesn't work via homebrew on linux (only on macOS),
# but oh-my-posh provides a way to install it easily :-)
# Note: technically not required on remote host, as the rendering happens
# client-side (so really no need to install in .e.g Github Codespace
oh-my-posh font install hack

# Install fzf commandline completion
$(brew --prefix)/opt/fzf/install --all


# TODO: do install of `cat brew.sh  | grep -v '#'`

ln -fs $PWD/{.vimrc,.vimhelp} ~
ln -fs $PWD/{.utils.py,.aliases_functions.sh,.version-managers.sh} ~
ln -fs $PWD/.joris.omp.json ~
ln -fs $PWD/{.zshrc,.bash_profile,.env.sh} ~
ln -fs $PWD/{.pdbrc,.pythonrc.py} ~
ln -fs $PWD/{.gitconfig,.gitignore_global} ~
ln -fs $PWD/.ssh/assh.yml ~/.ssh
mkdir  ~/.config/gh # Create ~/.config/gh dir if it doesn't already exist
ln -fs $PWD/.config/gh/config.yml ~/.config/gh/config.yml
