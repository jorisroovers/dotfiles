### SHELL GENERIC  #####################################################################################################

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Length of terminal history
# https://askubuntu.com/questions/1006075/increase-reverse-i-search-history-length
HISTSIZE=1000       # history of a single terminal session, saved in RAM
HISTFILESIZE=10000  # size of the history file, usually ~/.bash_history). 

### PATH ###############################################################################################################

prependpath() {
  [ -d "$1" ] && PATH="$1:$PATH"
}
prependpath '/usr/local/bin'
prependpath "$HOME/.local/bin"
prependpath "$HOME/bin"
prependpath "$HOME/.cargo/bin" # cargo (rust)
prependpath "$HOME/.rd/bin"    # Rancher Desktop

unset prependpath
export PATH

### MISC ###############################################################################################################

export PGM_KEY_FILE=~/keys/pgm.pem

# Adds colors to grep on mac
# http://superuser.com/questions/416835/how-can-i-grep-with-color-in-mac-os-xs-terminal
# export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;35;40'

export EDITOR=vim
export PAGER=less

# Ensure pip will only install in virtualenvs
export PIP_REQUIRE_VIRTUALENV=true