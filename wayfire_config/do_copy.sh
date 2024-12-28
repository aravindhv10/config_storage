#!/bin/sh
cd "$('dirname' '--' "${0}")"
mkdir -pv -- "${HOME}/.config/waybar/"
cp './wayfire.ini' "${HOME}/.config/wayfire.ini"
cp './config.jsonc' "${HOME}/.config/waybar/config.jsonc"
exit '0'
