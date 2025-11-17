#!/bin/sh
cd "$(dirname -- "${0}")"
ls /var/tmp/* -d | sed 's@^@("cp" "-vf" "./install.sh" "@g;s@$@");@g' | sh
