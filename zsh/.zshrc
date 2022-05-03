### ENCODING ###########################################################################################################

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

### OH-MY-ZSH ##########################################################################################################
# oh-my-zsh needs to be near the top of .zshrc since it changes the shell itself. If you do this lower down in the file
# it will just overwrite any other changes you've made to the oh-my-zsh defaults.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster" # super slow?
plugins=(git)
source $ZSH/oh-my-zsh.sh

# Disable some agnoster theme things we don't use and that make it very slow
prompt_context(){}
prompt_hg(){} # hg (=mercurial) in particular is superslow. Mercurial is required by https://github.com/moovweb/gvm
prompt_bzr(){}
prompt_aws(){}

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

# Useful shortcuts
# Find in environment variables
alias cenv="env | grep -i "
# Trim whitespace from the beginning and end of a string
alias trim="python -c \"import sys; print('\n'.join([l.strip() for l in sys.stdin]))\""

# Vagrant
alias v='vagrant'
alias vs='vagrant status'
alias vgs='vagrant global-status'
alias vss='vagrant ssh'
alias vup='vagrant up'
alias vssh='vagrant ssh'
alias vd='vagrant destroy -f'

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

# Cisco
alias cec="export CEC_USERNAME=$(whoami); read -s '?CEC PASSWORD: ' CEC_PASSWORD; export CEC_PASSWORD=\$CEC_PASSWORD; echo -e '\nEnvironment variables CEC_USERNAME and CEC_PASSWORD set.'"
alias produsa="export PRODUSA_USERNAME=$(whoami); read -s '?PRODUSA_PASSWORD: ' PRODUSA_PASSWORD; export PRODUSA_PASSWORD=\$PRODUSA_PASSWORD; echo -e '\nEnvironment variables PRODUSA_USERNAME and PRODUSA_PASSWORD set.'"

alias jumphost="ssh iotcc_jumphost"
alias fjump="pkill ssh;ssh iotcc_jumphost -fN"

### PATH ###############################################################################################################

export PATH="/usr/local/opt/curl/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
# Needed for pipx (can be added by `pipx ensurepath`)
export PATH="$PATH:/Users/jroovers/.local/bin"

### VERSION MANAGERS ###################################################################################################

# GVM (Go): https://github.com/moovweb/gvm
source ~/.gvm/scripts/gvm

# NVM (Node): https://github.com/nvm-sh/nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# RVM (Ruby): https://rvm.io/
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

# pyenv (Python): https://github.com/pyenv/pyenv
eval "$(pyenv init -)"

# Ensure pip will only install in virtualenvs
export PIP_REQUIRE_VIRTUALENV=true

### MISC ###############################################################################################################
# Disable auto cd
unsetopt AUTO_CD

# fzf: https://github.com/junegunn/fzf
FZF_DEFAULT_OPTS="--history-size=3000"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export PGM_KEY_FILE="~/keys/pgm.pem"

# Adds colors to grep on mac
# http://superuser.com/questions/416835/how-can-i-grep-with-color-in-mac-os-xs-terminal
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;35;40'
