export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

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

alias hass="ssh joris@192.168.1.121"
alias cec="export CEC_USERNAME=jroovers; read -s -p 'CEC PASSWORD: ' CEC_PASSWORD; export CEC_PASSWORD=\$CEC_PASSWORD; echo -e '\nEnvironment variables CEC_USERNAME and CEC_PASSWORD set.'"

# Adds colors to grep on mac
# http://superuser.com/questions/416835/how-can-i-grep-with-color-in-mac-os-xs-terminal
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;35;40'

# added by Anaconda2 4.3.1 installer
export PATH="/anaconda/bin:$PATH"

# added etcher-cli to PATH: https://etcher.io/cli/
export PATH="$PATH:/opt/etcher-cli"

alias cat='ccat'
