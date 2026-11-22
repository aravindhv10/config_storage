#!/bin/sh
cd "$(dirname -- "${0}")"
. './env.sh'

'podman' 'run' \
    '-it' '--rm' \
    '--name' "${NAME_GUEST}" \
    '--network' 'app_net' \
    '-e' "POSTGRES_PASSWORD=${PASSWORD_GUEST}" \
    '-e' "POSTGRES_USER=${USER}" \
    '-v' "${VOLUME_POSTGRES}:/var/lib/postgresql" \
    '-p' "${PORT_HOST}:${PORT_GUEST}" \
    "${IMAGE_NAME}"

exit '0'
