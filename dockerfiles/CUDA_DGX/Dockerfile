FROM nvcr.io/nvidia/pytorch:26.08-py3

COPY './important_functions.sh' '/root/important_functions.sh'

ENV HOME='/root'
ENV DEBIAN_FRONTEND='noninteractive'
ENV CMAKE_EXPORT_COMPILE_COMMANDS=1
WORKDIR '/root'
USER root

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get update' \
    && apt-get update \
    && . '/root/important_functions.sh' \
    && apt-get -y install \
        'aria2' \
        'automake' \
        'bear' \
        'bison' \
        'build-essential' \
        'cmake' \
        'curl' \
        'ffmpeg' \
        'fish' \
        'fzf' \
        'git' \
        'git-lfs' \
        'make' \
        'mold' \
        'squashfs-tools' \
        'unzip' \
        'wget' \
        'yacc' \
        'zip' \
        'zsh' \
        'zstd' \
    && echo 'DONE apt-get update' ;

ENV CARGO_HOME="${HOME}/cargo"
ENV RUSTUP_HOME="${HOME}/rustup"
ENV PATH="${HOME}/bin:${CARGO_HOME}/bin:${PATH}"

RUN \
    --mount=target=/root/SHA512SUM,type=cache \
    --mount=target=/root/TMP,type=cache \
    echo 'START Download and install rust' \
    && . "${HOME}/important_functions.sh" \
    && adown \
        'https://sh.rustup.rs' \
        'rustup.rs' \
        '494ddf67a104d5deb49380968ecccd8648ee0d7a3e61a8fa45b4dfd3bdc51ba8777922ed0e1864bf81ba78ce718bd40c55c1835c328df3cd1cd0d17312411460' \
        "${HOME}/rustup-init.sh" \
    && cd "${HOME}" \
    && chmod +x 'rustup-init.sh' \
    && './rustup-init.sh' '-y' '--no-modify-path' \
    && echo 'DONE Download and install rust'

RUN rustup default stable
RUN rustup component add rust-src
RUN rustup component add rust-analyzer
RUN rustup component add rustfmt

RUN \
    --mount=target=/root/SHA512SUM,type=cache \
    --mount=target=/root/TMP,type=cache \
    echo 'START Download and install zig' \
    && . "${HOME}/important_functions.sh" \
    && adown \
        'https://ziglang.org/builds/zig-aarch64-linux-0.17.0-dev.2131+d08989840.tar.xz' \
        'zig-aarch64-linux-0.17.0-dev.2131+d08989840.tar.xz' \
        'dc816d391b4a81f5c34a70466716678374b696eadabdf766e13b78b79e931a3c8345f7bfb86cd0db607f5980a8a283dbfd9086f6542fad9d43a8180f2e7a1933' \
        "${HOME}/ZIG/zig-aarch64-linux-0.17.0-dev.2131+d08989840.tar.xz" \
    && cd "${HOME}/ZIG/" \
    && tar -xf './zig-aarch64-linux-0.17.0-dev.2131+d08989840.tar.xz' \
    && cd './zig-aarch64-linux-0.17.0-dev.2131+d08989840' \
    && mv * /usr/local/bin/ \
    && echo 'DONE Download and install zig' ;
