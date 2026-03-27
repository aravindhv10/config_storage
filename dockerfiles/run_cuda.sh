#!/bin/sh
cd "$('dirname' '--' "${0}")"

# IMAGE_NAME='6_pytorch'
IMAGE_NAME="$(basename -- "$(realpath -- .)")"
IMAGE_CMD='zsh'
PATH_DIR_SRC="$('realpath' '.')"
PATH_DIR_DST="/data/$('basename' -- "${PATH_DIR_SRC}")"

sudo -A docker run \
    '--tty' \
    '--interactive' \
    '--rm' \
    '--gpus' 'all,"capabilities=compute,utility,video"' \
    '--ipc' 'host' \
    '--ulimit' 'memlock=-1' \
    '--ulimit' 'stack=67108864' \
    '--shm-size' '107374182400' \
    '--mount' 'type=tmpfs,destination=/tmp,tmpfs-size=107374182400' \
    -v "${PATH_DIR_SRC}:${PATH_DIR_DST}" \
    -v "CACHE:/usr/local/cargo/registry" \
    -v "CACHE:/root/.cache" \
    "${IMAGE_NAME}" "${IMAGE_CMD}" \
;
