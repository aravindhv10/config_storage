#!/bin/sh
export PATH="/usr/lib/sdk/texlive/bin/x86_64-linux:/usr/lib/sdk/texlive/bin:/usr/lib/sdk/rust-stable/bin:/usr/lib/sdk/llvm19/bin:/var/tmp/all/bin:${HOME}/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/app/bin"
export SHELL='nu'
exec 'zellij' 'attach' '--create'
