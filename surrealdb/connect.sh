#!/bin/sh
cd "$('dirname' -- "${0}")"

. './env.sh'

podman exec \
    '-it' "${NAME_GUEST}" \
    '/surreal' 'sql' \
        '--endpoint' 'ws://localhost:8102' \
        '--username' 'cloudphysician' \
        '--password' '7*Bellary' \
        '--namespace' 'main' \
        '--database' 'main' \
        '--pretty'

exit '0'
