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
        'zsh' \
    && echo 'DONE apt-get stuff' ;

RUN \
    echo 'START ohmyzsh' \
    && git clone 'https://github.com/ohmyzsh/ohmyzsh.git' \
    && ln -vfs "${HOME}/ohmyzsh" "${HOME}/.oh-my-zsh" \
    && echo 'DONE ohmyzsh' ;

ADD ./zshrc /root/.zshrc

COPY out /root/
RUN ln -vfs /root/out/* /var/tmp/
RUN ls /var/tmp/*/install.sh | sh
