#!/bin/sh
export PATH="/usr/lib/sdk/texlive/bin/x86_64-linux:/usr/lib/sdk/texlive/bin:/usr/lib/sdk/rust-stable/bin:/usr/lib/sdk/llvm19/bin:/var/tmp/all/bin:${HOME}/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/app/bin"
export SHELL='bash'
exec flatpak run '--talk-name=org.freedesktop.Flatpak' '--command=/var/tmp/all/bin/fish' 'org.gnu.emacs' '-c' 'set PATH /usr/lib/sdk/texlive/bin/x86_64-linux /usr/lib/sdk/texlive/bin /usr/lib/sdk/rust-stable/bin /usr/lib/sdk/llvm19/bin /var/tmp/all/bin {$HOME}/bin /usr/local/bin /usr/bin /bin /usr/local/sbin /usr/sbin /sbin /app/bin ; exec /app/bin/emacsclient -c'
