#!/bin/bash

RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
GREEN="\033[32m"
NO_COLOR="\033[0m"

report(){
    MSG="$GREEN$1$NO_COLOR"
    echo -e $MSG
}

report "*** LINUX SETUP ***"

report "[Running vim/install.sh]"
vim/install.sh

report "[Running misc/install.sh]"
misc/install.sh

report "[Running git/install.sh]"
git/install.sh

report "[Running packages/install.sh (as sudo)]"
sudo packages/install.sh

report "ALL DONE"
