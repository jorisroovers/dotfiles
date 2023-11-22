### ZSH ################################################################################################################

# Disable auto cd
unsetopt AUTO_CD

# Allow '#' to be used as a comment character in shell sessions
setopt interactivecomments

# For terminal editing, use emacs keybindings (CTRL+A, CTRL+E for start/end of line, etc)
# This is required to override zsh subshells starting in vi mode because EDITOR=vim is set in .env.sh
# Context: https://zsh.sourceforge.io/Guide/zshguide04.html
bindkey -e

# Load shell completion (for git, etc)
autoload -Uz compinit && compinit

alias reload='exec zsh'

### OH-MY-ZSH ##########################################################################################################
# https://ohmyz.sh/
plugins=(gitfast)

[ -f ~/.oh-my-zsh ] && export ZSH="$HOME/.oh-my-zsh"
[ -f ~/.oh-my-zsh ] && source $ZSH/oh-my-zsh.sh

### ENVIRONMENT (GENERIC) ##############################################################################################

[ -f ~/.env.sh ] && source ~/.env.sh

### VERSION MANAGERS ###################################################################################################
# Needs to happen early, for runtimes to be available for scripts below
[ -f ~/.version-managers.sh ] && source ~/.version-managers.sh

### ALIASES AND FUNCTIONS ##############################################################################################

[ -f ~/.aliases_functions.sh ] && source ~/.aliases_functions.sh

### WORK ###############################################################################################################

[ -f ~/.workrc.sh ] && source ~/.workrc.sh

### DESK ###############################################################################################################
# https://github.com/jamesob/desk
# TODO: consider using https://github.com/direnv/direnv instead
[ -n "$DESK_ENV" ] && source "$DESK_ENV" || true
