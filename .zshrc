### ZSH ################################################################################################################

# Disable auto cd
unsetopt AUTO_CD

# Allow '#' to be used as a comment character in shell sessions
setopt interactivecomments

alias reload='exec zsh'

### OH-MY-ZSH ##########################################################################################################
# https://ohmyz.sh/
plugins=(gitfast)

[ -f ~/.oh-my-zsh ] && export ZSH="$HOME/.oh-my-zsh"
[ -f ~/.oh-my-zsh ] && source $ZSH/oh-my-zsh.sh

### ENVIRONMENT (GENERIC) ##############################################################################################

[ -f ~/.env.sh ] && source ~/.env.sh

### ITERM2 #############################################################################################################
# https://iterm2.com/
# Activate shell integration. Install via "iTerm2>Install Shell Integration" menu item.
[ -f  ~/.iterm2_shell_integration.zsh ] && source ~/.iterm2_shell_integration.zsh

### VERSION MANAGERS ###################################################################################################
# Needs to happen early, for runtimes to be available for scripts below
[ -f ~/.version-managers.sh ] && source ~/.version-managers.sh

### ALIASES AND FUNCTIONS ##############################################################################################

[ -f ~/.aliases_functions.sh ] && source ~/.aliases_functions.sh

### WORK ###############################################################################################################

[ -f ~/.workrc.sh ] && source ~/.workrc.sh

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
