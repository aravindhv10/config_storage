#!/bin/sh
if tmux has
then
    exec tmux attach
else
    exec tmux new -- /bin/bash
fi
exit '0'
