#!/bin/sh
export PATH="/usr/lib/sdk/texlive/bin/x86_64-linux:/usr/lib/sdk/texlive/bin:/usr/lib/sdk/rust-stable/bin:/usr/lib/sdk/llvm19/bin:/var/tmp/all/bin:${HOME}/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/app/bin"

# export LD_LIBRARY_PATH="/var/tmp/RUST/lib64:/var/tmp/squashfs/lib64"

eval -- "$(starship init bash --print-full-init)"

. "${HOME}/important_functions.sh"

alias ls=lsd
alias top=htop
alias cat=bat
