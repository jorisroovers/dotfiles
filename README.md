
# dotfiles

My dotfiles

My .vimrc file needs clean up.

For my commandline prompt, I use https://ohmyposh.dev/

# Inspirational dotfile repos
- https://gitlab.com/EvanHahn/dotfiles
- https://github.com/holman/dotfiles
- https://github.com/mathiasbynens/dotfiles/
- https://github.com/driesvints/dotfiles

# Notes

When having issues with overwriting .ssh/assh.yml, it's probably because there's
still a linger assh session. Use `lsof | grep assh.yml` to find the process and
kill it (`fuser .ssh/assh.yml` doesn't always work).
`ps -ef | grep assh` can also be used to identify this process.
