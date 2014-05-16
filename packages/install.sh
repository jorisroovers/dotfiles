#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root"
    exit 1
fi

packages=()

ask_install(){
    package=$1
    read -e -p "Install package '$package' (Y/n): " install
    # -z -> check if empty (needed because bash doesn't like to comparison with
    # empty strings
    # ${var, ,} -> to lower case
    if [[ -z $install ]] || [ "y" == ${install,,} ]; then
        packages+=( $package )
    fi
}

ask_install "vim"
ask_install "curl"
ask_install "openjdk-7-jdk"

echo "Installing packages (CTRL+C to abort): ${packages[@]}"
read -e

sudo apt-get install -y ${packages[@]}

echo "ALL DONE"
