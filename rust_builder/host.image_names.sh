#!/bin/sh
IMAGE_NAME='rust_builder'
CONTAINER_NAME="${IMAGE_NAME}_1"

BUILDAH(){
    buildah "$@"
}

DOCKER_BUILD(){
    sudo -A docker image "$@"
}

IMAGE_BUILDER(){
    BUILDAH "$@"
}

docker_build(){
    cp '../shell_functions/important_functions.sh' ./

    IMAGE_BUILDER build \
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

START_IMAGE(){
    PODMAN "$@"
}

docker_run () {
    mkdir -pv -- "${1}" "${2}"
    INPUT="$(realpath ${1})"
    OUTPUT="$(realpath ${2})"
    START_IMAGE run \
        --tty \
        --interactive \
        --rm \
        --mount 'type=tmpfs,destination=/data/TMPFS,tmpfs-size=137438953472' \
        -v "${INPUT}:/data/input" \
        -v "${INPUT}:/root/GITHUB" \
        -v "${OUTPUT}:/data/output" \
        -v "${OUTPUT}:/var/tmp" \
        -v "CACHE:/root/.cache" \
        "${IMAGE_NAME}" "${IMAGE_CMD}" \
    ;
}

IMAGE_CMD='zsh'
