export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Length of terminal history
# https://askubuntu.com/questions/1006075/increase-reverse-i-search-history-length
HISTSIZE=1000  # history of a single terminal session, saved in RAM
HISTFILESIZE=10000 # size of the history file, usually ~/.bash_history). 

# show current git branch in commandline prompt and take existing coloring
# and changes into account (e.g. .venv)
# http://martinvalasek.com/blog/current-git-branch-name-in-command-prompt
# If colors are enabled in git output, we run into an ugly bash escaping issue
# The post below provides details:
# https://stackoverflow.com/questions/19092488/custom-bash-prompt-is-overwriting-itself#
# Instead of extra escaping (which doesn't seem to fully solve the problem), we
# just force git branch to not use any colors

function parse_git_branch () {
  git -c color.ui=false branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

RED="\[\033[0;31m\]"
YELLOW="\[\033[0;33m\]"
GREEN="\[\033[0;32m\]"
NO_COLOR="\[\033[0m\]"

PS1="$GREEN\$$NO_COLOR\w$YELLOW\$(parse_git_branch)$NO_COLOR\$ "

# ALIASES
alias v='vagrant'
alias vs='vagrant status'
alias vgs='vagrant global-status'
alias vss='vagrant ssh'
alias vup='vagrant up'
alias vssh='vagrant ssh'
alias vd='vagrant destroy -f'

export HASS_IP="<redacted>"
export RPI_IP="<redacted>"
export RPITV_IP="<redacted>"
alias hass="ssh joris@$HASS_IP"
alias casa="hass"
alias rpi="ssh joris@$RPI_IP"
alias rpitv="ssh joris@$RPITV_IP"
alias cec="export CEC_USERNAME=<redacted>; read -s -p 'CEC PASSWORD: ' CEC_PASSWORD; export CEC_PASSWORD=\$CEC_PASSWORD; echo -e '\nEnvironment variables CEC_USERNAME and CEC_PASSWORD set.'"

# Adds colors to grep on mac
# http://superuser.com/questions/416835/how-can-i-grep-with-color-in-mac-os-xs-terminal
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;35;40'

# added by Anaconda2 4.3.1 installer
export PATH="/anaconda/bin:$PATH"

# added etcher-cli to PATH: https://etcher.io/cli/
# export PATH="$PATH:/opt/etcher-cli"

alias cat='bat'
alias code="code-insiders"
alias vscode="code-insiders"

# Ansible
export ANSIBLE_VAULT_PASSWORD_FILE="~/.ansible-vault-password"
export PGM_KEY_FILE="~/keys/pgm.pem"

export PATH="$HOME/.cargo/bin:$PATH"

alias honcho="cd ~/repos/honcho; open 'http://localhost:8000'; watchexec --exts rs,css,hbs --restart 'cargo run'";

function vault-get(){
  local VAULT="$(ansible-vault view ~/repos/casa-data/group_vars/all)"
  echo "$VAULT" | awk "/$1: /{print \$2}" | tr -d '\"'
}

function vault-search(){
  local VAULT="$(ansible-vault view ~/repos/casa-data/group_vars/all)"
  echo "$VAULT" | grep "$1"
}

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# fzf: https://github.com/junegunn/fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

source /Users/jroovers/.gvm/scripts/gvm

export PATH="/usr/local/opt/curl/bin:$PATH"
