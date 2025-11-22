FROM debtestrust

COPY './important_functions.sh' '/root/important_functions.sh'

COPY './install.sh' '/root/install.sh'
COPY './install_all.sh' '/root/install_all.sh'
COPY './compress.sh' '/root/compress.sh'

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get stuff' \
    && apt-get -y update \
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
    && echo 'DONE apt-get stuff' ;
