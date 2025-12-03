#!/bin/sh
# IMAGE_NAME='debtestrustzshhelixpytorch'
IMAGE_NAME='debtestrustzshhelixpytorch2'

. '../../common_functions.sh'

RUN_CONTAINER () {
    CMD='sudo -A docker'
    which podman && CMD='podman'
    ${CMD} run -it --rm \
        -v "$(realpath .):/data" \
        "${IMAGE_NAME}" zsh ;
}
