#!/bin/sh
mkdir -pv -- "${HOME}/.config/"

mkdir -pv -- "${HOME}/.config/fish"
cp -vf -- './HOME,.config,fish,config.fish' "${HOME}/.config/fish/config.fish"

gcc -O2 -mtune=native -march=native ./SUDO_ASKPASS.c -o  "${HOME}/SUDO_ASKPASS"
