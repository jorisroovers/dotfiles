#!/bin/bash
script_dir="$( cd "$( dirname "$0" )" && pwd )"
echo -n "Installing global .gitconfig and .gitignore files..."
cp $script_dir/gitconfig ~/.gitconfig
cp $script_dir/gitignore ~/.gitignore
echo "DONE"

echo -n "Installing patch so that branch is shown in the commandline prompt..."
cat $script_dir/show-branch-in-prompt.sh >> ~/.bashrc
echo "DONE"
