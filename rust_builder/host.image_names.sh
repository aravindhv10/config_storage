#!/bin/sh
IMAGE_NAME='rust_builder'
CONTAINER_NAME="${IMAGE_NAME}_1"

BUILDAH(){
    buildah "$@"
}

DOCKER_BUILD(){
    sudo -A docker image "$@"
}

docker_build(){
    cp '../shell_functions/important_functions.sh' ./

    BUILDAH build \
        -t "${IMAGE_NAME}" \
        . \
    ;
}

DOCKER(){
    sudo -A docker "$@"
}

PODMAN(){
    podman "$@"
}

docker_run () {
    mkdir -pv -- "${1}" "${2}"
    INPUT="$(realpath ${1})"
    OUTPUT="$(realpath ${2})"
    PODMAN run \
        --tty \
        --interactive \
        --rm \
        --mount 'type=tmpfs,destination=/data/TMPFS,tmpfs-size=137438953472' \
        -v "${INPUT}:/data/input" \
        -v "${OUTPUT}:/data/output" \
        -v "CACHE:/root/.cache" \
        "${IMAGE_NAME}" "${IMAGE_CMD}" \
    ;
}

IMAGE_CMD='zsh'
