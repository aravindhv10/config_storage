#!/bin/sh
cd "$('dirname' -- "${0}")"

. './env.sh'

podman run \
    '-it' '--rm' \
    '--name' "${NAME_GUEST}" \
    '--network' 'app_net' \
    '-p' '8101:8101' \
    '-v' "${VOLUME}:/data" \
    '-e' 'RUST_LOG=info' \
    "${NAME_IMAGE}" 'start' \
        '--username' 'cloudphysician' \
        '--password' '7*Bellary' \
        '--bind' '0.0.0.0:8101' \
        '--allow-all' \
        'surrealkv:///data'

exit '0'
