#!/bin/sh
IMAGE_NAME='mainbase'

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
        "${IMAGE_NAME}" bash \
    ;
}
