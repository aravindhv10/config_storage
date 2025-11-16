FROM debtestrustzsh

RUN rustup component add rust-analyzer
RUN rustup component add rustfmt
RUN rustup component add rust-src

RUN \
      --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
      --mount=target=/var/cache/apt,type=cache,sharing=locked \
      echo 'START apt-get stuff' \
      && apt-get -y update \
      && apt-get install -y \
          'aria2' \
          'clangd' \
          'clang-format' \
          'clang-tidy' \
          'clang-tools' \
      && echo 'DONE apt-get stuff' ;

RUN aria2c -c -x16 -j16 'https://github.com/helix-editor/helix/releases/download/25.07.1/helix-25.07.1-x86_64-linux.tar.xz'
RUN tar -xf ./helix-25.07.1-x86_64-linux.tar.xz
RUN \
    echo 'Start installing helix' \
        && rm -vf -- 'helix-25.07.1-x86_64-linux.tar.xz' \
        && cd './helix-25.07.1-x86_64-linux/' \
        && mv hx /usr/local/bin \
        && mv runtime /usr/local/bin \
        && mv contrib/completion/hx.bash /usr/share/bash-completion/completions/hx \
        && mv ./contrib/completion/hx.zsh /usr/share/zsh/vendor-completions/_hx \
        && chown 'root:root' '/usr/share/zsh/vendor-completions/_hx' \
        && mv ./contrib/completion/hx.fish /usr/share/fish/completions/hx.fish \
        && cd .. \
        && rm -rf -- './helix-25.07.1-x86_64-linux/' \
    && echo 'Done installing helix' ;

RUN mkdir -pv -- "${HOME}/.config/helix"
ADD ./config.toml '/root/.config/helix/config.toml'
