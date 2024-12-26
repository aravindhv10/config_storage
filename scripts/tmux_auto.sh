#!/bin/sh
if tmux has
then
    exec tmux attach -- /bin/bash
else
    exec tmux -- /bin/bash
fi
exit '0'
