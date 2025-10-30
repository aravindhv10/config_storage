FROM rust:trixie

ENV HOME='/root'
ENV DEBIAN_FRONTEND='noninteractive'
WORKDIR '/root'
USER root

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get stuff' \
    && apt-get -y update \
    && apt-get install -y \
        'aria2' \
        'git' \
        'wget' \
        'zsh' \
    && echo 'DONE apt-get stuff' ;

RUN \
    echo 'START ohmyzsh' \
    && git clone 'https://github.com/ohmyzsh/ohmyzsh.git' \
    && ln -vfs "${HOME}/ohmyzsh" "${HOME}/.oh-my-zsh" \
    && cp "${HOME}/.oh-my-zsh/templates/zshrc.zsh-template" "${HOME}/.zshrc" \
    && echo 'DONE ohmyzsh' ;

RUN \
    echo 'START ohmyzsh' \
    && aria2c -c 'https://starship.rs/install.sh' \
    && chmod +x './install.sh' \
    && './install.sh' '-y' \
    && echo 'eval "$(starship init zsh)"' >> "${HOME}/.zshrc" \
    && echo 'DONE ohmyzsh' ;

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get stuff' \
    && apt-get -y update \
    && apt-get install -y \
        'bat' \
        'fzf' \
        'lsd' \
    && echo 'alias ls=lsd' >> "${HOME}/.zshrc" \
    && echo 'alias cat=batcat' >> "${HOME}/.zshrc" \
    && echo 'DONE apt-get stuff' ;

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    echo 'START sourcing important functions' \
    && echo '. "/root/important_functions.sh"' >> "${HOME}/.zshrc" \
    && echo 'DONE sourcing important functions' ;

RUN \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    echo 'START apt-get stuff' \
    && apt-get -y update \
    && apt-get install -y \
        'aria2' \
        'build-essential' \
        'cmake' \
        'curl' \
        'git' \
        'git-lfs' \
        'make' \
        'neovim' \
        'ninja-build' \
        'pkg-config' \
        'unzip' \
        'wget' \
    && echo 'DONE apt-get stuff' ;
