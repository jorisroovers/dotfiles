#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
PACKAGES_FILE="$SCRIPT_DIR/packages"

if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root"
    exit 1
fi

packages=()
already_installed=()

ask_install(){
    package=$1
    if [[ `dpkg -s $package 2> /dev/null` ]]; then
        already_installed+=( $package )
        echo "Already installed packaged '$package'."
    else
        read -e -p "Install package '$package' (Y/n): " install
        # -z -> check if empty (needed because bash doesn't like to comparison with
        # empty strings
        # ${var, ,} -> to lower case
        if [[ -z $install ]] || [ "y" == ${install,,} ]; then
            packages+=( $package )
        fi
    fi
}

# For each package in $PACKAGES_FILE, ask if it needs to be installed
for available_package in `cat $PACKAGES_FILE`
do
    ask_install $available_package
done

if [ ${#packages[@]} -gt 0 ]; then

    echo "Installing packages (CTRL+C to abort, ENTER to continue): ${packages[@]}"
    read -e

    sudo apt-get install -y ${packages[@]}

    echo "ALL DONE"
fi

