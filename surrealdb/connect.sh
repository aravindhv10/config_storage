#!/bin/sh
cd "$('dirname' -- "${0}")"

NAME_IMAGE='docker.io/surrealdb/surrealdb:latest'
VOLUME="$('realpath' './data')"
NAME_GUEST='surrealdb_container'

podman exec \
    '-it' "${NAME_GUEST}" \
    '--help'

exit '0'
