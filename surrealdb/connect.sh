#!/bin/sh
cd "$('dirname' -- "${0}")"

. './env.sh'

podman exec \
    '-it' "${NAME_GUEST}" \
    '/surreal' 'sql' \
        '--endpoint' "ws://127.0.0.1:${PORT_HOST}" \
        '--username' "${USER}" \
        '--password' "${PASSWORD_GUEST}" \
        '--namespace' 'main' \
        '--database' 'main' \
        '--pretty'

exit '0'
