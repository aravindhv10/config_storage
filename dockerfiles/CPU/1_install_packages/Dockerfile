FROM 0_base

ENV HOME='/root' \
    DEBIAN_FRONTEND='noninteractive' \
    CMAKE_EXPORT_COMPILE_COMMANDS=1

ENV CARGO_HOME="${HOME}/cargo" \
    RUSTUP_HOME="${HOME}/rustup" \
    VIRTUAL_ENV="${HOME}/venv" \
    VIRTUAL_ENV_PROMPT='venv'

ENV PATH="${HOME}/bin:${HOME}/venv/bin:${CARGO_HOME}/bin:${PATH}"

WORKDIR '/root'

USER root

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get update' \
    && apt-get update \
    && . '/root/important_functions.sh' \
    && get_apt_packages \
    && echo 'DONE apt-get update' ;
