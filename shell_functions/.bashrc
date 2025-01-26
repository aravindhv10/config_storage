#!/bin/sh
export ATH="/var/tmp/all/bin:${HOME}/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
# export LD_LIBRARY_PATH="/var/tmp/RUST/lib64:/var/tmp/squashfs/lib64"

eval -- "$(starship init bash --print-full-init)"

. "${HOME}/important_functions.sh"

alias ls=lsd
alias top=htop
alias cat=bat
