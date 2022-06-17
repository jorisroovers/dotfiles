#!/bin/bash
set -x

# cp .joris.omp.json ~

# cp {.gitconfig,.gitignore_global} ~

# cp {.utils.py,.aliases_functions} ~

# cp .env.sh ~

# cp {.vimrc,.vimhelp} ~

ln -fs $PWD/{.vimrc,.vimhelp} ~
ln -fs $PWD/{.utils.py,.aliases_functions.sh} ~
ln -fs $PWD/.joris.omp.json ~
ln -fs $PWD/{.bash_profile,.env.sh} ~
ln -fs $PWD/{.gitconfig,.gitignore_global} ~
