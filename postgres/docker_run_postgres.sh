#!/bin/sh
cd "$(dirname -- "${0}")"
. './env.sh'


'docker' 'run' \
    '-it' '--rm' \
    '--name' "${NAME_GUEST}" \
    '-e' "POSTGRES_PASSWORD=${PASSWORD_GUEST}" \
    '-v' 'postgres_data:/var/lib/postgresql' \
    '-p' "${PORT_HOST}:${PORT_GUEST}" \
    '-d' "${IMAGE_NAME}" \
;

exit '0'
