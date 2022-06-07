### ZSH ################################################################################################################

# Disable auto cd
unsetopt AUTO_CD

# Allow '#' to be used as a comment character in shell sessions
setopt interactivecomments

alias reload='exec zsh'

### OH-MY-ZSH ##########################################################################################################
# https://ohmyz.sh/
plugins=(gitfast)

export ZSH="$HOME/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh

### ENVIRONMENT (GENERIC) ##############################################################################################

[ -f ~/.env.sh ] && source ~/.env.sh

### ITERM2 #############################################################################################################
# https://iterm2.com/
# Activate shell integration. Install via "iTerm2>Install Shell Integration" menu item.
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

### ALIASES AND FUNCTIONS ##############################################################################################

[ -f ~/.aliases_functions ] && source ~/.aliases_functions

### WORK ###############################################################################################################

[ -f ~/.workrc ] && source ~/.workrc

### OH-MY-POSH #########################################################################################################
# https://ohmyposh.dev/
if [ $TERM_PROGRAM != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config ~/.joris.omp.json)"
fi

### FZF ################################################################################################################
# https://github.com/junegunn/fzf
FZF_DEFAULT_OPTS="--history-size=3000"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

### DESK ###############################################################################################################
# https://github.com/jamesob/desk
# TODO: consider using https://github.com/direnv/direnv instead
[ -n "$DESK_ENV" ] && source "$DESK_ENV" || true

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

# Python

# pyenv: https://github.com/pyenv/pyenv
eval "$(pyenv init -)"

# Ensure pip will only install in virtualenvs
export PIP_REQUIRE_VIRTUALENV=true
