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

RUN cargo install bat
RUN cargo install du-dust
RUN cargo install eza
RUN cargo install fd-find
RUN cargo install find-files
RUN cargo install starship

RUN \
    echo 'START ohmyzsh' \
    && git clone 'https://github.com/ohmyzsh/ohmyzsh.git' \
    && ln -vfs "${HOME}/ohmyzsh" "${HOME}/.oh-my-zsh" \
    && echo 'DONE ohmyzsh' ;

ADD ./zshrc /root/.zshrc
