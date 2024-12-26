#!/bin/sh
RES="$(fd 'Alacritty-wayland' "/run/user/$(id -u)/" | wc -l)"
if test "${RES}" -gt 0
then
    alacritty msg create-window -e tmux_auto
else
    alacritty -e tmux_auto
fi
exit '0'
