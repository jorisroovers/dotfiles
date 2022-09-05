
# dotfiles

My dotfiles

My .vimrc file needs clean up.

For my commandline prompt, I use https://ohmyposh.dev/

# Inspirational dotfile repos
- https://gitlab.com/EvanHahn/dotfiles
- https://github.com/holman/dotfiles
- https://github.com/mathiasbynens/dotfiles/

# Notes

When having issues with overwritin .ssh/assh.yml, it's probably because there's
still a linger assh session. Use `fuser .ssh/assh.yml` to find the process and
kill it.
