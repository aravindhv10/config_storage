FROM 0_base

ENV HOME='/root'
ENV DEBIAN_FRONTEND='noninteractive'
ENV CMAKE_EXPORT_COMPILE_COMMANDS=1
WORKDIR '/root'
USER root

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get update' \
    && apt-get update \
    && apt-get -y install \
        'aria2' \
        'fish' \
        'fzf' \
        'git' \
        'zsh' \
        'zstd' \
    && echo 'DONE apt-get update' ;
