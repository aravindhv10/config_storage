#!/bin/sh
RES="$(fd 'Alacritty-wayland' "/run/user/$(id -u)/" | wc -l)"
if test "${RES}" -gt 0
then
    exec alacritty msg create-window ${@}
else
    exec alacritty ${@}
fi
exit '0'
