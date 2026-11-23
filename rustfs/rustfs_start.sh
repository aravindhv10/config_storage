#!/bin/sh
. './env.sh'

podman run \
    '-it' '--rm' \
    '--name' "${NAME_GUEST}" \
    '--network' 'app_net' \
    '-p' "${PORT_HOST}:${PORT_GUEST}" \
    '-v' "${VOLUME}:/data" \
    '-e' 'RUSTFS_NOTIFY_ENABLE=true' \
    '-e' 'RUSTFS_NOTIFY_POSTGRES_CONNECTION_STRING_PRIMARY=postgres://cloudphysician:7*Bellary@postgres_container:5432/postgres?sslmode=disable' \
    '-e' 'RUSTFS_NOTIFY_POSTGRES_ENABLE_PRIMARY=on' \
    '-e' 'RUSTFS_NOTIFY_POSTGRES_QUEUE_DIR_PRIMARY=/data/.notify-postgres' \
    '-e' 'RUSTFS_NOTIFY_POSTGRES_TABLE_PRIMARY=s3_object_notifications' \
    '-e' 'RUST_LOG=info' \
    "${NAME_IMAGE}" \
        '--address' "0.0.0.0:${PORT_GUEST}" \
        '--access-key' "${USER}" \
        '--secret-key' "${PASSWORD_GUEST}" \
        '/data'

exit '0'
