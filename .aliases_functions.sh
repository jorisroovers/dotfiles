### SHELL UTILITIES ####################################################################################################
alias choose="fzf --height 10"
alias fchoose="ls | choose"

# Check environment variables: shorthand or `env | grep i <foo>`. Redacts passwords and tokens.
cenv(){
    # Filter output
    if [ -n "$1" ]; then
        output=$(env | grep -i $1 --color=always)
    else
        output=$(env)
    fi
    # Redact passwords and tokens, mark empty vars
    echo $output |  \
    sed -E "s/(.*)PASSWORD=(.+)/\1PASSWORD=<redacted (non-empty)>/" | \
    sed -E "s/(.*)TOKEN=(.+)/\1TOKEN=<redacted (non-empty)>/" | \
    sed -E "s/(.*)SECRET(.*)=(.+)/\1SECRET\2=<redacted (non-empty)>/" | \
    sed -E "s/(.*)ROLE_ID(.*)=(.+)/\1ROLE_ID\2=<redacted (non-empty)>/" | \
    sed -E "s/(.*)=$/\1=<empty>/"
}

# Unset env vars based on regex matching (case insensitive)
unsetall(){
    unset $(env | grep -i $1 | awk -F "=" '{print $1}')
}

# Edit an ENV VAR in $EDITOR, then export it back to the shell
editvar(){
    envvar=$(env | choose)
    tempfile=$(temp-filepath)
    echo "$envvar" > $tempfile
    $EDITOR $tempfile
    eval "export $(cat $tempfile)"
    cat $tempfile
}

# Select dotfile to source from .rc directory
sl(){
    source $(find ~/.rc  -type f | choose)
}

# Shows definition of passed alias or function
define(){
    type $1
    declare -f $1 | bat -p --language sh || return 0 # declare only on functions, don't error out if $1 is an alias
}

# default: returns a default value if STDIN is empty, otherwise return STDIN
default() {
    grep . || echo $1
    #  awk '{print ($0 == "" ? "'$1'" : $0)}'
}

line(){
    linechar=${1:-"#"}
    python -c "print('\033[0;36m' + ('$linechar' * $(tput cols) + '\033[0m'))"
    # printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
}

# o2f: output-to-file. Runs a command and writes the output to a file, returns filename
# NOTE: should be the same as <(some command), consider removing this
o2f(){
    file=$(temp-filepath)
    echo $file
    eval "$@" > $file
}

### TIME ###############################################################################################################

# Human friendly timestamp
human-timestamp(){
    date +'%Y-%m-%d_%H-%M-%S'
}

today(){
    date +'%Y-%m-%d'
}

### FILE I/O ###########################################################################################################

random-filename(){
    prefix=${1:-"file-"}
    echo "$prefix$(human-timestamp)"
}

temp-filepath(){
    echo "/tmp/$(random-filename $1)"
}

### PROCESS MGMT #######################################################################################################

mykill(){
    process=$(ps -ef | rg -i $1 | choose)
    echo $process | awk '{print $2}' | xargs kill -9
    echo "Killed: $process"
}

unbloat(){
    pkill "Microsoft Excel"
}

### FOCUS MODES  #######################################################################################################

# Copies select dotfiles to dotfiles repo on `menthol` server
copy-dotfiles() {
    target="joris@menthol.local:~/repos/dotfiles"
    # use /./ in rsync to tell rsync to copy the path from that point forward
    # Thanks sir! https://serverfault.com/a/973844/166001
    # --copy-links: if the local files are symlinks, resolve them first and copy the actual files, not the symlinks
    rsync --copy-links --relative ~/./{.env.sh,.aliases_functions.sh,.version-managers.sh} $target
    rsync --copy-links --relative ~/./{.tool-versions,.*.omp.json,.utils.py,.zshrc,.vimrc} $target
    # git
    rsync --copy-links --relative ~/./{.gitconfig,.gitignore_global} $target
    # python
    rsync --copy-links --relative ~/./{.pdbrc,.pythonrc.py} $target
    # Misc
    rsync --copy-links --relative ~/./{.config/gh/config.yml,.ssh/assh.yml,.hammerspoon/cheatsheets.lua} $target
    # vscode
    rsync --copy-links --relative ~/Library/Application\ Support/Code\ -\ Insiders/User/{settings,keybindings}.json $target/vscode
}

focus-personal(){
    pkill "Microsoft Excel"
    pkill "Microsoft PowerPoint"
    pkill "Microsoft Outlook"
    pkill "Webex Teams"
    pkill "draw.io"
    pkill "SimpleMind"
}

focus-work(){
    open -a 'Microsoft Outlook'
    open -a 'Webex Teams'
}

### PROGRAM OVERRIDES  #################################################################################################
alias cat='bat'                 # https://github.com/sharkdp/bat
#alias find='fd'                # https://github.com/sharkdp/fd
alias ls="lsd"                  # https://github.com/Peltoche/lsdexport 
alias ssh="assh wrapper ssh --" # https://github.com/moul/assh

# Program aliases
alias excel="open -a 'Microsoft Excel'"
alias code="code-insiders"
alias vscode="code-insiders"
alias pc="pre-commit"

### DATA WRANGLING  ####################################################################################################
# .utils.py is a python script that contains functions for data wrangling
# While some of these could be written as pure shell functions, python makes many functions simpler and portable across
# shells.
alias _u="python ~/.utils.py"
eval "$(_u _install_aliases _u)"

ldiff(){
    _u linecompare $1 $2 | less -SR
}

