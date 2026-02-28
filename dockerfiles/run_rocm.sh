#!/bin/sh
cd "$('dirname' '--' "${0}")"

# IMAGE_NAME="6_pytorch"
IMAGE_NAME="$(basename -- "$(realpath -- .)")"

IMAGE_CMD='zsh'

PATH_DIR_SRC="$('realpath' '.')"
PATH_DIR_DST="/data/$('basename' -- "${PATH_DIR_SRC}")"

podman run \
    -it --rm \
    '--device' '/dev/kfd' \
    '--device' '/dev/dri' \
    '--net' 'host' \
    '--security-opt' 'seccomp=unconfined' \
    --mount 'type=tmpfs,destination=/data/TMPFS,tmpfs-size=137438953472' \
    -v "$(realpath .):/data/source" \
    -v "${HOME}/BUILD:/data/build" \
    # -v "${PATH_DIR_SRC}:${PATH_DIR_DST}" \
    -v "CACHE:/usr/local/cargo/registry" \
    -v "CACHE:/root/.cache" \
    "${IMAGE_NAME}" "${IMAGE_CMD}" \
;
