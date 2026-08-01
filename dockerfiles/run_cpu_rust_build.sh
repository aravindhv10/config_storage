#!/bin/sh
cd "$('dirname' '--' "${0}")"

IMAGE_NAME='2_install_rust'
# IMAGE_NAME="$(basename -- "$(realpath -- .)")"
IMAGE_CMD='bash'
PATH_DIR_SRC="$('realpath' '.')"
PATH_DIR_DST="/data/$('basename' -- "${PATH_DIR_SRC}")"

podman run \
    '--cap-add=IPC_LOCK' \
    '--ulimit' 'memlock=-1:-1' \
    '--tty' \
    '--interactive' \
    '--rm' \
    '--net' 'host' \
    '--ipc' 'host' \
    '--tmpfs' '/tmp:size=107374182400,exec' \
    '--ulimit' 'memlock=-1' \
    '--ulimit' 'stack=67108864' \
    '--device' '/dev/dri' \
    '--security-opt' 'seccomp=unconfined' \
    -v "${PATH_DIR_SRC}:${PATH_DIR_DST}" \
    -v "CACHE:/root/cargo/registry" \
    -v "CACHE:/root/.cache" \
    -v "${HOME}/GITHUB:/root/GITHUB" \
    "${IMAGE_NAME}" "${IMAGE_CMD}" \
;
