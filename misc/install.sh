#!/bin/bash

config_gedit(){
   gsettings set org.gnome.gedit.preferences.editor tabs-size 4
   gsettings set org.gnome.gedit.preferences.editor create-backup-copy false
   gsettings set org.gnome.gedit.preferences.editor display-line-numbers true
   gsettings set org.gnome.gedit.preferences.editor auto-indent true
   gsettings set org.gnome.gedit.preferences.editor insert-spaces true
}

echo "Configuring gedit.."
config_gedit
echo "DONE"

