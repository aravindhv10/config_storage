FROM debtestrustzshhelixpy

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
      --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
      --mount=target=/var/cache/apt,type=cache,sharing=locked \
      echo 'START apt-get stuff' \
      && apt-get install -y \
          'bear' \
          'zip' \
      && echo 'DONE apt-get stuff' ;

RUN \
    --mount=target=/root/SHA512SUM,type=cache \
    --mount=target=/root/TMP,type=cache \
    echo 'START Download and install libtorch' \
    && . "${HOME}/important_functions.sh" \
    && cd '/opt/venv/lib/python3.12/site-packages/torch' \
    && cd lib \
    && ls | sed 's@^@(cp -vapf -- "@g;s@$@" "/usr/lib/");@g' | sh \
    && cd .. \
    && cd include \
    && ls | sed 's@^@(cp -vapf -- "@g;s@$@" "/usr/include/");@g' | sh \
    && cd .. \
    && cd share/cmake \
    && ls | sed 's@^@(cp -vapf -- "@g;s@$@" "/usr/share/cmake");@g' | sh \
    && cd ../.. \
    && cd .. \
    && echo 'DONE Download and install libtorch' ;

ENV LIBTORCH="/usr/"
