### ENCODING ###########################################################################################################
 
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

### TERMINAL HISTORY ###################################################################################################

# Length of terminal history
# https://askubuntu.com/questions/1006075/increase-reverse-i-search-history-length
HISTSIZE=1000  # history of a single terminal session, saved in RAM
HISTFILESIZE=10000 # size of the history file, usually ~/.bash_history). 

### ANSIBLE  ###########################################################################################################
export ANSIBLE_VAULT_PASSWORD_FILE="~/.ansible-vault-password"

function vault-get(){
  local VAULT="$(ansible-vault view ~/repos/casa-data/group_vars/all)"
  echo "$VAULT" | awk "/$1: /{print \$2}" | tr -d '\"'
}

function vault-search(){
  local VAULT="$(ansible-vault view ~/repos/casa-data/group_vars/all)"
  echo "$VAULT" | grep "$1"
}

# Get host IP. Usage: ansible-host <hostname>
function ansible-host(){
  ansible-inventory -i ~/repos/casa-data/inventory/prod --list | jq -r ."$1.hosts[0]"
}

# Get variable for a given host. Usage: ansible-inventory-get <host> <varname>
function ansible-inventory-get(){
  ansible-inventory -i ~/repos/casa-data/inventory/prod --host $1 | jq -r .$2
}


### ALIASES  ###########################################################################################################
alias reload='exec zsh'

# Program overrides
alias cat='bat'  # https://github.com/sharkdp/bat
#alias find='fd' # https://github.com/sharkdp/fd
alias ls="lsd"   # https://github.com/Peltoche/lsdexport 

# Program aliases
alias excel="open -a 'Microsoft Excel'"
alias code="code-insiders"
alias vscode="code-insiders"

# Check environment variables: shorthand or `env | grep i <foo>`. Redacts passwords and tokens.
cenv(){
  env | grep -i $1 |  \
  sed -E "s/(.*)PASSWORD=(.*)/\1PASSWORD=<redacted>/" | \
  sed -E "s/(.*)TOKEN=(.*)/\1TOKEN=<redacted>/"
}

# DATA MANIPULATION
# Trim whitespace from the beginning and end of a string
alias trim="python -c \"import sys; print('\n'.join([l.strip() for l in sys.stdin]))\""
alias lower="tr '[:upper:]' '[:lower:]'"
alias upper="tr '[:lower:]' '[:upper:]'"
# Replace whitespace with newlines
alias w2nl='tr "\t| " "\n"'
alias lsplit='w2nl'

# scratchpad
alias sc="cat /tmp/scratchpad.txt"
alias scn="pbpaste > /tmp/scratchpad.txt;sc"
alias sce="code /tmp/scratchpad.txt"

# Vagrant
alias v='vagrant'
alias vs='vagrant status'
alias vgs='vagrant global-status'
alias vss='vagrant ssh'
alias vup='vagrant up'
alias vssh='vagrant ssh'
#alias vd='vagrant destroy -f' # conflicts with visidata

# Home automation
#export RPI_IP="$(ansible-host energy_tracker)"
#export RPITV_IP="$(ansible-host tv_controller)"

#alias rpi="ssh joris@$RPI_IP"
#alias rpitv="ssh joris@$RPITV_IP"
#alias octopi="ssh joris@octopi.local"

#alias casa-pass="ansible-inventory-get controller ansible_sudo_pass | pbcopy"
#alias rpi-pass="ansible-inventory-get energy_tracker ansible_sudo_pass | pbcopy"
#alias rpitv-pass="ansible-inventory-get tv_controller ansible_sudo_pass | pbcopy"
#alias octopi-pass="ansible-inventory-get octopi ansible_sudo_pass | pbcopy"

# TODO: figure out shorthand for sourcing files
# ls -R ~/.rc | fzf
alias myfoo="source ~/.rc/ldap/test"

# Unset env vars based on regex matching (case insensitive)
unsetall(){
  unset $(cenv $1 | awk -F "=" '{print $1}')
}

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
