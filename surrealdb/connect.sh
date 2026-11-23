#!/bin/sh
cd "$('dirname' -- "${0}")"

NAME_IMAGE='docker.io/surrealdb/surrealdb:latest'
VOLUME="$('realpath' './data')"
NAME_GUEST='surrealdb_container'

podman exec \
    '-it' "${NAME_GUEST}" \
    'surreal' \
    '--help'

exit '0'
