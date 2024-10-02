#!/bin/sh
# echo 'export PATH="${HOME}/bin:${PATH}"; /app/bin/emacs-wrapper' | flatpak run --command=sh org.gnu.emacs
echo 'export PATH="${HOME}/bin:${PATH}"; source /usr/lib/sdk/llvm18/enable.sh; /app/bin/emacs-wrapper' | flatpak run --command=sh org.gnu.emacs
exit '0'
