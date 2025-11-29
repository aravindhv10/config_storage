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
        'ab2c599dc722b95cec511ba0432642ea401d2fef51b512a08783a7f0af3b00547017868b3cc1e191cd038b9a4d7cb4fe83d16a50b888ec721194e0e297ad3cbd' \
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
