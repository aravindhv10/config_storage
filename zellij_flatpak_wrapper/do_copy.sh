#!/bin/sh
mkdir -pv -- "${HOME}/bin" "${HOME}/exe"

cp -vf -- './zellij.sh' "${HOME}/bin/"

cp -vf -- './enter_emacs_flatpak.sh' "${HOME}/bin/"

cp -vf -- './emd.sh' "${HOME}/bin/"

cp -vf -- './emc.sh' "${HOME}/bin/"
