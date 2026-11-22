#!/bin/sh
NAME_IMAGE='docker.io/rustfs/rustfs:latest-glibc'
VOLUME_RUSTFS='/home/root/rust_fs'

podman run \
  '-it' '--rm' \
  '-p' '8100:8100' \
  '-v' "${VOLUME_RUSTFS}:/data" \
  '-e' 'RUST_LOG=info' \
  "${NAME_IMAGE}" \
  '--address' '0.0.0.0:8100' \
  '--access-key' 'cloudphysician' \
  '--secret-key' '7*Bellary' \
  '/data'
