### SHELL UTILITIES ####################################################################################################
alias choose="fzf --height 10"
alias fchoose="ls | choose"

# Check environment variables: shorthand or `env | grep i <foo>`. Redacts passwords and tokens.
cenv(){
    env | grep -i $1 |  \
    sed -E "s/(.*)PASSWORD=(.*)/\1PASSWORD=<redacted>/" | \
    sed -E "s/(.*)TOKEN=(.*)/\1TOKEN=<redacted>/"
}

# Unset env vars based on regex matching (case insensitive)
unsetall(){
    unset $(cenv $1 | awk -F "=" '{print $1}')
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

### FILE I/O ###########################################################################################################

random-filename(){
    prefix=${1:-"file-"}
    echo "$prefix$(human-timestamp)"
}

temp-filepath(){
    echo "/tmp/$(random-filename $1)"
}

### PROCESS MGMT #######################################################################################################

unbloat(){
    pkill "Microsoft Excel"
}

### FOCUS MODES  #######################################################################################################

# Copies select dotfiles to dotfiles repo on `menthol` server
copy-dotfiles() {
    target="joris@menthol.local:~/repos/dotfiles"
    # use /./ in rsync to tell rsync to copy the path from that point forward
    # Thanks sir! https://serverfault.com/a/973844/166001
    rsync --relative ~/./{.env.sh,.aliases_functions.sh,.gitconfig,.gitignore_global,.joris.omp.json,.utils.py,.zshrc,brew.sh,.vimrc} $target
    rsync --relative ~/./{.config/gh/config.yml,.ssh/assh.yml} $target
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

### DATA WRANGLING  ####################################################################################################
# .utils.py is a python script that contains functions for data wrangling
# While some of these could be written as pure shell functions, python makes many functions simpler and portable across
# shells.
alias _u="python ~/.utils.py"
eval "$(_u _install_aliases _u)"

ldiff(){
    _u linecompare $1 $2 | less -SR
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

### ANSIBLE  ###########################################################################################################
export ANSIBLE_VAULT_PASSWORD_FILE="~/.ansible-vault-password"

vault-get(){
    local VAULT="$(ansible-vault view ~/repos/casa-data/group_vars/all)"
    echo "$VAULT" | awk "/$1: /{print \$2}" | tr -d '\"'
}

vault-search(){
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
