FROM debtestrustzsh

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

RUN mkdir -pv -- "${HOME}/.config/helix"
ADD ./config.toml '/root/.config/helix/config.toml'
