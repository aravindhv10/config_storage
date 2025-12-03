#!/bin/sh
BUILD_CONTAINER () {
    cp '../../../shell_functions/important_functions.sh' ./
    CMD='sudo -A docker'
    which buildah && CMD='buildah'
    ${CMD} build -t "${IMAGE_NAME}" -f "./Dockerfile" .
}
