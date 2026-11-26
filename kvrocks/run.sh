#!/bin/sh
cd "$(dirname -- "${0}")"

. './env.sh'

'podman' 'run' \
    '-it' '--rm' \
    '--name' "${NAME_GUEST}" \
    '--network' 'app_net' \
    '-p' "${PORT_HOST}:${PORT_GUEST}" \
    '-v' "${VOLUME_HOST}:${VOLUME_GUEST}" \
    "${NAME_IMAGE}" \
        '--bind' '0.0.0.0' \
        '--dir' '/var/lib/kvrocks'

exit '0'