csvdiff(){
    echo "$1: $(xsv count $1)x$(xsv headers $1 | wc -l | tr -d ' ')"
    echo "$2: $(xsv count $2)x$(xsv headers $2 | wc -l | tr -d ' ')"
    _u csvcompare $1 $2 $3 | xsv table
}

xlsdiff(){
    # Uses xlsx2csv to convert, and then does a CSV compare: https://github.com/dilshod/xlsx2csv
    _u csvcompare <(xlsx2csv -n Data $1) <(xlsx2csv -n Data $2) $3 | xsv table
}

xlsview(){
    xlsx2csv -n Data $1 | xsv table
}

xlscount(){
    xlsx2csv -n Data $1 | xsv count
}

# Show frequency table
frequency() {
    sort | uniq -c | sort -nr | trim
}

# stats() {
#   echo "Lines Count: $(wc -l | trim)"
#   echo "Unique Lines: $(sort | uniq | wc -l | trim)"
# }

### SCRATCHPAD #########################################################################################################
alias sc="cat /tmp/scratchpad.txt"
scn(){
    # replace windows newlines with unix newlines (required when copying from excel)
    pbpaste | sd "\r\n" "\n" > /tmp/scratchpad.txt
    sc # show scratchpad
}
alias sce="code /tmp/scratchpad.txt"

### DESK  ##############################################################################################################

# https://github.com/jamesob/desk
alias dl="desk list"
desk_choose(){
    desk list | choose | awk '{print $1}'
}

ds() { # Desk "switch"
    if [ $SHLVL -gt 1 ]; then
        echo "Exiting current subshell; run ds again"
        kill $$
    fi
    desk go $(desk_choose)
}
de(){
    code-insiders ~/.desk/desks/$(desk_choose).sh
}

### PYTEST #############################################################################################################

# TODO: still WIP, easily extract paths from pytest output
pypaths() {
    pbpaste | split "," | awk '{print $3}' | sd "local\('" "" | sd "'\)" "" | xargs -L2 echo ldiff
}

### HASHICORP VAULT ####################################################################################################

hvault_login(){
    error_msg="Required env vars: VAULT_ADDR, VAULT_NAMESPACE, VAULT_ROLE_ID, VAULT_SECRET_ID"
    [ -z ${VAULT_ADDR} ] && echo $error_msg && return 1
    [ -z ${VAULT_NAMESPACE} ] && echo $error_msg && return 1
    [ -z ${VAULT_ROLE_ID} ] && echo $error_msg && return 1
    [ -z ${VAULT_SECRET_ID} ] && echo $error_msg && return 1

    VAULT_RESPONSE=$(vault write auth/approle/login role_id=$VAULT_ROLE_ID secret_id=$VAULT_SECRET_ID -format=json)
    export VAULT_TOKEN=$(echo $VAULT_RESPONSE | jq -r .auth.client_token)
}

### ANSIBLE  ###########################################################################################################
#export ANSIBLE_VAULT_PASSWORD_FILE="~/.ansible-vault-password"

# Re-use (a)ssh controlpath for ssh connections
# ANSIBLE_SSH_COMMON_ARGS applies to ssh/scp/sftp connections, vs. ANSIBLE_SSH_EXTRA_ARGS which is for SSH only
export ANSIBLE_SSH_COMMON_ARGS="-o ControlMaster=auto -o ControlPersist=yes -o ControlPath=~/.ssh/socket-%h-%p-%r.sock"

# Speeds up connections, but can cause issues with some target hosts:
# https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-pipelining
export ANSIBLE_PIPELINING=1


ansible-vault-get(){
    local VAULT="$(ansible-vault view ~/repos/casa-data/group_vars/all)"
    echo "$VAULT" | awk "/$1: /{print \$2}" | tr -d '\"'
}

ansible-vault-search(){
    local VAULT="$(ansible-vault view ~/repos/casa-data/group_vars/all)"
    echo "$VAULT" | grep "$1"
}

# Get host IP. Usage: ansible-host <hostname>
ansible-host(){
    ansible-inventory -i ~/repos/casa-data/inventory/prod --list | jq -r ."$1.hosts[0]"
}

# Get variable for a given host. Usage: ansible-inventory-get <host> <varname>
ansible-inventory-get(){
    ansible-inventory -i ~/repos/casa-data/inventory/prod --host $1 | jq -r .$2
}

### VAGRANT  ###########################################################################################################
alias v='vagrant'
alias vs='vagrant status'
alias vgs='vagrant global-status'
alias vss='vagrant ssh'
alias vup='vagrant up'
alias vssh='vagrant ssh'
#alias vd='vagrant destroy -f' # conflicts with visidata

### LDAP  ##############################################################################################################
lds(){
    ldapsearch -o ldif-wrap=no -H $LDAP_HOST -w $LDAP_PASSWORD -D $LDAP_BIND -b $LDAP_BASE_SEARCH $1
}

### Device42  ##########################################################################################################

d42get(){
    curl -s -k -u "$D42_USERNAME:$D42_PASSWORD" "$D42_BASE_URL$@"
}
d42post(){
    curl -s -k -u "$D42_USERNAME:$D42_PASSWORD" -X POST "$D42_BASE_URL$@"
}
d42put(){
    curl -s -k -u "$D42_USERNAME:$D42_PASSWORD"  -X PUT "$D42_BASE_URL$@"
}
d42delete(){
    curl -s -k -u "$D42_USERNAME:$D42_PASSWORD"  -X DELETE "$D42_BASE_URL$@"
}
