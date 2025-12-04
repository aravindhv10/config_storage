#!/bin/sh
# IMAGE_NAME='debtestrustzshhelix'
IMAGE_NAME='debtestrustzshhelixpytorch'

. '../../common_functions.sh'

RUN_CONTAINER () {
    CMD='sudo -A docker'
    which podman && CMD='podman'
    ${CMD} run -it --rm \
        --gpus 'all,"capabilities=compute,utility,video"' \
        --ipc host \
        --ulimit memlock=-1 \
        --ulimit stack=67108864 \
        --shm-size 107374182400 \
        --mount 'type=tmpfs,destination=/data/TMPFS,tmpfs-size=137438953472' \
        -v "CACHE:/root/.cache" \
        -v "CACHE:/root/.triton" \
        -p "0.0.0.0:${LISTEN_PORT}:${LISTEN_PORT}/tcp" \
        -v "$(realpath .):/data" \
        "${IMAGE_NAME}" zsh ;
}
