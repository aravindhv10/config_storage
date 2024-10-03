#!/bin/sh
echo 'export PATH="${HOME}/bin:${PATH}"; source /usr/lib/sdk/llvm18/enable.sh; source /usr/lib/sdk/rust-stable/enable.sh; /app/bin/emacs-wrapper' | flatpak run '--command=sh' org.gnu.emacs
exit '0'
