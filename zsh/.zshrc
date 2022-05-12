### ENCODING ###########################################################################################################
 
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

### TERMINAL HISTORY ###################################################################################################

# Length of terminal history
# https://askubuntu.com/questions/1006075/increase-reverse-i-search-history-length
HISTSIZE=1000  # history of a single terminal session, saved in RAM
HISTFILESIZE=10000 # size of the history file, usually ~/.bash_history). 

### ALIASES AND FUNCTIONS ##############################################################################################

[ -f ~/.aliases_functions ] && source ~/.aliases_functions

### WORK ###############################################################################################################

[ -f ~/.workrc ] && source ~/.workrc

### VERSION MANAGERS ###################################################################################################

# GVM (Go): https://github.com/moovweb/gvm
source ~/.gvm/scripts/gvm

# SLOW?
# NVM (Node): https://github.com/nvm-sh/nvm
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# RVM (Ruby): https://rvm.io/
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

# pyenv (Python): https://github.com/pyenv/pyenv
eval "$(pyenv init -)"

# Ensure pip will only install in virtualenvs
export PIP_REQUIRE_VIRTUALENV=true

### MISC ###############################################################################################################
# Disable auto cd
unsetopt AUTO_CD

# Allow '#' to be used as a comment character in shell sessions
setopt interactivecomments

# fzf: https://github.com/junegunn/fzf
FZF_DEFAULT_OPTS="--history-size=3000"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export PGM_KEY_FILE="~/keys/pgm.pem"

# Adds colors to grep on mac
# http://superuser.com/questions/416835/how-can-i-grep-with-color-in-mac-os-xs-terminal
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;35;40'

eval $(thefuck --alias)

### OH-MY-POSH ###########################################################################################################
if [ $TERM_PROGRAM != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config ~/.joris.omp.json)"
fi

### PATH ###############################################################################################################

export PATH="/usr/local/opt/curl/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
# Needed for pipx (can be added by `pipx ensurepath`)
export PATH="$PATH:$HOME/.local/bin"
# Rancher Desktop
export PATH="$HOME/.rd/bin:$PATH"
