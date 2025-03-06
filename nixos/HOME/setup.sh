#!/bin/sh
mkdir -pv -- "${HOME}/.config/"

cp -vf -- './HOME,important_functions.sh' "${HOME}/important_functions.sh"

cp -vf -- './HOME,.bashrc' "${HOME}/.bashrc"

mkdir -pv -- "${HOME}/.config/fish"
cp -vf -- './HOME,.config,fish,config.fish' "${HOME}/.config/fish/config.fish"

gcc -O2 -mtune=native -march=native ./SUDO_ASKPASS.c -o  "${HOME}/SUDO_ASKPASS"
