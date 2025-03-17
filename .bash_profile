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

### VERSION MANAGERS ###################################################################################################
# Needs to happen early, for runtimes to be available for scripts below
[ -f ~/.version-managers.sh ] && source ~/.version-managers.sh

### ALIASES AND FUNCTIONS ##############################################################################################

[ -f ~/.aliases_functions.sh ] && source ~/.aliases_functions.sh

### WORK ###############################################################################################################

[ -f ~/.workrc.sh ] && source ~/.workrc.sh
