#!/bin/sh
C(){
    mkdir -pv -- "$('dirname' -- "${2}")"
    rm -vf -- "${2}"
    cp -vf -- "${1}" "${2}"
}

C './HOME,.wezterm.lua' "${HOME}/.wezterm.lua"

C './HOME,.config,foot,foot.ini' "${HOME}/.config/foot/foot.ini"

C './HOME,important_functions.sh' "${HOME}/important_functions.sh"

C './HOME,.bashrc' "${HOME}/.bashrc"

C './HOME,.config,fish,config.fish' "${HOME}/.config/fish/config.fish"

gcc -O2 -mtune=native -march=native ./SUDO_ASKPASS.c -o  "${HOME}/SUDO_ASKPASS"
