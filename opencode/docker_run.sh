#!/bin/sh
cd "$('dirname' '--' "${0}")"

# IMAGE_NAME='6_pytorch'
IMAGE_NAME='ghcr.io/anomalyco/opencode'
IMAGE_CMD='zsh'

PATH_DIR_SRC="$('realpath' '.')"
PATH_DIR_DST="/data/$('basename' -- "${PATH_DIR_SRC}")"

sudo -A docker run \
    '--tty' \
    '--interactive' \
    '--rm' \
    '--net' 'host' \
    '--ipc' 'host' \
    '--tmpfs' '/tmp:size=107374182400,exec' \
    '--ulimit' 'memlock=-1' \
    '--ulimit' 'stack=67108864' \
    '--gpus' 'all,"capabilities=compute,utility,video"' \
    -v "${PATH_DIR_SRC}:${PATH_DIR_DST}" \
    -v "CACHE:/usr/local/cargo/registry" \
    -v "CACHE:/root/.cache" \
    "${IMAGE_NAME}" \
;
