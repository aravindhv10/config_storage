#!/bin/sh
cd "$(dirname -- "${0}")"

sudo -A \
    docker build \
        -f ./Dockerfile \
        -t myrocm \
;
