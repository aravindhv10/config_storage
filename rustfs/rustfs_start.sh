#!/bin/sh
NAME_IMAGE='docker.io/rustfs/rustfs:latest-glibc'
VOLUME_RUSTFS='/home/root/rust_fs'
NAME_GUEST='rustfs_container'

podman run \
    '-it' '--rm' \
    '--name' "${NAME_GUEST}" \
    '--network' 'app_net' \
    '-p' '8100:8100' \
    '-v' "${VOLUME_RUSTFS}:/data" \
    '-e' 'RUST_LOG=info' \
    "${NAME_IMAGE}" \
    '--address' '0.0.0.0:8100' \
    '--access-key' 'cloudphysician' \
    '--secret-key' '7*Bellary' \
    '/data'

exit '0'
