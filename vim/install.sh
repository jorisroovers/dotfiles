#!/bin/bash
####################################
# Simple script for setting up Vim #
#                                  #
####################################

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

install(){	

	# install pathogen
	echo "Installing pathogen..."
	mkdir -p ~/.vim/autoload ~/.vim/bundle;
	wget -O ~/.vim/autoload/pathogen.vim \
    	https://raw.githubusercontent.com/tpope/vim-pathogen/master/autoload/pathogen.vim
	echo "DONE"

	# install nerdTree
	echo "Installing NerdTree"
	git clone https://github.com/scrooloose/nerdtree.git ~/.vim/bundle/nerdtree
	echo "DONE"

	# Copy vimrc file
	echo -n "Copying vimrc to ~/.vimrc..."
	cp vimrc ~/.vimrc		
	echo "DONE"
	
}

check_requirements
install 




