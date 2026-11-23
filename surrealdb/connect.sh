#!/bin/sh
cd "$('dirname' -- "${0}")"

NAME_IMAGE='docker.io/surrealdb/surrealdb:latest'
VOLUME="$('realpath' './data')"
NAME_GUEST='surrealdb_container'

podman run \
    '-it' '--rm' \
    '--name' "${NAME_GUEST}" \
    '--network' 'app_net' \
    '-p' '8101:8101' \
    '-v' "${VOLUME}:/data" \
    '-e' 'RUST_LOG=info' \
    "${NAME_IMAGE}" '--help'

exit '0'
