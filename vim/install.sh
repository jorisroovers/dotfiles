#!/bin/bash
####################################
# Simple script for setting up Vim #
#                                  #
####################################

install(){

	# install pathogen
	echo "Installing pathogen..."
	mkdir -p ~/.vim/autoload ~/.vim/bundle;
	curl -Sso ~/.vim/autoload/pathogen.vim \
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

install 




