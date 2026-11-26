#!/bin/sh
cd "$('dirname' '--' "${0}")/.."
'grep' '-v' '^ *$' 'GIT/add.txt' > 'GIT/tmpadd.txt'
'git' 'add' '--pathspec-from-file=GIT/tmpadd.txt'
'rm' '-vf' '--' 'GIT/tmpadd.txt'
exit '0'
