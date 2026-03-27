#!/bin/sh
cd "$(dirname -- "${0}")"

PORT_HOST='12345'
PORT_GUEST='5432'
PASSWORD_GUEST='asd123'
NAME_GUEST='inferencecoordinator'
IMAGE_NAME='postgres:18.3-trixie'

'docker' 'run' \
    '-it' '--rm' \
    '--name' "${NAME_GUEST}" \
    '-e' "POSTGRES_PASSWORD=${PASSWORD_GUEST}" \
    '-v' 'postgres_data:/var/lib/postgresql' \
    '-p' "${PORT_HOST}:${PORT_GUEST}" \
    '-d' "${IMAGE_NAME}" \
;

exit '0'
