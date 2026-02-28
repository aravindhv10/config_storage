#!/bin/sh
cd "$('dirname' -- "${0}")"

C(){
    mkdir -pv -- "$('dirname' -- "${2}")"
    rm -vf -- "${2}"
    cp -vf -- "${1}" "${2}"
}

C 'HOME,.config,wayfire.ini' "${HOME}/.config/wayfire.ini"

C 'HOME/.config/waybar/config.jsonc' "${HOME}/.config/waybar/config.jsonc"
