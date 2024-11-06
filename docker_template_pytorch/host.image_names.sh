#!/bin/sh
IMAGE_NAME='flux_diffusers'
CONTAINER_NAME="${IMAGE_NAME}_1"

docker_build(){
    sudo docker image build \
        -t "${IMAGE_NAME}"  \
        .                   \
    ;
}
