# mise (https://github.com/jdxcode/mise)
[[ -s "$(brew --prefix mise)/bin/mise" ]] && eval "$($(brew --prefix mise)/bin/mise activate $SHELL_NAME)"

# ASDF (version manager to rule them all!): https://asdf-vm.com/
# [[ -s "$(brew --prefix asdf)/libexec/asdf.sh" ]] && source "$(brew --prefix asdf)/libexec/asdf.sh"

# GVM (Go): https://github.com/moovweb/gvm
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source $HOME/.gvm/scripts/gvm

# SLOW?
# NVM (Node): https://github.com/nvm-sh/nvm
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# RVM (Ruby): https://rvm.io/
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

# pyenv (Python): https://github.com/pyenv/pyenv
# eval "$(pyenv init -)"

# sdkman (Java): https://sdkman.io/
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
