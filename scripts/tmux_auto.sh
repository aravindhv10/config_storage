#!/bin/sh
export PATH="/var/tmp/all/bin:${HOME}/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
export SHELL='/var/tmp/all/bin/fish'
export TERM='xterm-256color'
exec byobu-tmux
if tmux has
then
    exec tmux attach
else
    exec tmux new -- /bin/bash
fi
exit '0'
