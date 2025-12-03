FROM debtestrustzsh

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
      --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
      --mount=target=/var/cache/apt,type=cache,sharing=locked \
      echo 'START apt-get stuff' \
      && apt-get install -y \
          'clangd' \
          'clang-format' \
          'clang-tidy' \
          'clang-tools' \
      && echo 'DONE apt-get stuff' ;
