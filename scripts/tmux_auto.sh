#!/bin/sh
tmux has && exec tmux attach
tmux new -- nu
exit '0'
