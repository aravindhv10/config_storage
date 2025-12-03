#!/bin/sh
# IMAGE_NAME='debtestrustzsh'
IMAGE_NAME='debtestrustzshhelix'

. '../../common_functions.sh'

RUN_CONTAINER () {
    CMD='sudo -A docker'
    which podman && CMD='podman'
    ${CMD} run -it --rm -v "$(realpath .):/data" "${IMAGE_NAME}" zsh
}
