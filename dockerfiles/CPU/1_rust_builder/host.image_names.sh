#!/bin/sh
IMAGE_NAME='debtestrustbuild'
IMAGE_CMD='bash'

. '../../common_functions.sh'

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
