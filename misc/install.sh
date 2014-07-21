#!/bin/bash

config_gedit(){
   gsettings set org.gnome.gedit.preferences.editor tabs-size 4
   gsettings set org.gnome.gedit.preferences.editor create-backup-copy false
   gsettings set org.gnome.gedit.preferences.editor display-line-numbers true
   gsettings set org.gnome.gedit.preferences.editor auto-indent true
   gsettings set org.gnome.gedit.preferences.editor insert-spaces true
}

download_pycharm(){
    wget -O ~/Downloads/pycharm-community-3.4.1.tar.gz \ 
        http://download.jetbrains.com/python/pycharm-community-3.4.1.tar.gz
}



echo "Configuring gedit.."
config_gedit
echo "DONE"
# There are some measures in place that prevent us to download pycharm
# automatically, so we don't do it for now.
#echo "Downloading pycharm"
#download_pycharm
#echo "DONE"
