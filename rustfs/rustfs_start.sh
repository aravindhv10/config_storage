#!/bin/sh
. './env.sh'

podman run \
    '-it' '--rm' \
    '--name' "${NAME_GUEST}" \
    '--network' 'app_net' \
    '-p' "${PORT_HOST}:${PORT_GUEST}" \
    '-v' "${VOLUME}:/data" \
    '-e' 'RUST_LOG=info' \
    '-e' 'RUSTFS_NOTIFY_ENABLE=true' \
    '-e' 'RUSTFS_NOTIFY_WEBHOOK_ENABLE_PRIMARY=on' \
    '-e' 'RUSTFS_NOTIFY_WEBHOOK_ENDPOINT_PRIMARY=http://surrealdb_container:8101/api/main/main/rustfs/events' \
    '-e' 'RUSTFS_NOTIFY_WEBHOOK_QUEUE_DIR_PRIMARY=/data/.notify-webhook' \
    '-e' 'RUSTFS_OUTBOUND_ALLOW_ORIGINS=http://surrealdb_container:8101' \
    "${NAME_IMAGE}" \
        '--address' "0.0.0.0:${PORT_GUEST}" \
        '--access-key' "${USER}" \
        '--secret-key' "${PASSWORD_GUEST}" \
        '/data'

exit '0'
