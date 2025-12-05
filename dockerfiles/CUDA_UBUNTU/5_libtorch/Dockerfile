FROM 4_python

COPY './important_functions.sh' '/root/important_functions.sh'

RUN \
    --mount=target=/root/SHA512SUM,type=cache \
    --mount=target=/root/TMP,type=cache \
    echo 'START Download and install libtorch' \
    && . "${HOME}/important_functions.sh" \
    && adown \
        'https://download.pytorch.org/libtorch/cu128/libtorch-shared-with-deps-2.9.1%2Bcu128.zip' \
        'libtorch.zip' \
        'ffbe0d9e3250cdcfc6f2fe8498e6b41a6e0949cbf048fb6e430b96bc4eda1a39d9857612fca487c30840572b1e51f4534d36b42bd0924b9ee7ec3bfb6f27c204' \
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
