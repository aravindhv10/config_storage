#!/bin/sh
IMAGE_NAME='debtestrustbuild'
IMAGE_CMD='bash'

BUILD_CONTAINER () {
    cp '../../../shell_functions/important_functions.sh' ./
    CMD='sudo -A docker'
    which buildah && CMD='buildah'
    ${CMD} build -t "${IMAGE_NAME}" -f "./Dockerfile" .
}

RUN_CONTAINER () {
    CMD='sudo -A docker'
    which podman && CMD='podman'
    mkdir -pv -- in out cache

    ${CMD} run -it --rm \
        -v "$(realpath .):/data" \
        -v "$(realpath .)/in:/root/GITHUB" \
        -v "$(realpath .)/in:/root/GITLAB" \
        -v "$(realpath .)/out:/var/tmp/" \
        -v "$(realpath .)/cache:/usr/local/cargo/registry" \
        "${IMAGE_NAME}" bash ;
}
