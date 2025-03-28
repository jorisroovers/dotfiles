### SHELL GENERIC  #####################################################################################################

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Length of terminal history
# https://askubuntu.com/questions/1006075/increase-reverse-i-search-history-length
HISTSIZE=1000       # history of a single terminal session, saved in RAM
HISTFILESIZE=10000  # size of the history file, usually ~/.bash_history). 

# Determine SHELL_NAME
# We use to do this from the full path of $SHELL (similar to using $0), but the problem is that
# SHELL points to the login/default shell, which is not necessarily the shell we are currently using.
# SHELL_NAME="${SHELL##*/}" # this doesn't work reliably
if [ -n "$BASH_VERSION" ]; then
    SHELL_NAME="bash"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_NAME="zsh"
else
    SHELL_NAME="unknown"
fi

### ITERM2 #############################################################################################################
# https://iterm2.com/
# Activate shell integration. Install via "iTerm2>Install Shell Integration" menu item.
# [ -f  ~/.iterm2_shell_integration.$SHELL_NAME ] && source ~/.iterm2_shell_integration.$SHELL_NAME

### BREW ###############################################################################################################

# On Apple Silicon, Homebrew is installed in /opt/homebrew and needs to be added to the PATH explicitly
# https://earthly.dev/blog/homebrew-on-m1/
[ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
# Linux Brew
[ -f /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

### PATH ###############################################################################################################

prependpath() {
  [ -d "$1" ] && PATH="$1:$PATH"
}
prependpath '/usr/local/bin'
prependpath "$HOME/.local/bin"
prependpath "$HOME/bin"
prependpath "$HOME/.cargo/bin" # cargo (rust)
# prependpath "$HOME/.rd/bin"    # Rancher Desktop

# [ -f /usr/local/anaconda3/bin/conda ] && prependpath "/usr/local/anaconda3/bin"

# unset prependpath
export PATH

### Github Co Pilot ####################################################################################################

# Install ?? gh?? and git?? aliases
which github-copilot-cli &> /dev/null && eval "$(github-copilot-cli alias -- "$0")"

### OH-MY-POSH #########################################################################################################

# https://ohmyposh.dev/
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init $SHELL_NAME --config ~/.joris-newline.omp.json)"
fi

### FZF ################################################################################################################
# https://github.com/junegunn/fzf
FZF_DEFAULT_OPTS="--history-size=3000"
[ -f ~/.fzf.zsh ] && source ~/.fzf.$SHELL_NAME

### PYTHON #############################################################################################################

# Ensure pip will only install in virtualenvs
#export PIP_REQUIRE_VIRTUALENV=true

# Make Hatch use the local virtualenv
# https://hatch.pypa.io/1.6/plugins/environment/virtual/#options
export HATCH_ENV_TYPE_VIRTUAL_PATH=".venv"

# Use pdbr for debugging: 
export PYTHONBREAKPOINT=pdbr.set_trace
export PYTHONSTARTUP="$HOME/.pythonrc.py"


### MISC ###############################################################################################################

# Bat's default theme on MacOS is hard to read in iTerm2
export BAT_THEME=1337

export PGM_KEY_FILE=~/keys/pgm.pem

# Adds colors to grep on mac
# http://superuser.com/questions/416835/how-can-i-grep-with-color-in-mac-os-xs-terminal
# export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;35;40'

export EDITOR=vim
export PAGER=less
