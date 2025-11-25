FROM debtestrustzshhelixpy

RUN \
      --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
      --mount=target=/var/cache/apt,type=cache,sharing=locked \
      echo 'START apt-get stuff' \
      && apt-get -y update \
      && apt-get install -y \
          'aria2' \
          'bear' \
          'zip' \
      && echo 'DONE apt-get stuff' ;

RUN \
    --mount=target=/root/SHA512SUM,type=cache \
    --mount=target=/root/TMP,type=cache \
    echo 'START Download and install libtorch' \
    && . "${HOME}/important_functions.sh" \
    && adown \
        'https://download.pytorch.org/libtorch/cpu/libtorch-shared-with-deps-2.9.1%2Bcpu.zip' \
        'libtorch.zip' \
        '86cd32e4c4a1e8810b1e7596cfa52341e16ab220e4a602bfbefa6af3227bac5cf83aa7372ffb1e787c893653a4c77a549c7e8c2e850ca9cbc325008d5f0b5237' \
        "${HOME}/libtorch.zip" \
    && cd "${HOME}" \
    && unzip './libtorch.zip' \
    && cd libtorch \
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
