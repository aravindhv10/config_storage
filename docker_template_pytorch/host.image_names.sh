#!/bin/sh
export IMAGE_NAME='debian-cuda'
export CONTAINER_NAME="${IMAGE_NAME}_1"

docker_build(){
    sudo docker image build \
        -t "${IMAGE_NAME}"  \
        .                   \
    ;
}
