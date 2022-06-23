# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
    fi
fi

### ENVIRONMENT (GENERIC) ##############################################################################################

[ -f ~/.env.sh ] && source ~/.env.sh

### ALIASES AND FUNCTIONS ##############################################################################################

[ -f ~/.aliases_functions.sh ] && source ~/.aliases_functions.sh

### FZF ################################################################################################################
# https://github.com/junegunn/fzf
FZF_DEFAULT_OPTS="--history-size=3000"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

### OH-MY-POSH #########################################################################################################
# https://ohmyposh.dev/
eval "$(oh-my-posh init bash --config ~/.joris.omp.json)"


### LINUXBREW ##########################################################################################################
# https://docs.brew.sh/Homebrew-on-Linux
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

