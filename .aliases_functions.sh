### HOMEBREW  ##########################################################################################################

# Show outdated packages grouped by major/minor/patch with changelogs from GitHub releases.
# Changelogs shown for major+minor (and patch with -v). Pipe output through less.
brew-changelog(){
    local verbose=0
    [[ "$1" == "-v" ]] && verbose=1

    local brew_json
    brew_json=$(brew outdated --json)

    BREW_JSON="$brew_json" BREW_VERBOSE="$verbose" python3 <<'PYEOF' | less -RF
import json, os, subprocess, urllib.request, re

RESET  = '\033[0m'
BOLD   = '\033[1m'
DIM    = '\033[2m'
RED    = '\033[91m'
YELLOW = '\033[93m'
CYAN   = '\033[96m'
BLUE   = '\033[94m'
WHITE  = '\033[97m'

verbose = os.environ['BREW_VERBOSE'] == '1'
data = json.loads(os.environ['BREW_JSON'])

major, minor, patch = [], [], []
for pkg in data['formulae']:
    name = pkg['name']
    current = pkg['installed_versions'][0] if pkg['installed_versions'] else '0'
    latest = pkg['current_version']
    cur = current.split('.')
    new = latest.split('.')
    entry = (name, current, latest)
    if cur[:1] != new[:1]:
        major.append(entry)
    elif cur[1:2] != new[1:2]:
        minor.append(entry)
    else:
        patch.append(entry)

need_info = [n for n, _, _ in major + minor] + ([n for n, _, _ in patch] if verbose else [])
pkg_info = {}
if need_info:
    result = subprocess.run(['brew', 'info', '--json=v2'] + need_info, capture_output=True, text=True)
    if result.returncode == 0:
        for f in json.loads(result.stdout).get('formulae', []):
            info = {
                'homepage': f.get('homepage', ''),
                'source_url': (f.get('urls') or {}).get('stable', {}).get('url', ''),
            }
            pkg_info[f['name']] = info
        # Also index by tap-qualified names (e.g. 'hashicorp/tap/vault' -> 'vault')
        for orig in need_info:
            short = orig.split('/')[-1]
            if short in pkg_info and orig not in pkg_info:
                pkg_info[orig] = pkg_info[short]

def parse_ver(v):
    v = re.sub(r'^[^0-9]*', '', v)
    parts = re.split(r'[.\-_]', v)
    result = []
    for p in parts:
        try:
            result.append((0, int(p)))
        except ValueError:
            result.append((1, p))
    return result

def ver_in_range(tag, cur, lat):
    try:
        return parse_ver(cur) < parse_ver(tag) <= parse_ver(lat)
    except Exception:
        return False

def github_owner_repo(url):
    # Match github.com/owner/repo anywhere in the URL (handles tarball/archive paths too)
    m = re.search(r'github\.com/([^/]+)/([^/]+?)(?:\.git|/|$)', url or '')
    return (m.group(1), m.group(2)) if m else None

def fetch_releases(info, cur, lat):
    for url in [info.get('source_url', ''), info.get('homepage', '')]:
        parsed = github_owner_repo(url)
        if parsed:
            owner, repo = parsed
            api_url = f"https://api.github.com/repos/{owner}/{repo}/releases?per_page=50"
            try:
                req = urllib.request.Request(api_url, headers={'User-Agent': 'brew-changelog'})
                with urllib.request.urlopen(req, timeout=8) as r:
                    releases = json.loads(r.read())
                relevant = [r for r in releases if ver_in_range(r['tag_name'], cur, lat)]
                return relevant, f"https://github.com/{owner}/{repo}/releases"
            except Exception:
                pass
    return None, info.get('homepage', '')

def print_group(color, title, entries, show_changelog):
    if not entries:
        return
    print(f"\n{BOLD}{color}{'═' * 80}{RESET}")
    print(f"{BOLD}{color}  {title} ({len(entries)}){RESET}")
    print(f"{BOLD}{color}{'═' * 80}{RESET}")
    for name, current, latest in entries:
        print(f"\n{BOLD}{WHITE}  {name}{RESET}  {DIM}{current} → {latest}{RESET}")
        if not show_changelog:
            continue
        info = pkg_info.get(name, {})
        releases, fallback_url = fetch_releases(info, current, latest)
        if releases:
            for rel in reversed(releases):
                print(f"\n  {BOLD}{BLUE}── {rel['tag_name']} ──{RESET}")
                body = (rel.get('body') or '').strip()
                if body:
                    for line in body.splitlines():
                        print(f"  {line}")
                else:
                    print(f"  {DIM}(no release notes){RESET}")
        elif fallback_url:
            print(f"  {DIM}Changelog: {fallback_url}{RESET}")

print_group(RED,    "Major Updates", major, show_changelog=True)
print_group(YELLOW, "Minor Updates", minor, show_changelog=True)
print_group(CYAN,   "Patch Updates", patch, show_changelog=verbose)
PYEOF
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

### SHELL UTILITIES ####################################################################################################
alias choose="fzf --height 10"
alias fchoose="ls | choose"

# Check environment variables: shorthand or `env | grep i <foo>`. Redacts passwords and tokens.
cenv(){
    # Parse options
    redact_data=1
    if [ "$1" = "--help" ]; then
        echo "-p: plain (don't redact)"
        return
    elif [ "$1" = "-p" ]; then
        redact_data=0
        shift
    fi

    output=$(env)

    # Redacting
    if [ $redact_data -eq 1 ]; then
        # Extract sensitive values
        sensitive_values=()
        for var in $(echo "$output"  | grep -E "PASSWORD|TOKEN|SECRET|KEY|ROLE_ID" | cut -d '=' -f 2-); do
            escaped_val=$(echo "$var" | sed 's/[]\/$*.^+[]/\\&/g')
            sensitive_values+=($escaped_val)
        done

        # Redact sensitive values from all variables
        for val in "${sensitive_values[@]}"; do
            output=$(echo "$output" | sed -E "s/$val/<redacted>/g")
        done

        # Mark empty variables and exclude PS1
        output=$(echo "$output" | grep -ve "^PS1" | sed -E "s/([^=]+)=$/\1=<empty>/")
    fi

    # Filter output if a search string is passed
    if [ -n "$1" ]; then
        output=$(echo "$output" | grep -i $1 --color=always)
    fi

    echo "$output"
}

# Unset env vars based on regex matching (case insensitive)
unsetall(){
    # Get matching variable names as a newline-separated string
    vars=$(env | grep -i "$1" | awk -F "=" '{print $1}')
    # Convert newline-separated variable names to an array in a cross-shell compatible manner
    if [[ -n "$vars" ]]; then
        # Use a while loop to read each line
        while IFS= read -r var; do
            unset "$var"
        echo "Unset: $var"
        done <<< "$vars"
    fi
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
    echo "Use alias 'se' to easily edit these files"
    # find -L: follow symlinks
    source $(find -L ~/.rc  -type f | choose)
}

se(){
    echo "Use alias 'se' to easily edit these files"
    # find -L: follow symlinks
    code $(find -L ~/.rc  -type f | choose)
}


# Shows definition of passed alias or function
define(){
    # type $1
    alias $1 | bat -p --language sh # this is a no-op on functions, so we can safely run it on both aliases and functions
    declare -f $1 | bat --style numbers,grid --language sh || return 0 # declare only on functions, don't error out if $1 is an alias
}

# Shows definitions of functions whose names match the supplied text (case-insensitive).
define_all() {
    local function_names=""

    if [ -n "$BASH_VERSION" ]; then
        function_names=$(declare -F | awk '{print $3}')
    elif [ -n "$ZSH_VERSION" ]; then
        function_names=$(print -l ${(k)functions})
    fi

    local matches
    matches=$(printf '%s\n' "$function_names" | grep -i -- "$1")

    while IFS= read -r match; do
        [ -n "$match" ] && define "$match"
    done <<< "$matches"
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

### NETWORKING #########################################################################################################

set-etc-hosts() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: $0 <hostname> <ip-address>"
        return 1
    fi

    HOSTNAME="$1"
    NEW_IP="$2"

    if grep -q "$HOSTNAME" /etc/hosts; then
        # sudo sed -i "" "s/^[0-9\.]*\s*$HOSTNAME/$NEW_IP $HOSTNAME/" /etc/hosts
        sudo sed -i "" "s/^[0-9\.]* $HOSTNAME/$NEW_IP $HOSTNAME/" /etc/hosts
        echo "IP address for $HOSTNAME updated to $NEW_IP."
    else
        echo "$HOSTNAME not found in /etc/hosts. Adding $NEW_IP $HOSTNAME."
        sudo sh -c "echo '$NEW_IP $HOSTNAME' >> /etc/hosts"
    fi
}

### HARDWARE ###########################################################################################################

cputemp(){
    sudo powermetrics --samplers smc |grep -i "CPU die temperature"
}

### PROCESS MGMT #######################################################################################################

mykill(){
    # TODO: also consider fkill: https://github.com/sindresorhus/fkill-cli
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
    target="joris@m2.local:~/repos/dotfiles"
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
    rsync --copy-links --relative ~/./{.config/gh/config.yml,.config/ghostty/config,.ssh/assh.yml,.hammerspoon/cheatsheets.lua} $target
    # vscode
    rsync --copy-links --relative ~/Library/Application\ Support/Code\ -\ Insiders/User/{settings,keybindings}.json $target/vscode
}

### TERMINAL ###########################################################################################################

darkmode(){
    # Set black background, white text
    # echo -e "\033]Ph000000\033\\"
    # foreground color not working :(
    # echo -e "\033]PiFFFFFF\033\\"

    unset FZF_DEFAULT_OPTS
    git config --global delta.light false
}

lightmode(){
    # Set white background, black text
    # echo -e "\033]PhFFFFFF\033\\"
    # foreground color not working :(
    # echo -e "\033]Pi000000\033\\"

    export FZF_DEFAULT_OPTS='--color=light'
    git config --global delta.light true
}

### WORK MODES  ########################################################################################################

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

focus-outside(){
    set-etc-hosts httpproxy 192.168.8.1
    # Send all traffic for home network via GLINet router
    sudo route -n add 192.168.0.0/16 192.168.8.1
    lightmode
    echo "Terminal set to light mode"
}

focus-desk(){
    set-etc-hosts httpproxy 192.168.40.123
    sudo route -n delete 192.168.0.0/16 192.168.8.1
    darkmode
    echo "Terminal set to dark mode"
}

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
# alias dl="desk list" # conflicts with `alias dl='docker log'`
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
    # Find the first desk with matching name in the ~/.desk/ directory
    desk_path=$(find ~/.desk/ -name "$(desk_choose)*" -print -quit)
    code $desk_path
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

### Docker  ############################################################################################################

function alias-docker(){
    alias d='docker'
    alias di='docker inspect'
    alias dr='docker run'
    alias dl='docker logs'
    alias dk='docker kill'
    alias dp='docker container prune'
    alias dps='docker ps'
    alias dil='docker image list'
    alias dvl='docker volume list'
    alias dnl='docker network list'

    alias dc='docker-compose'
    alias | grep docker
}


### KUBERNETES  ########################################################################################################

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


### Tableau ############################################################################################################


tableau_get(){
    curl -s -H "X-Tableau-Auth: $TABLEAU_TOKEN" -H "Accept: application/json" "$TABLEAU_URL$@"
}

tableau_post(){
    curl -s -X POST -H "X-Tableau-Auth: $TABLEAU_TOKEN" -H "Accept: application/json" "$TABLEAU_URL$@"
}

tableau_site_get(){
    tableau_get "/sites/$TABLEAU_SITE_ID$@"
}

tableau_site_post(){
    tableau_post "/sites/$TABLEAU_SITE_ID$@"
}

tableau_signin(){
    PAYLOAD=$(cat <<EOF
        {
            "credentials": {
                "personalAccessTokenName": "$TABLEAU_PERSONAL_ACCESS_TOKEN_NAME",
                "personalAccessTokenSecret": "$TABLEAU_PERSONAL_ACCESS_TOKEN",
                "site": {
                    "contentUrl": "$TABLEAU_CONTENTURL"
                }
            }
        }
EOF
)

    export TABLEAU_TOKEN=$(curl -s -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d "$PAYLOAD" $TABLEAU_URL/auth/signin | jq -r ".credentials.token")
    cenv TABLEAU_TOKEN

    export TABLEAU_SITE_ID=$(tableau_get "/sites" | jq -r ".sites.site[] | select(.contentUrl == \"$TABLEAU_CONTENTURL\").id")
    cenv TABLEAU_SITE_ID
}
