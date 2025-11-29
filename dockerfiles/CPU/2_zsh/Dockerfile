FROM debtestrustbuild

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get stuff' \
    && apt-get install -y \
        'build-essential' \
        'fish' \
        'fzf' \
        'git' \
        'zstd' \
        'zsh' \
    && echo 'DONE apt-get stuff' ;

RUN \
    --mount=target=/root/SHA512SUM,type=cache \
    --mount=target=/root/TMP,type=cache \
    echo 'START Download and install rust programs' \
    && . "${HOME}/important_functions.sh" \
    && adown \
        'https://github.com/aravindhv10/config_storage/releases/download/v1.0/out.tar.zst' \
        'out.tar.zst' \
        '1aaba657c6b814ff2a75c1d4ec692c09b5c6c76ed4351fca366e8acf160b568750c7881475b4b01d4e2fa8b6eb7348377176bac9012c24303c088e5c047afde8' \
        '/var/tmp/out.tar.zst' \
    && cd '/var/tmp/' \
    && zstd -dfk --long=30 './out.tar.zst' \
    && tar -xf './out.tar' \
    && mv out/* ./ \
    && rmdir -pv -- out \
    && rm -vf -- './out.tar' './out.tar.zst' \
    && echo 'DONE Download and install rust programs' ;

RUN ls /var/tmp/*/install.sh | sh

RUN home_config
