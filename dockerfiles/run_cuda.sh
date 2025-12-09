#!/bin/sh
cd "$('dirname' '--' "${0}")"
. "${HOME}/important_functions.sh"
IMAGE_NAME="$(basename -- "$(realpath -- .)")"
mkdir -pv -- './input' './output' './model'
INPUT="$(realpath ./input)"
OUTPUT="$(realpath ./output)"
MODEL="$(realpath ./model)"
sudo -A docker run \
    --tty \
    --interactive \
    --rm \
    --gpus 'all,"capabilities=compute,utility,video"' \
    --ipc host \
    --ulimit memlock=-1 \
    --ulimit stack=67108864 \
    --shm-size 107374182400 \
    --mount 'type=tmpfs,destination=/data/TMPFS,tmpfs-size=137438953472' \
    -v "${INPUT}:/data/input" \
    -v "${OUTPUT}:/data/output" \
    -v "${MODEL}:/data/model" \
    -v "CACHE:/root/.cache" \
    -v "CACHE:/root/.triton" \
    "${IMAGE_NAME}" "${IMAGE_CMD}" \
;

    # -p "0.0.0.0:${LISTEN_PORT}:${LISTEN_PORT}/tcp" \
