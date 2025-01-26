#!/bin/sh
export PATH="/var/tmp/all/bin:${HOME}/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
if fd -ts -g -d1 'Alacritty-wayland-*.sock$' "/run/user/$(id -u)/" -q
then
    exec alacritty msg create-window -e tmux_auto.sh
else
    exec alacritty -e tmux_auto.sh
fi
exit '0'
