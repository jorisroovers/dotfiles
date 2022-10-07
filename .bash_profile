# bash_profile: sourced for login shells only by default

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
    fi
fi

### ENVIRONMENT (GENERIC) ##############################################################################################
[ -f ~/.env.sh ] && source ~/.env.sh

### LINUXBREW ##########################################################################################################
# https://docs.brew.sh/Homebrew-on-Linux
# Has to be initialized early because it adds programs to PATH that are depended on below
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

### VERSION MANAGERS ###################################################################################################
# Needs to happen early, for runtimes to be available for scripts below
[ -f ~/.version-managers.sh ] && source ~/.version-managers.sh

### ALIASES AND FUNCTIONS ##############################################################################################

[ -f ~/.aliases_functions.sh ] && source ~/.aliases_functions.sh

### FZF ################################################################################################################
# https://github.com/junegunn/fzf
FZF_DEFAULT_OPTS="--history-size=3000"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

### OH-MY-POSH #########################################################################################################
# https://ohmyposh.dev/
eval "$(oh-my-posh init bash --config ~/.joris.omp.json)"



