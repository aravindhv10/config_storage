#!/bin/sh
eval -- "$(starship init bash --print-full-init)"

. "${HOME}/important_functions.sh"

alias ls=lsd
alias top='btm -b --process_command'
alias cat=bat
