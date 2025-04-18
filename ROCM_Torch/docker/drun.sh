#!/bin/sh
sudo -A \
    docker run \
        -it \
        --network=host \
        --device=/dev/kfd \
        --device=/dev/dri \
        --group-add=video \
        --ipc=host \
        --cap-add=SYS_PTRACE \
        --security-opt seccomp=unconfined \
        "${@}" \
;
