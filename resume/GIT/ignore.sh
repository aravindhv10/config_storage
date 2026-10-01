#!/bin/sh
cd "$('dirname' '--' "${0}")/.."

'cat' 'GIT/rm.txt' \
    | 'sed' 's@^@/@g' \
    > '.gitignore'


'cat' 'GIT/ignore.txt' \
    >> '.gitignore'

exit '0'
