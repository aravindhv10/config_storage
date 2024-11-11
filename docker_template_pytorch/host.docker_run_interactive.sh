#!/bin/sh
mkdir -pv -- "${2}"

export INPUT="$(realpath -- "${1}")"
export OUTPUT="$(realpath -- "${2}")"

cd "$('dirname' '--' "${0}")"

. './host.image_names.sh'

sudo docker run                                                          \
    --tty                                                                \
    --interactive                                                        \
    --rm                                                                 \
    --gpus all                                                           \
    --ipc host                                                           \
    --ulimit memlock=-1                                                  \
    --ulimit stack=67108864                                              \
    --mount 'type=tmpfs,destination=/data/TMPFS,tmpfs-size=137438953472' \
    -p '0.0.0.0:8888:8888/tcp'                                           \
    -v "CACHE:/root/.cache"                                              \
    -v "${INPUT}:/data/input"                                            \
    -v "${OUTPUT}:/data/output"                                          \
    "${IMAGE_NAME}"                                                      \
    '/bin/bash'                                                          \
;
