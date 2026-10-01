#!/bin/sh
cd "$('dirname' '--' "${0}")/.."

'sed' 's@^@("rm" "-vf" "--" "@g ; s@$@");@g' 'GIT/rm.txt' \
    | 'sh'

exit '0'
