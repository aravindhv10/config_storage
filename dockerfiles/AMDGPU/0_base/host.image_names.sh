#!/bin/sh
IMAGE_NAME='mainbase'

BUILD_CONTAINER () {
    CMD='sudo -A docker'
    which buildah && CMD='buildah'
    ${CMD} build -t "${IMAGE_NAME}" -f "./Dockerfile" .
}

RUN_CONTAINER () {
    CMD='sudo -A docker'
    which podman && CMD='podman'
    ${CMD} run \
        -it --rm \
        '--device' '/dev/kfd' \
        '--device' '/dev/dri' \
        '--security-opt' 'seccomp=unconfined' \
        -v "$(realpath .):/data" \
        "${IMAGE_NAME}" bash \
    l
}
