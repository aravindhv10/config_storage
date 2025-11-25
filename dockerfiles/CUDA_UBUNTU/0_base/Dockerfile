FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04

ENV HOME='/root'
ENV DEBIAN_FRONTEND='noninteractive'
WORKDIR '/root'
USER root

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get update' \
    && apt-get update \
    && apt-get -y install \
        'aria2' \
        'git' \
    && echo 'DONE apt-get update' ;
