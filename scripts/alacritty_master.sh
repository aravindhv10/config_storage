#!/bin/sh
# RES="$(fd -ts -g -d1 'Alacritty-wayland-*.sock' "/run/user/$(id -u)/" | wc -l)"
# fd -ts -F -d1 'Alacritty-wayland-' "/run/user/$(id -u)/"
if fd -ts -g -d1 'Alacritty-wayland-*.sock$' "/run/user/$(id -u)/" -q
then
    if tmux has
    then
        exec alacritty msg create-window -e tmux attach
    else
        exec alacritty msg create-window -e tmux new -- /bin/bash
    fi
else
    if tmux has
    then
        exec alacritty -e tmux attach
    else
        exec alacritty -e tmux new -- /bin/bash
    fi
fi
exit '0'
