#!/bin/bash

echo -n "Installing global .gitconfig and .gitignore files..."
cp gitconfig ~/.gitconfig
cp gitignore ~/.gitignore
echo "DONE"

echo -n "Installing patch so that branch is shown in the commandline prompt..."
cat show-branch-in-prompt.sh >> ~/.bashrc
echo "DONE"
