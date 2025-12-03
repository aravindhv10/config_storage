#!/bin/sh
# IMAGE_NAME='debtestrustzshhelix'
IMAGE_NAME='debtestrustzshhelixpy'

. '../../common_functions.sh'

RUN_CONTAINER () {
    CMD='sudo -A docker'
    which podman && CMD='podman'
    ${CMD} run \
        -it --rm \
        '--device' '/dev/kfd' \
        '--device' '/dev/dri' \
        '--security-opt' 'seccomp=unconfined' \
        -v "$(realpath .):/data" \
        "${IMAGE_NAME}" zsh \
    ;
}
