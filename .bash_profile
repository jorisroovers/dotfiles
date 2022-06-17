# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
    fi
fi

[ -f ~/.env.sh ] && source ~/.env.sh
[ -f ~/.aliases_functions.sh ] && source ~/.aliases_functions.sh

eval "$(oh-my-posh init bash --config ~/.joris.omp.json)"

source /usr/share/doc/fzf/examples/key-bindings.bash
source /usr/share/doc/fzf/examples/completion.bash
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
