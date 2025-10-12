#!/bin/sh
IMAGE_NAME='pytorch_big'
CONTAINER_NAME="${IMAGE_NAME}_1"

docker_build(){
    sudo -A docker image build \
        -t "${IMAGE_NAME}"  \
        .                   \
    ;
}

docker_run () {
    mkdir -pv -- './input' './output'
    INPUT="$(realpath ./input)"
    OUTPUT="$(realpath ./output)"
    sudo -A docker run \
        --tty \
        --interactive \
        --rm \
        --gpus 'all,"capabilities=compute,utility,video"' \
        --ipc host \
        --ulimit memlock=-1 \
        --ulimit stack=67108864 \
        --shm-size 107374182400 \
        --mount 'type=tmpfs,destination=/data/TMPFS,tmpfs-size=137438953472' \
        -v "${INPUT}:/data/input" \
        -v "${OUTPUT}:/data/output" \
        -v "CACHE:/root/.cache" \
        -p "0.0.0.0:${LISTEN_PORT}:${LISTEN_PORT}/tcp" \
        "${IMAGE_NAME}" "${IMAGE_CMD}" \
    ;
}

IMAGE_CMD='zsh'

LISTEN_PORT='8888'
