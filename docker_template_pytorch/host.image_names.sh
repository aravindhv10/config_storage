#!/bin/sh
IMAGE_NAME='jupyter_torch'
CONTAINER_NAME="${IMAGE_NAME}_1"

docker_build(){
    sudo docker image build \
        -t "${IMAGE_NAME}"  \
        .                   \
    ;
}
