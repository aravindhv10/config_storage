#!/bin/sh
cd "$('dirname' -- "${0}")/.."
'git' 'commit' '-m' "$('cat' 'GIT/message.txt')"
'git' 'status'
"${HOME}/SSH/K/P/setup.sh"
'git' 'push'
exit '0'
