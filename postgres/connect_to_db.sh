#!/bin/sh
cd "$('dirname' -- "${0}")"

. './env.sh'

echo "${PASSWORD_GUEST}"

psql \
    -h "${HOST}" \
    -p "${PORT_HOST}" \
    -U "${USER}" \
    -d "${DBNAME}" \
;
