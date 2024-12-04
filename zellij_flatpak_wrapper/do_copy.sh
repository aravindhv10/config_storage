#!/bin/sh
mkdir -pv -- "${HOME}/bin" "${HOME}/exe"

rm -vf -- "${HOME}/bin/zellij"
cp -vf -- './zellij' "${HOME}/bin/"

cp -vf -- './enter_emacs_flatpak' "${HOME}/bin/"

cp -vf -- './tmux_auto' "${HOME}/bin/"

cp -vf -- './emd' "${HOME}/bin/"

cp -vf -- './emc' "${HOME}/bin/"
