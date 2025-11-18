#!/bin/sh
IMAGE_NAME='debtestrustbuild'

BUILD_CONTAINER () {
    CMD='sudo -A docker'
    which buildah && CMD='buildah'
    cp '../../../shell_functions/important_functions.sh' ./
    ${CMD} build -t "${IMAGE_NAME}" -f "./Dockerfile"
}

RUN_CONTAINER () {
    CMD='sudo -A docker'
    which podman && CMD='podman'
    mkdir -pv -- in out

    ${CMD} run -it --rm \
        -v "$(realpath .):/data" \
        -v "$(realpath .)/in:/root/GITHUB" \
        -v "$(realpath .)/in:/root/GITLAB" \
        -v "$(realpath .)/out:/var/tmp/" \
        "${IMAGE_NAME}" bash ;
}

IMAGE_CMD='bash'
