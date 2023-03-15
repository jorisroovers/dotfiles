#!/bin/bash
set -ux

# Install homebrew if not already installed
brew --version || NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Check if on macos or linux and ensure we can use brew below
if [ "$(uname)" == "Darwin" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 
fi

# Install all brew packages
brew bundle --file ./Brewfile

# Install fzf commandline completion
$(brew --prefix)/opt/fzf/install --all

# Link dotfiles into home directory
ln -fs $PWD/{.vimrc,.vimhelp} ~
ln -fs $PWD/{.utils.py,.aliases_functions.sh,.version-managers.sh} ~
ln -fs $PWD/.*.omp.json ~
ln -fs $PWD/{.zshrc,.bash_profile,.env.sh} ~
ln -fs $PWD/{.pdbrc,.pythonrc.py} ~
ln -fs $PWD/{.gitconfig,.gitignore_global} ~
mkdir -p ~/.ssh
ln -fs $PWD/.ssh/assh.yml ~/.ssh
mkdir -p ~/.config/gh # Create ~/.config/gh dir if it doesn't already exist
ln -fs $PWD/.config/gh/config.yml ~/.config/gh/config.yml
