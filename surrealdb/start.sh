#!/bin/sh
cd "$('dirname' -- "${0}")"

. './env.sh'

podman run \
    '-it' '--rm' \
    '--name' "${NAME_GUEST}" \
    '--network' 'app_net' \
    '-p' "${PORT_HOST}:${PORT_GUEST}" \
    '-v' "${VOLUME}:/data" \
    '-e' 'RUST_LOG=info' \
    "${NAME_IMAGE}" 'start' \
        '--username' "${USER}" \
        '--password' "${PASSWORD_GUEST}" \
        '--bind' "0.0.0.0:${PORT_GUEST}" \
        '--allow-all' \
        'surrealkv:///data'

exit '0'
