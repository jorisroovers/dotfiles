#!/bin/bash
####################################
# Simple script for setting up Vim #
#                                  #
####################################
script_dir="$( cd "$( dirname "$0" )" && pwd )"

# Asserts that a package has been installed
assert_installed(){
	if ! dpkg -s $1 2>/dev/null; then
		echo "ERROR: Package '$1' is required to run this script"
		exit 1
	fi	
}

check_requirements(){
	assert_installed wget
	assert_installed git
}

RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
GREEN="\033[32m"
NO_COLOR="\033[0m"

report(){
    MSG="[$YELLOW$1$NO_COLOR]"
    echo -e $MSG
}

install(){	

	bundle_path=~/.vim/bundle

	# install pathogen
	report "Installing pathogen..."
	mkdir -p ~/.vim/autoload $bundle_path;
	wget -O ~/.vim/autoload/pathogen.vim \
    	https://raw.githubusercontent.com/tpope/vim-pathogen/master/autoload/pathogen.vim
	report "DONE"

	# install nerdTree
	report "Installing NerdTree"
	git clone https://github.com/scrooloose/nerdtree.git $bundle_path/nerdtree
	report "DONE"
    
    # L9
	report "Installing L9 (vim utility library needed by autocomplpop)"
	zipfile=$bundle_path/L9.zip
	wget -O $zipfile https://bitbucket.org/ns9tks/vim-l9/get/tip.zip
	unzip $zipfile -d $bundle_path
	rm $zipfile
	report "DONE"

    # autocomplpop
	report "Installing autocomplpop"
    zipfile=$bundle_path/autocomplpop.zip
	wget -O $zipfile \
        https://bitbucket.org/ns9tks/vim-autocomplpop/get/tip.zip
	unzip $zipfile -d $bundle_path
	rm $zipfile
	report "DONE"

    # Conque
    # cd ~/.vim/bundle
    # zipfile=$bundle_path/conque.zip
    # wget -O $zipfile http://conque.googlecode.com/files/conque_2.3.zip
    # unzip $zipfile -d $bundle_path/conque
    # rm $zipfile
    # report "DONE"

	# Copy vimrc file
	report "Copying vimrc to ~/.vimrc..."
	cp $script_dir/vimrc ~/.vimrc	
	report "DONE"

    report "Copying vimhelp to ~/.vimhelp..."
    cp $script_dir/vimhelp ~/.vimhelp
    report "DONE"
	
}

# check_requirements # disable install 
install 




