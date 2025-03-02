#!/bin/sh
cd "$('dirname' '--' "${0}")"
echo 'START COPYING' \
    && find './' '-type' 'f' \
        | grep '^\./M_.*$' \
        | sed 's@^@("cp" "-vf" "--" "@g ; s@$@" "/usr/local/bin/");@g' \
        | sh \
&& echo 'DONE COPYING' ;
