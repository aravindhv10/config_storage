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
        'd7394b0fac769f3eaa1f57567db4c1a9f80b6697a8fd4a96b00830d82cae6c9839e5f1ce8e14e57f597473012206a60dad2748b5dca47c0fb282760af8a2d23d' \
        '/var/tmp/out.tar.zst' \
    && cd '/var/tmp/' \
    && aria2c -c -x16 -j16 'https://github.com/aravindhv10/config_storage/releases/download/v1.0/out.tar.zst' \
    && zstd -dfk --long=30 './out.tar.zst' \
    && tar -xf './out.tar' \
    && mv out/* ./ \
    && rmdir -pv -- out \
    && rm -vf -- './out.tar' './out.tar.zst' \
    && echo 'DONE Download and install rust programs' ;

RUN ls /var/tmp/*/install.sh | sh

RUN \
    echo 'START ohmyzsh' \
    && git clone 'https://github.com/ohmyzsh/ohmyzsh.git' \
    && ln -vfs "${HOME}/ohmyzsh" "${HOME}/.oh-my-zsh" \
    && echo 'DONE ohmyzsh' ;

ADD ./zshrc /root/.zshrc
