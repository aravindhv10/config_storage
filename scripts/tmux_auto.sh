#!/bin/sh
if tmux has
then
    exec tmux attach
else
    exec tmux
fi
exit '0'
