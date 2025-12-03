#!/bin/sh
# IMAGE_NAME='debtestrustzshhelix'
IMAGE_NAME='debtestrustzshhelixpytorch'

BUILD_CONTAINER () {
    cp '../../../shell_functions/important_functions.sh' ./
    CMD='sudo -A docker'
    which buildah && CMD='buildah'
    ${CMD} build -t "${IMAGE_NAME}" -f "./Dockerfile" .
}

RUN_CONTAINER () {
    CMD='sudo -A docker'
    which podman && CMD='podman'
    ${CMD} run -it --rm \
        -v "$(realpath .):/data" \
        "${IMAGE_NAME}" zsh ;
}
