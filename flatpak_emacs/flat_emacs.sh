#!/bin/sh
echo 'export PATH="${HOME}/bin:${PATH}"; source /usr/lib/sdk/llvm19/enable.sh; source /usr/lib/sdk/rust-stable/enable.sh; /app/bin/emacs-wrapper' | flatpak run '-talk-name=org.freedesktop.Flatpak' '--command=sh' org.gnu.emacs
exit '0'
