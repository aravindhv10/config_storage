FROM debtestrust

COPY './important_functions.sh' '/root/important_functions.sh'

COPY './install.sh' '/root/install.sh'

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get stuff' \
    && apt-get -y update \
    && apt-get install -y \
        'aria2' \
        'bison' \
        'build-essential' \
        'clang' \
        'cmake' \
        'curl' \
        'gawk' \
        'gettext' \
        'git' \
        'git-lfs' \
        'liblz4-dev' \
        'libpcre2-16-0' \
        'libpcre2-32-0' \
        'libpcre2-8-0' \
        'libpcre2-dev' \
        'libpcre2-posix3' \
        'libssl-dev' \
        'make' \
        'neovim' \
        'ninja-build' \
        'pkg-config' \
        'python3-sphinx' \
        'squashfs-tools' \
        'unzip' \
        'wget' \
        'yacc' \
    && echo 'DONE apt-get stuff' ;
