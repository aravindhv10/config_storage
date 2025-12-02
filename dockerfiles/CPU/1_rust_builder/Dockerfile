FROM mainbase

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get stuff' \
    && apt-get install -y \
        'aria2' \
        'curl' \
        'git' \
        'wget' \
    && echo 'DONE apt-get stuff' ;

ENV RUSTUP_HOME='/usr/local/rustup'
ENV CARGO_HOME='/usr/local/cargo'
ENV PATH="/usr/local/cargo/bin:${PATH}"
ENV RUST_VERSION='1.91.1'

RUN \
    --mount=target=/cache,type=cache,sharing=locked \
    set -eux; \
    mkdir -pv '/cache'; \
    cd '/cache'; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
        'amd64') \
            rustArch='x86_64-unknown-linux-gnu'; \
            rustupSha256='20a06e644b0d9bd2fbdbfd52d42540bdde820ea7df86e92e533c073da0cdd43c'; \
            ;; \
        'armhf') \
            rustArch='armv7-unknown-linux-gnueabihf'; \
            rustupSha256='3b8daab6cc3135f2cd4b12919559e6adaee73a2fbefb830fadf0405c20231d61'; \
            ;; \
        'arm64') \
            rustArch='aarch64-unknown-linux-gnu'; \
            rustupSha256='e3853c5a252fca15252d07cb23a1bdd9377a8c6f3efa01531109281ae47f841c'; \
            ;; \
        'i386') \
            rustArch='i686-unknown-linux-gnu'; \
            rustupSha256='a5db2c4b29d23e9b318b955dd0337d6b52e93933608469085c924e0d05b1df1f'; \
            ;; \
        'ppc64el') \
            rustArch='powerpc64le-unknown-linux-gnu'; \
            rustupSha256='acd89c42b47c93bd4266163a7b05d3f26287d5148413c0d47b2e8a7aa67c9dc0'; \
            ;; \
        's390x') \
            rustArch='s390x-unknown-linux-gnu'; \
            rustupSha256='726b7fd5d8805e73eab4a024a2889f8859d5a44e36041abac0a2436a52d42572'; \
            ;; \
        'riscv64') \
            rustArch='riscv64gc-unknown-linux-gnu'; \
            rustupSha256='09e64cc1b7a3e99adaa15dd2d46a3aad9d44d71041e2a96100d165c98a8fd7a7'; \
            ;; \
        *) \
            echo >&2 "unsupported architecture: $arch"; \
            exit 1; \
            ;; \
    esac; \
    \
    url="https://static.rust-lang.org/rustup/archive/1.28.2/${rustArch}/rustup-init"; \
    wget --progress=dot:giga -c "$url"; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host ${rustArch}; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    \
    rustup --version; \
    cargo --version; \
    rustc --version;

RUN rustup component add rust-src
RUN rustup component add rust-analyzer
RUN rustup component add rustfmt

COPY './install.sh' '/root/install.sh'
COPY './install_all.sh' '/root/install_all.sh'
COPY './compress.sh' '/root/compress.sh'

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get stuff' \
    && apt-get install -y \
        'aria2' \
        'automake' \
        'bear' \
        'bison' \
        'build-essential' \
        'clang' \
        'cmake' \
        'curl' \
        'ffmpeg' \
        'gawk' \
        'gettext' \
        'git' \
        'git-lfs' \
        'libevent-dev' \
        'liblz4-dev' \
        'liblzo2-dev' \
        'libpcre2-16-0' \
        'libpcre2-32-0' \
        'libpcre2-8-0' \
        'libpcre2-dev' \
        'libpcre2-posix3' \
        'libssl-dev' \
        'libzstd-dev' \
        'make' \
        'nasm' \
        'neovim' \
        'ninja-build' \
        'pkg-config' \
        'python3-newt' \
        'python3-sphinx' \
        'squashfs-tools' \
        'unzip' \
        'wget' \
        'yacc' \
        'zip' \
        'zstd' \
    && echo 'DONE apt-get stuff' ;
