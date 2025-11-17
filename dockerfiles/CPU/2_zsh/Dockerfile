FROM debtestrustbuild

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get stuff' \
    && apt-get -y update \
    && apt-get install -y \
        'build-essential' \
        'fish' \
        'fzf' \
        'git' \
        'zstd' \
        'zsh' \
    && echo 'DONE apt-get stuff' ;

RUN \
    echo 'START ohmyzsh' \
    && git clone 'https://github.com/ohmyzsh/ohmyzsh.git' \
    && ln -vfs "${HOME}/ohmyzsh" "${HOME}/.oh-my-zsh" \
    && echo 'DONE ohmyzsh' ;

ADD ./zshrc /root/.zshrc

RUN \
    echo 'START Downloading rust programs' \
    && cd '/var/tmp/' \
    && aria2c -c -x16 -j16 'https://github.com/aravindhv10/config_storage/releases/download/v1.0/out.tar.zst' \
    && zstd -d --long=30 './out.tar.zst' \
    && tar -xf './out.tar' \
    && mv out/* ./ \
    && rmdir -pv -- out \
    && rm -vf -- './out.tar' './out.tar.zst' \
    && echo 'DONE Downloading rust programs' ;

RUN ls /var/tmp/*/install.sh | sh

RUN atuin init zsh >> /root/.zshrc
