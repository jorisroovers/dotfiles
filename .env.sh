### SHELL GENERIC  #####################################################################################################

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Length of terminal history
# https://askubuntu.com/questions/1006075/increase-reverse-i-search-history-length
HISTSIZE=1000       # history of a single terminal session, saved in RAM
HISTFILESIZE=10000  # size of the history file, usually ~/.bash_history). 


### BREW ###############################################################################################################

# On Apple Silicon, Homebrew is installed in /opt/homebrew and needs to be added to the PATH explicitly
# https://earthly.dev/blog/homebrew-on-m1/
[ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

### PATH ###############################################################################################################

prependpath() {
  [ -d "$1" ] && PATH="$1:$PATH"
}
prependpath '/usr/local/bin'
prependpath "$HOME/.local/bin"
prependpath "$HOME/bin"
prependpath "$HOME/.cargo/bin" # cargo (rust)
prependpath "$HOME/.rd/bin"    # Rancher Desktop

# unset prependpath
export PATH

### PYTHON #############################################################################################################

# Ensure pip will only install in virtualenvs
#export PIP_REQUIRE_VIRTUALENV=true

# Make Hatch use the local virtualenv
# https://hatch.pypa.io/1.6/plugins/environment/virtual/#options
export HATCH_ENV_TYPE_VIRTUAL_PATH=".venv"

# Use pdbr for debugging: 
export PYTHONBREAKPOINT=pdbr.set_trace
export PYTHONSTARTUP="$HOME/.pythonrc.py"

### Github Co Pilot ####################################################################################################

# Install ?? gh?? and git?? aliases
which github-copilot-cli &> /dev/null && eval "$(github-copilot-cli alias -- "$0")"

### MISC ###############################################################################################################

export PGM_KEY_FILE=~/keys/pgm.pem

# Adds colors to grep on mac
# http://superuser.com/questions/416835/how-can-i-grep-with-color-in-mac-os-xs-terminal
# export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;35;40'

export EDITOR=vim
export PAGER=less

