#!/bin/sh
# RES="$(fd -ts -g -d1 'Alacritty-wayland-*.sock' "/run/user/$(id -u)/" | wc -l)"
# fd -ts -F -d1 'Alacritty-wayland-' "/run/user/$(id -u)/"
if fd -ts -g -d1 'Alacritty-wayland-*.sock$' "/run/user/$(id -u)/" -q
then
    exec alacritty msg create-window ${@}
else
    exec alacritty ${@}
fi
exit '0'
