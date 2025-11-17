FROM debtestrustzshhelixpy

RUN uv pip install torch torchvision --index-url 'https://download.pytorch.org/whl/cpu'
RUN uv pip install einops timm

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

RUN aria2c -c -x16 -j16 'https://download.pytorch.org/libtorch/cpu/libtorch-shared-with-deps-2.9.1%2Bcpu.zip'
RUN unzip './libtorch-shared-with-deps-2.9.1+cpu.zip'
RUN rm -vf -- './libtorch-shared-with-deps-2.9.1+cpu.zip'
ENV LIBTORCH="/usr/"
RUN \
    echo 'Install libtorch' \
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
    && echo 'Done Install libtorch' ;
